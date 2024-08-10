#!/usr/bin/env ruby
# frozen_string_literal: true

# numerical utils
class NumRuby
  def self.linspace(fstart, fend, n_points)
    h = (fend - fstart) / (n_points - 1).to_f
    (fstart..fend).step(h).to_a
  end

  def self.fun_array(fun_name, xarr)
    result = []
    xarr.each do |x|
      result << method(fun_name.to_sym).call(x)
    end
    result
  end

  def self.math_array(math_name, xarr)
    result = []
    xarr.each do |x|
      result << Math.send(math_name.to_sym, x)
    end
    result
  end

  def self.trapz(yarr, xarr)
    res = 0.0
    (0...xarr.length - 1).each do |i|
      res += (xarr[i + 1] - xarr[i]) * (yarr[i + 1] + yarr[i]) / 2.0
    end
    res
  end

  def self.weight_average(y, x)
    area = trapz(y, x)
    weighted_values = y.zip(x).map { |ey, ex| ey * ex / area }
    trapz(weighted_values, x)
  end

  def self.band_center(dos, e_ef, occ: nil)
    s_dos = []
    s_energy = []

    e_ef.each_with_index do |value, i|
      if occ.nil? || (occ && value.negative?) || (!occ && value.positive?)
        s_energy << value
        s_dos << dos[i]
      end
    end

    weight_average(s_dos, s_energy)
  end
end
