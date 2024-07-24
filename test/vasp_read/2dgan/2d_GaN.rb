# frozen_string_literal: true

$LOAD_PATH << '../../../lib'
require 'siesta'

siesta = Siesta.import_from_file('slab.vasp')
siesta.label('2dgan')
siesta.xc('PBE')
siesta.spin(pol: false)
siesta.kpoint(kmesh: [30, 30, 1])
ecal = siesta.energy
puts "Total energy: #{format('%.4f', ecal)} eV"
