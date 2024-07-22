# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'read_geom'
solid=ReadGeom.new('slab.STRUCT_OUT')
latt_vec =solid.lattice

puts latt_vec.inspect
