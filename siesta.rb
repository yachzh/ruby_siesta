# frozen_string_literal: true

require 'cell'
require 'pycall'
require 'data_io'

# write siesta input file
class Siesta
  # attr_reader :cryst, :para

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
               'Mesh.Cutoff' => '300 Ry',
               'WriteMullikenPop' => 1,
               'WriteCoorXmol' => true,
               'DM.MixingWeight' => 0.02,
               'DM.NumberPulay' => 5,
               'DM.UseSaveDM' => true,
               'DM.Tolerance' => 0.0001,
               'MaxSCFIterations' => 2000,
               'SCF.H.Converge' => true,
               'SCF.H.Tolerance' => '10 meV',
               'ElectronicTemperature' => '300 K',
               'OccupationFunction' => 'MP',
               'OccupationMPOrder' => 4 }
    xc('PZ')
    @blocks = []
    update_file
  end

  def label(sys_label)
    @syslabel = sys_label
    update_file
  end

  def self.import_from_file(str_file)
    atoms = PyCall.import_module('ase.io').read(str_file)
    cryst = DataIO.atoms2cryst(atoms)
    new(cryst)
  end

  def xc(inp_xc)
    allowed_xc = {
      'LDA' => %w[PZ CA PW92],
      'GGA' => %w[PW91 PBE revPBE RPBE
                  WC AM05 PBEsol PBEJsJrLO
                  PBEGcGxLO PBEGcGxHEG BLYP],
      'VDW' => %w[DRSLL LMKLL KBM C09 BH VV]
    }

    allowed_xc.each do |key, value|
      if value.include?(inp_xc)
        @parah['XC.functional'] = key
        @parah['XC.authors'] = inp_xc
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
  # todo set Hubbard U
  # todo write pdos denchar
  # todo geometry optimization

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

  def generate_fdf_file(vector: true)
    File.open(@fdf_file, 'w') do |file|
      file.puts "SystemLabel   #{@syslabel}"
      file.puts "NumberOfAtoms   #{@coordinates.size}"
      file.puts "NumberOfSpecies   #{@species_labels.size}"
      file.puts 'LatticeConstant   1.0 Ang'
      vector ? write_lattice_vectors(file) : write_lattice_parameters(file)
      file.puts 'AtomicCoordinatesFormat   Ang'
      file.puts '%block ChemicalSpeciesLabel'
      @species_labels.each_with_index do |label, index|
        atomic_number = get_atomic_number(label)
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
    generate_fdf_file
    command = "siesta < #{@fdf_file} > #{@ofile}"
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
    xc = @parah['XC.functional'].downcase
    src_psf = File.join(ENV['SIESTA_PP_PATH'], "#{atom}.#{xc}.psf")
    unless File.exist?(src_psf)
      puts "#{src_psf} does not exist"
      exit
    end
    system("ln -s #{src_psf} #{file_path}")
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

  def get_atomic_number(atom)
    atomic_numbers = {
      'H' => 1,
      'He' => 2,
      'Li' => 3,
      'Be' => 4,
      'B' => 5,
      'C' => 6,
      'N' => 7,
      'O' => 8,
      'F' => 9,
      'Ne' => 10,
      'Na' => 11,
      'Mg' => 12,
      'Al' => 13,
      'Si' => 14,
      'P' => 15,
      'S' => 16,
      'Cl' => 17,
      'Ar' => 18,
      'K' => 19,
      'Ca' => 20,
      'Sc' => 21,
      'Ti' => 22,
      'V' => 23,
      'Cr' => 24,
      'Mn' => 25,
      'Fe' => 26,
      'Co' => 27,
      'Ni' => 28,
      'Cu' => 29,
      'Zn' => 30,
      'Ga' => 31,
      'Ge' => 32,
      'As' => 33,
      'Se' => 34,
      'Br' => 35,
      'Kr' => 36,
      'Rb' => 37,
      'Sr' => 38,
      'Y' => 39,
      'Zr' => 40,
      'Nb' => 41,
      'Mo' => 42,
      'Tc' => 43,
      'Ru' => 44,
      'Rh' => 45,
      'Pd' => 46,
      'Ag' => 47,
      'Cd' => 48,
      'In' => 49,
      'Sn' => 50,
      'Sb' => 51,
      'Te' => 52,
      'I' => 53,
      'Xe' => 54,
      'Cs' => 55,
      'Ba' => 56,
      'La' => 57,
      'Ce' => 58,
      'Pr' => 59,
      'Nd' => 60,
      'Pm' => 61,
      'Sm' => 62,
      'Eu' => 63,
      'Gd' => 64,
      'Tb' => 65,
      'Dy' => 66,
      'Ho' => 67,
      'Er' => 68,
      'Tm' => 69,
      'Yb' => 70,
      'Lu' => 71,
      'Hf' => 72,
      'Ta' => 73,
      'W' => 74,
      'Re' => 75,
      'Os' => 76,
      'Ir' => 77,
      'Pt' => 78,
      'Au' => 79,
      'Hg' => 80,
      'Tl' => 81,
      'Pb' => 82,
      'Bi' => 83,
      'Po' => 84,
      'At' => 85,
      'Rn' => 86
    }
    atomic_numbers[atom]
  end
end
