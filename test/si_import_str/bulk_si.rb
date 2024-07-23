# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'

siesta = Siesta.import_from_file('input.STRUCT_OUT')
siesta.label('silicon')
siesta.xc('PBE')
siesta.spin(pol: false)
siesta.kpoint(kmesh: [9, 9, 9])
ecal = siesta.energy
puts "Total energy: #{format('%.4f', ecal)} eV"
