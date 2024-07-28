# frozen_string_literal: true

require 'cell'
require 'struct_reader'
require 'fdf'

# call siesta from Ruby
class Siesta
  def initialize(struct)
    @syslabel = 'siesta'
    @struct = struct
    @cell = @struct[:cell_parameters]
    @coordinates = @struct[:coordinates]
    @species_labels = []
    @coordinates.each do |coord|
      @species_labels << coord[:atom] unless @species_labels.include?(coord[:atom])
    end
    @lattice_vectors ||= if @struct[:lattice_vectors].nil?
                           Cell.lattice_vectors(@cell)
                         else
                           @struct[:lattice_vectors]
                         end
    default_option
  end

  def label(sys_label)
    @syslabel = sys_label
    update_file
  end

  def self.import_from_file(str_file)
    new(StructReader.new(str_file).struct)
  end

  def plus_d2
    @vdW_correction = true
  end

  def xc(inp_xc)
    allowed_xc = {
      'LDA' => %w[PZ CA PW92],
      'GGA' => %w[PW91 PBE revPBE RPBE
                  WC AM05 PBEsol PBEJsJrLO
                  PBEGcGxLO PBEGcGxHEG BLYP],
      'VDW' => %w[DRSLL LMKLL KBM C09 BH VV]
    }

    inp_xc = 'pz' if inp_xc.downcase == 'lda'
    allowed_xc.each do |key, value|
      value.each do |aux|
        next unless aux.downcase == inp_xc.downcase

        fdf_input({ 'XC.Functional' => key, 'XC.Authors' => aux })
      end
    end
  end

  def spin(pol: false, noncol: false, soc: false, fixspin: false, totspin: 0)
    spinpar = {}
    ss = if pol
           'polarized'
         else
           'non-polarized'
         end
    ss = 'non-colinear' if noncol
    ss = 'spin-orbit' if soc
    spinpar.store('Spin', ss) if ss != 'non-polarized'
    if fixspin
      spinpar.store('Spin.Fix', true)
      spinpar.store('Spin.Total', totspin)
    end
    return if spinpar.nil?

    fdf_input(spinpar)
  end

  def magnetic_center(metal: 'fe', spin_state: 'ls')
    local_spin=generate_spin_moment
    init_spin(local_spin)
  end

  def parameters(**kwargs)
    fdfpar = {}
    kwargs.each_key do |ik|
      raise "#{ik} not recognized!" unless Fdf.custom.key?(ik)
    end
    Fdf.custom.each do |ck, cv|
      if kwargs.key?(ck)
        fdfpar.store(cv[0], kwargs[ck])
      else
        fdfpar.store(cv[0], cv[1])
      end
    end
    fdf_input(fdfpar)
  end

  # ExternalElectricField
  # todo set Hubbard U
  # todo write pdos
  # todo geometry optimization
  # aimd setup

  def kpoint(kmesh: [1, 1, 1], dk: 0.0)
    k1 = [kmesh[0], 0, 0]
    k2 = [0, kmesh[1], 0]
    k3 = [0, 0, kmesh[2]]

    kgrid = <<~BLOCK
      %block kgrid_Monkhorst_Pack
        #{k1.map { |x| x.to_s.rjust(4) }.join(' ')}   #{dk}
        #{k2.map { |x| x.to_s.rjust(4) }.join(' ')}   #{dk}
        #{k3.map { |x| x.to_s.rjust(4) }.join(' ')}   #{dk}
      %endblock kgrid_Monkhorst_Pack
    BLOCK
    @blocks << kgrid
  end

  def write_fdf(vector: true)
    File.open(@fdf_file, 'w') do |file|
      file.puts "SystemLabel   #{@syslabel}"
      file.puts "NumberOfAtoms   #{@coordinates.size}"
      file.puts "NumberOfSpecies   #{@species_labels.size}"
      file.puts 'LatticeConstant   1.0 Ang'
      vector ? write_lattice_vectors(file) : write_lattice_parameters(file)
      file.puts 'AtomicCoordinatesFormat   Ang'
      file.puts '%block ChemicalSpeciesLabel'
      @species_labels.each_with_index do |label, index|
        atomic_number = StructReader.atomic_number(label)
        file.puts "#{format('%3d', (index + 1))} #{format('%4d', atomic_number)}   #{label}"
        link_psf(label)
      end
      file.puts '%endblock ChemicalSpeciesLabel', ''

      file.puts '%block AtomicCoordinatesAndAtomicSpecies'
      file.puts @coordinates.map { |coord| format_coordinate(coord) }.join("\n")
      file.puts '%endblock AtomicCoordinatesAndAtomicSpecies', ''
    end
    write_parah
    write_blocks
    return unless @vdW_correction

    system("fdf2grimme #{@fdf_file} >> #{@fdf_file}")
  end

  def energy
    run_siesta
    last_line = nil
    File.foreach(@ofile) do |line|
      last_line = line if line.include?('Total =')
    end
    raise 'SIESTA computation is incomplete!' if last_line.nil?

    last_line.split(' ')[-1].to_f
  end

  private

  def fdf_input(args)
    # the args looks like {'PAO.BasisSize' => 'DZP', 'Mesh.Cutoff' => '200 Ry',...}
    fdf_ctrl = Fdf.new(@parah)
    fdf_ctrl.update_parameters(args)
    @parah = fdf_ctrl.fdf_parameters
  end

def init_spin(moments)
  # input: the array of local spin moment in Bohr magneton
  non_zero_moments = moments.each_with_index.select { |moment, index| moment.abs > 1e-6 }
  spinblock = <<~BLOCK
    %block DM.InitSpin
    #{non_zero_moments.map { |moment, index| "#{index + 1} #{moment}" }.join("\n")}
    %endblock DM.InitSpin
  BLOCK
  @blocks << spinblock
end
  def default_option
    @blocks = []
    @parah = Fdf.default_parameters
    @vdW_correction = false
    xc('pz')
    update_file
  end

  def update_file
    @fdf_file = "#{@syslabel}.fdf"
    @ofile = "#{@syslabel}.out"
  end

  def run_siesta
    write_fdf
    user_command = ENV['RUBY_SIESTA_COMMAND']
    command = if user_command.nil?
                "siesta #{@fdf_file} > #{@ofile}"
              else
                user_command.gsub(/PREFIX/, @syslabel)
              end
    system(command)
  end

  def write_blocks
    File.open(@fdf_file, 'a') do |file|
      @blocks.each do |block|
        file.puts block
      end
    end
  end

  def write_parah
    @parah.delete('NetCharge') if @parah['NetCharge'].abs < 1e-6
    @parah.delete('SCF.Mixer.Kick') if @parah['SCF.Mixer.Kick'].zero?
    ['SaveElectrostaticPotential', 'MullikenInSCF', 'Write.Denchar',
     'SaveBaderCharge', 'Slab.DipoleCorrection'].each do |key|
      @parah.delete(key) unless @parah[key]
    end
    File.open(@fdf_file, 'a') do |file|
      @parah.each do |key, value|
        file.puts "#{key}   #{value}"
      end
      file.puts ''
    end
  end

  def link_psf(atom)
    dir_path = File.dirname(File.expand_path($PROGRAM_NAME))
    file_path = File.join(dir_path, "#{atom}.psf")
    File.unlink(file_path) if File.symlink?(file_path) || File.exist?(file_path)
    xc = @parah['XC.Functional'].downcase
    src_psf = File.join(ENV['SIESTA_PP_PATH'], "#{atom}.#{xc}.psf")
    raise "#{src_psf} does not exist" unless File.exist?(src_psf)

    File.symlink(src_psf, file_path)
  end

  def format_coordinate(xyz)
    i = @species_labels.index(xyz[:atom]) + 1
    "#{format('%15.8f', xyz[:x])} " \
      "#{format('%15.8f', xyz[:y])} " \
      "#{format('%15.8f', xyz[:z])} " + format('%3d', i).to_s
  end

  def write_lattice_vectors(file)
    file.puts '%block LatticeVectors'
    @lattice_vectors.each do |vector|
      file.puts vector.map { |num| format('%15.8f', num) }.join(' ')
    end
    file.puts '%endblock LatticeVectors', ''
  end

  def write_lattice_parameters(file)
    file.puts '%block LatticeParameters'
    file.puts " #{format('%12.8f', @cell[:a])}"\
              " #{format('%12.8f', @cell[:b])}"\
              " #{format('%12.8f', @cell[:c])}"\
              " #{format('%7.2f', @cell[:alpha])}"\
              " #{format('%7.2f', @cell[:beta])}"\
              " #{format('%7.2f', @cell[:gamma])}"
    file.puts '%endblock LatticeParameters', ''
  end
end
