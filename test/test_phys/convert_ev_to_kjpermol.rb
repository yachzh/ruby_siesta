# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'phys'

energy_in_ev = 10
energy_in_kj_per_mol = energy_in_ev / (Phys::kJ / Phys::mol)
energy_in_j_per_mol = energy_in_ev / (Phys::J / Phys::mol)
puts "Energy in kJ/mol: #{energy_in_kj_per_mol}"
puts "Energy in J/mol: #{energy_in_j_per_mol}"
