#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'
require 'phys'
require 'time_converter'

magcenter = 'fe'
U = 4.0
xc = 'LDA'
resultfile = File.open('result.txt', 'w')
energies = {}

%w[hs ls].each do |state|
  start_time = Time.now
  dft = Siesta.import_from_file("#{state}.STRUCT_OUT")
  dft.xc(xc)
  dft.label("#{xc}-U#{format('%.1f', U)}-#{state}")
  dft.parameters(beta: 0.01, nmaxold: 7)
  dft.spin(pol: true) if state == 'hs'
  dft.initial_spin(atom: magcenter, spin_state: state)
  dft.plus_u(atom: magcenter, orbital: '3d', hubbard_u: U)
  dft.pdos
  energy = dft.energy
  energies[state] = energy
  end_time = Time.now
  walltime = TimeConverter.sec2time(end_time - start_time)
  resultfile.puts "#{state} #{format('%14.6f', energy)} Walltime: #{format('%10s', walltime)}"
end

e_hl = (energies['hs'] - energies['ls']) / (Phys.kJ / Phys.mol)
resultfile.puts "E_hl = #{format('%5.1f', e_hl)} kJ/mol"
resultfile.close
