# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'
require 'pycall'
require 'data_io'

a0 = 5.48
geom = PyCall.import_module('ase.build').bulk('Si', 'diamond', a0)
cell = geom.get_cell(true)
kpath = 'WLGXWK'
bp = cell.bandpath(kpath, 0)
kpoints = bp.kpts
rb_array = []
kpath.split('').length.times { |i| rb_array << DataIO.to_a(kpoints[i]) }
xk = rb_array.map { |a| a.map(&:to_f) }

dft = Siesta.new(DataIO.atoms2struct(geom))
dft.xc('PBE')
dft.kpoint(kmesh: [15, 15, 15])
dft.bands(bandpath: kpath, xk: xk, ngrid: 480)
dft.energy
