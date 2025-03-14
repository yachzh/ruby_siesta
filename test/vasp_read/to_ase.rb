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

solid = StructReader.new('molhsN2Site.vasp')
# latt_vec =solid.lattice_vectors
# coord=solid.coordinates
# cellpar=solid.cell_parameters
geom = solid.struct
atoms = struct2ase(geom)
puts atoms.get_global_number_of_atoms
# puts latt_vec.inspect
# puts coord.inspect
# puts cellpar.inspect
# puts geom.inspect
