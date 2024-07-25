# frozen_string_literal: true

require 'cell'
require 'read_geom'
require 'data_io'

# call siesta from Ruby
class Siesta
  def initialize(crystal_structure)
    @syslabel = 'siesta'
    @cryst = crystal_structure
    @cell = @cryst[:cell_parameters]
    @coordinates = @cryst[:coordinates]
    @species_labels = []
    @coordinates.each do |coord|
      @species_labels << coord[:atom] unless @species_labels.include?(coord[:atom])
    end
    @lattice_vectors ||= if @cryst[:lattice_vectors].nil?
                           Cell.lattice_vectors(@cell)
                         else
                           @cryst[:lattice_vectors]
                         end
    @parah = { 'PAO.BasisSize' => 'DZP',
               'PAO.EnergyShift' => '50 meV',
               'Mesh.Cutoff' => '200 Ry',
               'WriteMullikenPop' => 1,
               'MullikenInSCF' => false,
               'WriteCoorXmol' => true,
               'SCF.Mixer.Weight' => 0.01,
               'SCF.Mixer.History' => 5,
               'SCF.Mixer.Kick' => 0,
               'SCF.DM.Tolerance' => 1e-4,
               'SCF.H.Converge' => true,
               'SCF.H.Tolerance' => '1.0 meV',
               'MaxSCFIterations' => 2000,
               'DM.UseSaveDM' => true,
               'OccupationFunction' => 'MP',
               'OccupationMPOrder' => 4,
               'ElectronicTemperature' => '1000 K',
               'NetCharge' => 0,
               'Slab.DipoleCorrection' => false }
    xc('PZ')
    @vdW_correction = false
    @blocks = []
    update_file
  end

  def label(sys_label)
    @syslabel = sys_label
    update_file
  end

  def self.import_from_file(str_file)
    new(ReadGeom.new(str_file).cryst)
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

    inp_xc = 'PZ' if inp_xc == 'LDA'
    allowed_xc.each do |key, value|
      value.each do |aux|
        next unless aux.downcase == inp_xc.downcase

        @parah['XC.Functional'] = key
        @parah['XC.Authors'] = aux
      end
    end
  end

  def spin(pol: false, noncol: false, soc: false, fixspin: false, totspin: 0)
    ss = if pol
           'polarized'
         else
           'non-polarized'
         end
    ss = 'non-colinear' if noncol
    ss = 'spin-orbit' if soc
    @parah['Spin'] = ss
    @parah['Spin.Fix'] = fixspin
    @parah['Spin.Total'] = totspin
  end

  # TODO: set initial spin
  # ExternalElectricField
  # format kmesh block
  # dispersion correction, call fdf2grimme
  # todo set Hubbard U
  # todo write pdos denchar
  # todo geometry optimization
  # aimd setup

  def kpoint(kmesh: [1, 1, 1], dk: 0.0)
    k1 = [kmesh[0], 0, 0]
    k2 = [0, kmesh[1], 0]
    k3 = [0, 0, kmesh[2]]

    kgrid = <<~BLOCK
      %block kgrid_Monkhorst_Pack
        #{k1.join('   ')}   #{dk}
        #{k2.join('   ')}   #{dk}
        #{k3.join('   ')}   #{dk}
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
        atomic_number = ReadGeom.atomic_number(label)
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
    # run unless File.exist?(@ofile)
    run
    last_line = nil
    File.foreach(@ofile) do |line|
      last_line = line if line.include?('Total =')
    end
    raise 'SIESTA computation is incomplete!' if last_line.nil?

    last_line.split(' ')[-1].to_f
  end

  private

  def update_file
    @fdf_file = "#{@syslabel}.fdf"
    @ofile = "#{@syslabel}.out"
  end

  def run
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
    file_path = @fdf_file
    File.open(file_path, 'a') do |file|
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
    unless File.exist?(src_psf)
      puts "#{src_psf} does not exist"
      exit
    end
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
