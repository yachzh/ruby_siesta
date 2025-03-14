# frozen_string_literal: true

require 'cell'
require 'matrix'

# read atomic structures from str files produced by
# siesta, vasp, and ase (xyz)
class StructReader
  attr_reader :lattice_vectors, :coordinates, :cell_parameters, :number_of_atoms

  def initialize(file_name)
    @inf = file_name
    @coordinates = []
    fn = @inf.downcase
    if fn.end_with?('.struct_out')
      read_siesta_struct_out
    elsif fn.end_with?('.vasp') || fn.include?('poscar')
      read_vasp_poscar
    elsif fn.end_with?('.xyz')
      read_xyz
    else
      puts 'Only implemented for struct_out, poscar, and xyz'
    end
    lattice_to_cell
  end

  def struct
    {
      cell_parameters: @cell_parameters,
      lattice_vectors: @lattice_vectors,
      coordinates: @coordinates
    }
  end

  def self.chemical_symbol(atomic_number)
    periodic_table[atomic_number]
  end

  def self.atomic_number(element)
    periodic_table.key(element)
  end

  def self.periodic_table
    {
      1 => 'H', 2 => 'He', 3 => 'Li', 4 => 'Be', 5 => 'B', 6 => 'C', 7 => 'N', 8 => 'O',
      9 => 'F', 10 => 'Ne', 11 => 'Na', 12 => 'Mg', 13 => 'Al', 14 => 'Si', 15 => 'P', 16 => 'S',
      17 => 'Cl', 18 => 'Ar', 19 => 'K',  20 => 'Ca', 21 => 'Sc', 22 => 'Ti', 23 => 'V',  24 => 'Cr',
      25 => 'Mn', 26 => 'Fe', 27 => 'Co', 28 => 'Ni', 29 => 'Cu', 30 => 'Zn', 31 => 'Ga', 32 => 'Ge',
      33 => 'As', 34 => 'Se', 35 => 'Br', 36 => 'Kr', 37 => 'Rb', 38 => 'Sr', 39 => 'Y',  40 => 'Zr',
      41 => 'Nb', 42 => 'Mo', 43 => 'Tc', 44 => 'Ru', 45 => 'Rh', 46 => 'Pd', 47 => 'Ag', 48 => 'Cd',
      49 => 'In', 50 => 'Sn', 51 => 'Sb', 52 => 'Te', 53 => 'I',  54 => 'Xe', 55 => 'Cs', 56 => 'Ba',
      57 => 'La', 58 => 'Ce', 59 => 'Pr', 60 => 'Nd', 61 => 'Pm', 62 => 'Sm', 63 => 'Eu', 64 => 'Gd',
      65 => 'Tb', 66 => 'Dy', 67 => 'Ho', 68 => 'Er', 69 => 'Tm', 70 => 'Yb', 71 => 'Lu', 72 => 'Hf',
      73 => 'Ta', 74 => 'W',  75 => 'Re', 76 => 'Os', 77 => 'Ir', 78 => 'Pt', 79 => 'Au', 80 => 'Hg',
      81 => 'Tl', 82 => 'Pb', 83 => 'Bi', 84 => 'Po', 85 => 'At', 86 => 'Rn', 87 => 'Fr', 88 => 'Ra',
      89 => 'Ac', 90 => 'Th', 91 => 'Pa', 92 => 'U',  93 => 'Np', 94 => 'Pu', 95 => 'Am', 96 => 'Cm',
      97 => 'Bk', 98 => 'Cf', 99 => 'Es', 100 => 'Fm', 101 => 'Md', 102 => 'No', 103 => 'Lr', 104 => 'Rf',
      105 => 'Db', 106 => 'Sg', 107 => 'Bh', 108 => 'Hs', 109 => 'Mt', 110 => 'Ds', 111 => 'Rg', 112 => 'Cn',
      113 => 'Nh', 114 => 'Fl', 115 => 'Mc', 116 => 'Lv', 117 => 'Ts', 118 => 'Og'
    }
  end

  private

  def read_siesta_struct_out
    File.open(@inf, 'r') do |file|
      lines = file.readlines
      @lattice_vectors = lines[0..2].map { |line| line.split.map(&:to_f) }
      latt_mat = Matrix.rows(@lattice_vectors)

      @number_of_atoms = lines[3].to_i

      lines[4..].each do |line|
        _, atomic_number, x, y, z = line.split
        fractional_coord = Matrix.row_vector([x.to_f, y.to_f, z.to_f])
        cartesian_coord = (fractional_coord * latt_mat).to_a[0]

        @coordinates << { atom: self.class.chemical_symbol(atomic_number.to_i),
                          x: cartesian_coord[0],
                          y: cartesian_coord[1],
                          z: cartesian_coord[2] }
      end
    end
  end

  def read_vasp_poscar
    File.open(@inf, 'r') do |file|
      lines = []
      icar = []
      chem = [] # chemical symbols
      file.each_with_index do |line, index|
        lines << line
        icar << index if line.start_with?('Cartesian')
      end
      elements = lines[0].split.map(&:to_s)
      j = icar[0]
      n_elements = lines[j - 1].split.map(&:to_i)
      @number_of_atoms = n_elements.sum
      n_elements.each_with_index do |n, i|
        n.times { chem << elements[i] }
      end
      @lattice_vectors = lines[2..4].map { |line| line.split.map(&:to_f) }
      atomic_positions = lines[(j + 1)..].map { |line| line.split.map(&:to_f) }
      chem.each_with_index do |element, i|
        position = atomic_positions[i]
        @coordinates << { atom: element, x: position[0], y: position[1], z: position[2] }
      end
    end
  end

  def read_xyz
    File.open(@inf, 'r') do |file|
      lines = file.readlines
      @number_of_atoms = lines[0].to_i
      lines[2..].each do |line|
        coord = line.split

        @coordinates << { atom: coord[0].to_s,
                          x: coord[1].to_f,
                          y: coord[2].to_f,
                          z: coord[3].to_f }
      end
      @lattice_vectors = extract_lattice_vector(lines)
    end
  end

  def extract_lattice_vector(lines)
    match = lines[1].match(/Lattice="(.*)"/)
    if match
      match[1].split.each_slice(3).map { |slice| slice.map(&:to_f) }.take(3)
    else
      generate_lattice_vector(lines)
    end
  end

  def generate_lattice_vector(lines)
    # create a cubic unit cell with a lattice constant that is twice the minimum
    # necessary to fit the molecule
    coords = lines[2..].map { |line| line.split[1..3].map(&:to_f) }
    x, y, z = coords.transpose
    center = [(x.min + x.max) / 2.0, (y.min + y.max) / 2.0, (z.min + z.max) / 2.0]
    a = [x, y, z].map { |coord| coord.max - coord.min }.max * 2.0

    # move the molecule to the center of the cell
    @coordinates.each do |atom|
      atom[:x] = (atom[:x] - center[0]) + a / 2.0
      atom[:y] = (atom[:y] - center[1]) + a / 2.0
      atom[:z] = (atom[:z] - center[2]) + a / 2.0
    end

    [[a, 0.0, 0.0], [0.0, a, 0.0], [0.0, 0.0, a]]
  end

  def lattice_to_cell
    @cell_parameters = Cell.parameters(@lattice_vectors)
  end
end
