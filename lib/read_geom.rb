# frozen_string_literal: true

class ReadGeom
  attr_reader :lattice

  def initialize(siesta_struct_out)
    @lattice = File.open(siesta_struct_out, 'r').readlines[0..2].map { |line| line.split.map(&:to_f) }
  end
  # todo: read_chemical_symbols and corresponding coordinates
  # todo: def cryst, return cryst obj
  # todo: other types of struct files from vasp & wien2k
end
