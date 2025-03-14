#!/usr/bin/env ruby
# frozen_string_literal: true

require 'data_io'
require 'json'

# read siesta pdos, call gnuplot
class SiestaDos
  attr_reader :i_atom, :dat, :asp, :ef

  def initialize(system_label)
    @sys_lab = system_label
    @inp_file = "#{@sys_lab}.PDOS"
    @i_atom = 0 # extract all atoms
    @n = 0 # all orbitals
    read_fermi_energy
    update_output
  end

  def atom(ato)
    @i_atom = if ato.is_a?(Integer)
                ato
              else
                File.foreach("#{@sys_lab}.xyz")
                    .with_index { |line, index| break index - 1 if line.match(ato.capitalize) }
              end
    update_output
  end

  def orbital(orb)
    @pao = orb
    ls = %w[s p d f g]
    @n = orb.length < 2 ? orb.to_i : orb[0].to_i
    @l = orb.length < 2 ? -1 : ls.index(orb[1]).to_i
    @m = orb.length > 2 ? read_m(orb).to_i : 9
    update_output
  end

  def ao(element, atomic_orbital)
    atom(element)
    orbital(atomic_orbital)
  end

  def read_dos
    call_fmpdos unless File.exist?(@dat)
  end

  def plot(show: false)
    read_dos unless File.exist?(@dat)
    gnuplot_commands
    DataIO.gnuplot(@gp_commands)
    return unless show

    system("eps-read #{@dat[0..-5]}.eps")
  end

  private

  def call_fmpdos
    echo_input
    @dos_commands = "#{@inp_file}\n#{@dat}\n#{@i_atom}\n#{@n}\n#{@l}\n#{@m}"
    IO.popen('fmpdos', 'w') do |io|
      io.puts @dos_commands
      io.close_write
    end
    puts "pdos data saved to #{@dat}", ''
  end

  def update_output
    @pao = 'all' if @pao.nil?
    @dat = "#{@sys_lab}_atom#{@i_atom}_#{@pao}.dat"
    @asp = "#{@sys_lab}_atom#{@i_atom}"
  end

  def echo_input
    puts 'all atoms, setting index to 0', '' if @i_atom.zero?
    puts 'extract all orbitals', '' if @n.zero?
    puts 'fmpdos INPUT >>> ', '', "Input: #{@inp_file}"
    puts "Output: #{@dat}", "Atom index: #{@i_atom}", "n = #{@n}"
    puts "l = #{@l}", "m = #{@m}" unless @n.zero?
    puts '<<<', ''
  end

  def gnuplot_commands
    @gp_commands = %(
      set term post eps color solid enh font 22
      set encoding utf8
      set output "#{@dat[0..-5]}.eps"
      set arrow from 0.0, graph 0 to 0.0, graph 1 nohead
      set ylabel 'PDOS (arb. units)'
      set xlabel '{/Times-Italic E} - {/Times-Italic E_F} (eV)'
      set xrange [-10:5]
      plot "#{@dat}" u ($1 - #{@ef}):($2) w l lw 3.0 t 'spin-up', \
      "" u ($1 - #{@ef}):(-1*$3) w l lw 3.0 t 'spin-down'
    )
    File.write("#{@dat[0..-5]}.plt", @gp_commands)
  end

  def read_fermi_energy
    File.open("#{@sys_lab}.out").each do |line|
      if line.match('Fermi')
        @ef = line.split(' ')[-1].to_f
        break
      end
    end
    File.write("#{@sys_lab}_ef.json", {:ef=>@ef}.to_json)
  end

  def read_m(orb)
    f_orbital_index = "#{@sys_lab}.ORB_INDX"
    lab = orb.slice(1, orb.length - 1)
    File.open(f_orbital_index).each do |line|
      next unless line.match(" #{lab} ")

      pd = line.split(' ')
      return pd[7] if (pd[1] == @i_atom.to_s) && (pd[5] == orb[0])
    end
    raise ArgumentError, 'orbitals not found', caller
  end
end
