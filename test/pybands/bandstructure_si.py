#!/usr/bin/env python

"""Band structure tutorial

Calculate the band structure of Si along high symmetry directions
Brillouin zone
"""

import time
from pylab import figure, plot, xticks, axis, xlabel, ylabel, title, savefig
from gpawdev import band_gap
from sec2time import sec2time
import numpy as np
from ase.build import bulk
from ase.dft.kpoints import ibz_points, get_bandpath
from gpaw import GPAW, PW, FermiDirac
import matplotlib as mpl
mpl.use('Agg')

with open('result.txt', 'w') as resultfile:
    # Perform standard ground state calculation (with plane wave basis)
    si = bulk('Si', 'diamond', 5.4844519562)

    start_time = time.time()
    print('ground state calculation\n', file=resultfile)

    calc = GPAW(mode=PW(400),
                xc='PBE',
                kpts=(8, 8, 8),
                # random guess (needed if many onoccupied bands required)
                random=True,
                occupations=FermiDirac(0.01),
                txt='Si_gs.txt')
    si.set_calculator(calc)
    e = si.get_potential_energy()
    calc.write('Si_gs.gpw')
    ef = calc.get_fermi_level()
    end_time_f = time.time()
    walltime_f = sec2time(end_time_f - start_time)
    bandgap = band_gap(calc)

    print('E = %20.6f, Ef = %10.6f\n' % (e, ef), file=resultfile)
    print('Walltime: %10s' % walltime_f, file=resultfile)
    print('************', file=resultfile)

    nbands = 8

    # Restart from ground state and fix potential:
    print('band structure calculation\n', file=resultfile)
    calc = GPAW('Si_gs.gpw',
                nbands=16,
                fixdensity=True,
                symmetry='off',
                convergence={'bands': nbands})
    end_time_s = time.time()
    walltime_s = sec2time(end_time_s - start_time)
    print('Walltime: %10s' % walltime_s, file=resultfile)
    print('************', file=resultfile)

    # Use ase.dft module for obtaining k-points along high symmetry directions
    points = ibz_points['fcc']
    G = points['Gamma']
    X = points['X']
    W = points['W']
    K = points['K']
    L = points['L']
    kpts, x, X = get_bandpath([W, L, G, X, W, K], calc.atoms.cell, npoints=60)
    calc.set(kpts=kpts)
    calc.get_potential_energy()
    e_kn = np.array([calc.get_eigenvalues(k) for k in range(len(kpts))])
    print('kpts:', file=resultfile)
    print(kpts, file=resultfile)
    print('x:', file=resultfile)
    print(x, file=resultfile)
    print('X:', file=resultfile)
    print(X, file=resultfile)
    print('e_kn', file=resultfile)
    print(e_kn, file=resultfile)

    # Plot the band structure
    print('plotting...\n', file=resultfile)

    e_kn -= ef
    emin = e_kn.min() - 1.0
    emax = e_kn[:, nbands].max() + 1.0

    print('emin = %10.6f, emax = %10.6f' % (emin, emax), file=resultfile)

    figure(figsize=(6, 6))
    for n in range(nbands):
        plot(x, e_kn[:, n])
    for p in X:
        plot([p, p], [emin, emax], 'k-')
    plot([0, X[-1]], [0, 0], 'k-')
    xticks(X, ['$%s$' % n for n in ['W', 'L', r'\Gamma', 'X', 'W', 'K']])
    axis(xmin=0, xmax=X[-1], ymin=emin, ymax=emax)
    xlabel('$k$-vector')
    ylabel('E - E$_F$ (eV)')
    title('Bandstructure of Silicon, $E_g=%.2f$' % bandgap)
    savefig('bandstructure.png')
