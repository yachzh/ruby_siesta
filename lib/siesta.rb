# frozen_string_literal: true

require_relative 'cell'
require_relative 'struct_reader'
require_relative 'fdf'
require_relative 'phys'

# call siesta from Ruby
class Siesta
  def initialize(struct)
    @syslabel = 'siesta'
    @struct = struct
    @cell = @struct[:cell_parameters]
    @coordinates = @struct[:coordinates]
    @number_of_atoms = @coordinates.length
    @species_labels = []
    @chem = []
    @coordinates.each do |coord|
      @species_labels << coord[:atom] unless @species_labels.include?(coord[:atom])
      @chem << coord[:atom] # chemical elements
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

  def spin(pol: false, noncol: false, soc: false, fixspin: false)
    spinpar = {}
    ss = if pol
           'polarized'
         else
           'non-polarized'
         end
    ss = 'non-colinear' if noncol
    ss = 'spin-orbit' if soc
    spinpar.store('Spin', ss) if ss != 'non-polarized'
    spinpar.store('Spin.Fix', true) if fixspin
    return if spinpar.nil?

    fdf_input(spinpar)
  end

  def plus_u(atom: 'Fe', orbital: '3d', hubbard_u: 4.0)
    orb = %w[s p d f]
    n = orbital[0] # principal quantum number
    l = orb.index(orbital[-1].downcase) # angular quantum number

    @hubbard_u[atom.capitalize] = [
      "  #{atom.capitalize}  1",
      "  n=#{n}  #{l}",
      "  #{format('%4.2f', hubbard_u)}  0.0",
      '  0.0  0.0'
    ]
  end

  def initial_spin(atom: nil, spin_moment: nil, spin_state: nil)
    # atom: chemical symbol or atom index (0..), spin_moment: in Bohr magneton
    # spin_state: 'hs' (high-spin), 'ls' (low-spin), 'is' (intermediate-spin)
    return if atom.nil?

    if atom.is_a?(Integer)
      raise "Atom index out of range, number of atoms: #{@number_of_atoms}" if atom >= @number_of_atoms

      if !spin_moment.nil?
        @local_spin[atom] = spin_moment
        @totspin += spin_moment
      elsif !atomic_spin(@chem[atom].capitalize, spin_state).nil?
        @local_spin[atom] = atomic_spin(@chem[atom].capitalize, spin_state)
        @totspin += atomic_spin(@chem[atom].capitalize, spin_state)
      end
    elsif atom.is_a?(String)
      raise "Not including #{atom.capitalize}" unless @chem.include?(atom.capitalize)

      index = @chem.index(atom.capitalize)
      if !spin_moment.nil?
        @local_spin[index] = spin_moment
        @totspin += spin_moment
      elsif !atomic_spin(atom, spin_state).nil?
        @local_spin[index] = atomic_spin(atom, spin_state)
        @totspin += atomic_spin(atom, spin_state)
      end
    end
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
    @blocks['kpoint'] = kgrid
  end

  def pdos(emin: -20.0, emax: 10.0, sigma: nil, ngrid: 3000)
    if sigma.nil?
      electronic_temperature = @parah['ElectronicTemperature']
      if !electronic_temperature.nil?
        unit = electronic_temperature.split.last
        number = electronic_temperature.split.first.to_f
        raise 'unrecognized electronic temperature unit!' unless unit == 'K'

        sigma = 2 * number * Phys.kB

      else
        sigma = 0.2
      end
    end
    pdos_block = <<~BLOCK
      %block ProjectedDensityOfStates
      #{format('%8.2f', emin)}#{format('%7.2f', emax)}#{format('%7.3f', sigma)}#{format('%6d', ngrid)}  eV
      %endblock ProjectedDensityOfStates
    BLOCK
    @blocks['pdos'] = pdos_block
  end

  def eef(ex: 0.0, ey: 0.0, ez: 0.0)
    return if ex.abs < 1e-6 && ey.abs < 1e-6 && ez.abs < 1e-6

    eef_block = <<~BLOCK
      %block ExternalElectricField
      #{format('%8.3f', ex)}#{format('%8.3f', ey)}#{format('%8.3f', ez)}  V/Ang
      %endblock ExternalElectricField
    BLOCK
    @blocks['eef'] = eef_block
  end

  def bands(bandpath: nil, xk: nil, ngrid: 420)
    return if bandpath.nil?

    label_k = []
    bandpath.each_char do |k|
      label_k << if k == 'G'
                   '\\Gamma'
                 else
                   k
                 end
    end
    npoints = generate_npoints(bandpath, ngrid)

    bands_block = []
    bands_block << '%block BandLines'
    npoints.zip(xk, label_k).each do |np, kc, lb|
      bands_block << "#{format('%3d', np)}  #{kc.map { |x| '%6.3f' % x }.join(' ')}  #{lb}"
    end
    bands_block << '%endblock BandLines'
    @blocks['bands'] = bands_block
    fdf_input({ 'WriteKbands' => true, 'WriteBands' => true })
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
    # run_siesta unless File.exist?(@ofile)
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

  def atomic_spin(atom, spin_state)
    spin = {
      Mn: { 'hs' => 5.0, 'ls' => 1.0 },
      Fe: { 'hs' => 4.0, 'ls' => 0.0, 'is' => 2.0 },
      Co: { 'hs' => 3.0, 'ls' => 1.0 },
      Ni: { 'hs' => 2.0 }
    }
    spin[atom.capitalize.to_sym][spin_state.downcase]
  end

  def generate_npoints(bp, ngrid)
    raise 'Error: bp cannot be nil' if bp.nil?

    num_of_bandlines = bp.split('').length - 1
    puts "Number of band lines #{num_of_bandlines}"
    np_per_line = ngrid / num_of_bandlines
    puts "Number of points per line #{np_per_line}"
    npoints = [1]
    (num_of_bandlines - 1).times { npoints << np_per_line }
    npoints << ngrid - np_per_line * (num_of_bandlines - 1)
    npoints
  end

  def config_init_spin
    non_zero_spin = @local_spin.each_with_index.select { |m, _index| m.abs > 1e-6 }

    return if non_zero_spin.empty?

    spinblock = <<~BLOCK
      %block DM.InitSpin
      #{non_zero_spin.map { |m, i| "#{format('%5d', i + 1)} #{format('%5.1f', m).sub(/0$/, '')}" }.join("\n")}
      %endblock DM.InitSpin
    BLOCK
    @blocks['spin'] = spinblock
  end

  def config_lda_plus_u
    return if @hubbard_u.empty?

    ldauproj_block = <<~BLOCK
      %block DFTU.Proj
      #{@hubbard_u.values.flatten.join("\n")}
      %endblock DFTU.Proj
    BLOCK
    @blocks['ldau'] = ldauproj_block
  end

  def default_option
    @blocks = {}
    @local_spin = [0.0] * @number_of_atoms
    @hubbard_u = {}
    @parah = Fdf.default_parameters
    @vdW_correction = false
    @totspin = 0.0
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
    config_init_spin
    config_lda_plus_u
    return if @blocks.empty?

    File.open(@fdf_file, 'a') do |file|
      @blocks.each_value do |block|
        file.puts block
        file.puts ''
      end
    end
  end

  def write_parah
    @parah.delete('NetCharge') if @parah['NetCharge'].nil? || @parah['NetCharge'].abs < 1e-6
    @parah.delete('SCF.Mixer.Kick') if @parah['SCF.Mixer.Kick'].nil? || @parah['SCF.Mixer.Kick'].zero?
    @parah.delete('FilterCutoff') if @parah['FilterCutoff'] == Fdf.default_parameters['FilterCutoff']
    ['SaveElectrostaticPotential', 'MullikenInSCF', 'Write.Denchar',
     'SaveBaderCharge', 'Slab.DipoleCorrection', 'WriteCoorXmol',
     'DM.UseSaveDM'].each do |key|
      @parah.delete(key) unless @parah[key]
    end
    fdf_input({ 'Spin.Total' => @totspin.to_i }) if @parah['Spin.Fix'] && @totspin.abs > 1e-6
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
