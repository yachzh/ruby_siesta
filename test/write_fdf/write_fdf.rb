# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'

dft = Siesta.import_from_file('slab.vasp')
dft.xc('pw91')
dft.kpoint(kmesh: [30, 30, 30])
dft.parameters(basis: 'TZP', meshcutoff: '200 Ry', temperature: '1000 K')
#dft.spin(pol: true)
# dft.plus_d2
dft.write_fdf
