#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'siesta_dos'

U = 4.0
xc = 'LDA'
spin = 'ls'
syslabel = "#{xc}-U#{format('%.1f', U)}-#{spin}"
dos = SiestaDos.new(syslabel)
dos.ao('fe', '3d')
dos.plot(show: true)
