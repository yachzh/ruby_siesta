# frozen_string_literal: true

require 'cell'
require 'matrix'

# read crystal structure from struct files produced by siesta, vasp
class ReadGeom
  attr_reader :lattice_vectors, :coordinates, :cell_parameters

  def initialize(file_name)
    fn_dc = file_name.downcase
    if fn_dc.end_with?('.struct_out')
      read_siesta_struct_out(file_name)
    elsif fn_dc.end_with?('.vasp') || fn_dc.include?('poscar')
      read_vasp_poscar(file_name)
    else
      puts 'Only implemented for struct_out (siesta) and poscar (vasp)'
    end
  end

  def cryst
    # Create the crystal structure hash
    {
      cell_parameters: Cell.parameters(@lattice_vectors),
      lattice_vectors: @lattice_vectors,
      coordinates: @coordinates
    }
  end

  def read_siesta_struct_out(file_name)
    File.open(file_name, 'r') do |file|
      lines = file.readlines

      # The first three lines: a1,a2,a3
      @lattice_vectors = lines[0..2].map { |line| line.split.map(&:to_f) }
      latt_mat = Matrix.rows(@lattice_vectors)

      # line 4: number_of_atoms
      number_of_atoms = lines[3].to_i

      # line 5 to (5+number_of_atoms): i_species, atomic_number, x,y,z (frac coord)
      @coordinates = []
      lines[4..(4 + number_of_atoms)].each do |line|
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
  # TODO: other types of struct files from vasp & wien2k

  def read_vasp_poscar(_file_name)
    raise 'To be implemented...'
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
end
