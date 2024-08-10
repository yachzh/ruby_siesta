#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'plot_pdos'
U = 4.0
xc = 'LDA'
spin = 'ls'
syslabel = "#{xc}-U#{format('%.1f', U)}-#{spin}"
dos = PlotPdos(syslabel, 'fe')
dos.plot_3d(show: true)
