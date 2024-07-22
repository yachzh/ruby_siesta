# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'

si_bulk = PyCall.import_module('ase.build').bulk('Si')
siesta = Siesta.new(DataIO.atoms2cryst(si_bulk))
siesta.label('silicon')
siesta.xc('PBE')
siesta.spin(pol: false)
siesta.kpoint(kmesh: [9, 9, 9])
ecal = siesta.energy
puts "Total energy: #{format('%.4f', ecal)} eV"
