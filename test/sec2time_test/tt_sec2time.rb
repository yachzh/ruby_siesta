# frozen_string_literal: true

$LOAD_PATH << '../../lib'
require 'time_converter'

n_seconds = 3325
puts "Wall time: #{TimeConverter.sec2time(n_seconds)}"
