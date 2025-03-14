from ase.build import bulk
from ase import io

a0 = 3.195
geom = bulk('GaN', crystalstructure='wurtzite', a=a0)
io.write('gan.vasp', geom)
# PC = geom.get_cell(complete=True)
# bp = PC.bandpath('GMKGALHA', npoints=0)
# kpoints = bp.kpts
# print(kpoints)
