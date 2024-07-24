# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'read_geom'
solid=ReadGeom.new('molhsN2Site.vasp')
latt_vec =solid.lattice_vectors
# coord=solid.coordinates
# cellpar=solid.cell_parameters
geom=solid.cryst

#puts latt_vec.inspect
# puts coord.inspect
# puts cellpar.inspect
puts geom.inspect
