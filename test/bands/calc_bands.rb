$LOAD_PATH << '../../lib'
require 'siesta'
require 'pycall'
require 'data_io'

xc = 'LDA'
a0 = 3.195
geom=PyCall.import_module('ase.build').bulk('GaN', crystalstructure='wurtzite', a=a0)
cell = geom.get_cell(complete=true)
bp = cell.bandpath('GMKGALHA', npoints=0)
kpoints = bp.kpts
xk=[]
kpoints.each do |py_xk|
  xk << DataIO.to_a(py_xk)  
end
puts kpoints
dft=Siesta.new(DataIO.atoms2struct(geom))
dft.xc(xc)
dft.kpoint(kmesh: [9,9,9])
dft.bands(bandpath: 'GMKGALHA',xk: xk, ngrid: 350)
dft.write_fdf
# dft.energy
