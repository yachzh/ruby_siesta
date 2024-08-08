# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'phys'

energy_in_ev = 10
energy_in_kj_per_mol = energy_in_ev / (PHYS::kJ / PHYS::mol)
puts "Energy in kJ/mol: #{energy_in_kj_per_mol}"
