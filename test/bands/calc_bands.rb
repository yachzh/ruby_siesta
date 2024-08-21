$LOAD_PATH << '../../lib'
require 'siesta'
require 'pycall'
require 'data_io'

xc = 'LDA'
geom=PyCall.import_module('ase.build').bulk('GaN', crystalstructure='wurtzite', a=a0)
cell = geom.get_cell(complete=True)
bp = cell.bandpath('GMKGALHA', npoints=0)
kpoints = bp.kpts
dft=Siesta.new(DataIO.atoms2struct(geom))
dft.xc(xc)
dft.kpoint(kmesh: [9,9,9])
dft.bands(bandpath: 'GMKGALHA',xk: kpoints, ngrid: 350)
dft.write_fdf
# dft.energy
