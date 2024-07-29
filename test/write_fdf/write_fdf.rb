# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'

dft = Siesta.import_from_file('hs.STRUCT_OUT')
dft.parameters(basis: 'TZP', meshcutoff: '200 Ry', temperature: '1000 K')
dft.spin(pol: true, fixspin: true)
dft.initial_spin(atom: 'fe', spin_state: 'hs')
# dft.plus_d2
dft.write_fdf
