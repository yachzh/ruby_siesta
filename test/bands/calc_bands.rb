# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'
require 'pycall'
require 'data_io'
require 'matrix'

a0 = 3.195
geom = PyCall.import_module('ase.build').bulk('GaN', 'wurtzite', a0)
cell = geom.get_cell(true)
kpath = 'GMKGALHA'
bp = cell.bandpath(kpath, 0)
kpoints = bp.kpts
rb_array = []
kpath.split('').length.times { |i| rb_array << DataIO.to_a(kpoints[i]) }
xk = rb_array.map { |a| a.map(&:to_f) }

dft = Siesta.new(DataIO.atoms2struct(geom))
dft.xc('LDA')
dft.kpoint(kmesh: [15, 15, 15])
dft.bands(bandpath: kpath, xk: xk, ngrid: 350)
dft.write_fdf
dft.energy
