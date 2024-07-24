# frozen_string_literal: true

$LOAD_PATH << '../../../lib'
require 'siesta'

siesta = Siesta.import_from_file('input.STRUCT_OUT')
siesta.label('silicon')
siesta.xc('PBE')
siesta.spin(pol: false)
siesta.kpoint(kmesh: [9, 9, 9])
energy = siesta.energy
puts "Total energy: #{energy} eV"
