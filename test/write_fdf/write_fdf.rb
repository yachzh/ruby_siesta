# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'

dft = Siesta.import_from_file('slab.vasp')
dft.xc('pw91')
dft.kpoint(kmesh: [30, 30, 30])
# dft.plus_d2
dft.write_fdf
