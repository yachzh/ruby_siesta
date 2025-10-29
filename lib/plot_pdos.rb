#!/usr/bin/env ruby
# frozen_string_literal: true

require 'siesta_dos'
require 'matrix'
require 'data_io'
require 'num_ruby'

# call siesta_dos, plot all 3d orbitals
class PlotPdos < SiestaDos
  def initialize(system_label, atom_or_index)
    super(system_label)
    atom(atom_or_index)
    @orb_3d = %w[dxy dyz dxz dx2-y2 dz2]
  end

  def plot_3d(show: false)
    pre = "#{@asp}_3d_split"
    generate_data
    gnuplot_3d(pre)
    DataIO.gnuplot(@gp_commands)
    return unless show

    system("eps-read #{pre}.eps")
  end

  def plot_t2geg(show: false)
    pre = "#{@asp}_t2geg"
    generate_data
    sum_dos
    gnuplot_t2geg(pre)
    DataIO.gnuplot(@gp_commands)
    return unless show

    system("eps-read #{pre}.eps")
  end

  def bandcenter_t2geg
    plot_t2geg if @energy.nil?
    e_ef = @energy.map { |e| e - @ef }

    bc_t2g = NumRuby.band_center(@t2g_up, e_ef, occ: true)
    bc_eg = NumRuby.band_center(@eg_up, e_ef, occ: false)
    puts "BAND CENTER of occupied t2g: #{format('%.2f', bc_t2g)} eV"
    puts "BAND CENTER of unoccupied eg: #{format('%.2f', bc_eg)} eV"

    delta = bc_eg - bc_t2g
    puts "Crystal-field splitting #{format('%.2f', delta)} eV"
    [bc_t2g, bc_eg, delta]
  end

  private

  def sum_dos
    d_hash = {}
    %w[xy xz yz x2-y2 z2].each do |orb|
      fn = @dat_hash["d#{orb}"]
      d_hash[orb] = [DataIO.read_file(fn, 0), DataIO.read_file(fn, 1), DataIO.read_file(fn, 2)]
    end

    @energy = d_hash['xy'][0]

    @t2g_up, t2g_dn = read_data(d_hash, 'xy', 'xz', 'yz')
    @eg_up, eg_dn = read_data(d_hash, 'x2-y2', 'z2')
    DataIO.write_dat("#{@asp}_t2g.dat", @energy, @t2g_up, t2g_dn)
    DataIO.write_dat("#{@asp}_eg.dat", @energy, @eg_up, eg_dn)
  end

  def read_data(d_hash, *orb)
    d_up = Vector.zero(d_hash[orb[0]][0].length)
    d_dn = Vector.zero(d_hash[orb[0]][0].length)
    orb.each do |o|
      d_up += Vector[*d_hash[o][1]]
      d_dn += Vector[*d_hash[o][2]]
    end
    [d_up.to_a, d_dn.to_a]
  end

  def gnuplot_3d(prefix)
    @gp_commands = %(
      set term post eps color solid enh font 22
      set encoding utf8
      set key left bottom
      set output "#{prefix}.eps"
      set arrow from 0.0, graph 0 to 0.0, graph 1 nohead
      set ylabel 'PDOS (arb. units)'
      set xlabel '{/Times-Italic E} - {/Times-Italic E_F} (eV)'
      set xrange [-10:5]
      plot "#{@dat_hash[@orb_3d[0]]}" u ($1 - #{@ef}):($2) w l lt 0 lw 3.0 t "#{@orb_3d[0]}", \
      "" u ($1 - #{@ef}):(-1*$3) w l lt 0 lw 3.0 t '',\ )

    (1..@orb_3d.length - 1).each do |i|
      @gp_commands = @gp_commands.dup
      @gp_commands << %("#{@dat_hash[@orb_3d[i]]}" u ($1 - #{@ef}):($2) w l lt #{i}  lw 3.0 t "#{@orb_3d[i]}", \
      "" u ($1 - #{@ef}):(-1*$3) w l lt #{i} lw 3.0 t '',\ )
    end
    File.write("#{prefix}.plt", @gp_commands)
  end

  def gnuplot_t2geg(prefix)
    @gp_commands = %(
      set term post eps color solid enh font 22
      set encoding utf8
      set key left bottom
      set output "#{prefix}.eps"
      set arrow from 0.0, graph 0 to 0.0, graph 1 nohead
      set ylabel 'PDOS (arb. units)'
      set xlabel '{/Times-Italic E} - {/Times-Italic E_F} (eV)'
      set xrange [-10:5]
      plot "#{@asp}_t2g.dat" u ($1 - #{@ef}):($2) w l lt 7 lw 3.0 t "t_{2g}", \
      "" u ($1 - #{@ef}):(-1*$3) w l lt 7 lw 3.0 t '',\
      "#{@asp}_eg.dat" u ($1 - #{@ef}):($2) w l lt -1 dt 2 lw 3.0 t "e_g", \
      "" u ($1 - #{@ef}):(-1*$3) w l lt -1 dt 2 lw 3.0 t '')

    File.write("#{prefix}.plt", @gp_commands)
  end

  def generate_data
    @dat_hash = {}
    @orb_3d.each do |dorb|
      orbital("3#{dorb}")
      read_dos
      @dat_hash[dorb] = @dat
    end
  end
end
