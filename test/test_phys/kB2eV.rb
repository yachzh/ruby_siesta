# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'phys'
require 'test/unit'

class TestPhys < Test::Unit::TestCase
  def test_simple
    # convert 1000 kB to eV
    ecal = 1000 * Phys.kB
    eexp = 0.08617330337217213
    assert_in_delta(ecal, eexp, 1.0E-8)
  end
end
