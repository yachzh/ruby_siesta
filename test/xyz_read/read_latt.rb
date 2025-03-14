# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'struct_reader'
require 'pycall'

def struct2ase(struct)
  ase = PyCall.import_module('ase')
  ase_obj = ase.Atoms.new(struct[:coordinates].map do |coord|
                            ase.Atom.new(coord[:atom], [coord[:x], coord[:y], coord[:z]])
                          end)
  ase_obj.set_cell(struct[:lattice_vectors])
  ase_obj.set_pbc([true, true, true])

  ase_obj
end

solid = StructReader.new('freemol-FeP-is.xyz')
geom = solid.struct
atoms = struct2ase(geom)
PyCall.import_module('ase.io').write('ase_new.xyz', atoms)
