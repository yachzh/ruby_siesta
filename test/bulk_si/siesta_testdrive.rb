# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'
require 'test/unit'
require 'pycall'

class TestSiesta < Test::Unit::TestCase
  def test_simple
    si_bulk = PyCall.import_module('ase.build').bulk('Si')
    siesta = Siesta.new(DataIO.atoms2cryst(si_bulk))
    siesta.label('silicon')
    siesta.xc('PW92')
    siesta.spin(pol: false)
    siesta.kpoint(kmesh: [9, 9, 9])
    ecal = siesta.energy
    eexp = -215.594961
    assert_in_delta(ecal, eexp, 1.0E-6)
  end
end
