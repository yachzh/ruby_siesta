# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'read_geom'
require 'pycall'

def cryst2ase(cryst)
  ase = PyCall.import_module('ase')
  ase_obj = ase.Atoms.new(cryst[:coordinates].map do |coord|
                            ase.Atom.new(coord[:atom], [coord[:x], coord[:y], coord[:z]])
                          end)
  ase_obj.set_cell(cryst[:lattice_vectors])
  ase_obj.set_pbc([true, true, true])

  ase_obj
end

solid = ReadGeom.new('freemol-FeP-is.xyz')
# latt_vec =solid.lattice_vectors
geom = solid.cryst
atoms = cryst2ase(geom)
PyCall.import_module('ase.io').write('ase_new.xyz', atoms)
# coord=solid.coordinates
# cellpar=solid.cell_parameters
# geom = solid.cryst
# puts latt_vec.inspect
# puts coord.inspect
# puts cellpar.inspect
# puts geom.inspect
