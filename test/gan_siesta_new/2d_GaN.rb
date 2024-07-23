# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'
require 'read_geom'

solid = ReadGeom.new('slab.STRUCT_OUT')
siesta = Siesta.new(solid.cryst)
siesta.label('2dgan')
siesta.xc('PBE')
siesta.spin(pol: false)
siesta.kpoint(kmesh: [30, 30, 1])
ecal = siesta.energy
puts "Total energy: #{format('%.4f', ecal)} eV"
