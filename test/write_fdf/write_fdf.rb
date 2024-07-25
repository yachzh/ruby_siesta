# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta'

siesta=Siesta.import_from_file('mol-opt.xyz')
siesta.xc('pbe')
siesta.plus_d2
siesta.write_fdf
