# frozen_string_literal: true

require 'fileutils'

# some utility methods relevant to data io
class DataIO
  def self.copy_file(src, tar, fil)
    source_path = File.join(src, fil)
    destination_path = File.join(tar, fil)
    FileUtils.cp(source_path, destination_path)
  end

  def self.read_file(fil, colidx)
    col = []
    File.open(fil).each do |line|
      col << line.split.map(&:to_f) unless line.start_with?('#')
    end
    mat = col.transpose
    mat[colidx]
  end

  def self.write_dat(fil, *data_array)
    File.open(fil, 'w') do |f|
      data_array.transpose.each do |line|
        formatted_line = line.map { |num| format('%15.8f', num) }.join(' ')
        f.puts formatted_line
      end
    end
  end

  def self.to_a(py_array)
    ruby_array = []
    (0...py_array.size).each { |i| ruby_array << py_array[i] }

    ruby_array
  end

  def self.atoms2struct(atoms)
    # Extract structural parameters from ASE object
    cellpar = to_a(atoms.cell.cellpar).map(&:to_f)

    cell_parameters = {
      a: cellpar[0],
      b: cellpar[1],
      c: cellpar[2],
      alpha: cellpar[3],
      beta: cellpar[4],
      gamma: cellpar[5]
    }

    latt = []
    3.times { |i| latt << to_a(atoms.cell[i]) }
    lattice_vectors = latt.map { |a| a.map(&:to_f) }

    chem = atoms.get_chemical_symbols.to_a
    coordinates = []

    chem.each_with_index do |element, i|
      position = to_a(atoms.positions[i]).map(&:to_f)
      coordinates << { atom: element.to_s, x: position[0], y: position[1], z: position[2] }
    end

    # Create the crystal structure hash
    {
      cell_parameters: cell_parameters,
      lattice_vectors: lattice_vectors,
      coordinates: coordinates
    }
  end

  def self.gnuplot(commands)
    IO.popen('gnuplot', 'w') do |io|
      io.puts commands
      io.close_write
    end
  end

  def self.python(commands)
    pipe = IO.popen('python', 'w+')
    pipe.puts(commands)
    pipe.close_write
    pipe.read
  end
end
