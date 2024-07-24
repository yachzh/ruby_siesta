#!/usr/bin/env python

import os
from ase.io import write
from ase.lattice.hexagonal import Graphene
# from ase.visualize import view

a = 3.218  # 2D GaN lattice constant by LDA, Crystals 13, 1048 (2023)
c = 3.355  # layer separation, not relevant here
vac = 20  # vacuum size on each side



def setup_struct():
    unit_cell = Graphene(symbol='C',
                         latticeconstant={
                             'a': a,
                             'c': c
                         },
                         size=(1, 1, 1),
                         pbc=(1, 1, 1))

    unit_cell.center(vacuum=vac, axis=2)
    unit_cell[0].symbol = 'Ga'
    unit_cell[1].symbol = 'N'
    slab = unit_cell.repeat((1, 1, 1))
    return slab


fn = 'slab.vasp'
geom = setup_struct()
# view(geom)
write(fn, geom)
