# frozen_string_literal: true

$LOAD_PATH << '../../lib'

require 'minitest/autorun'
require 'struct_reader'
require 'data_io'
require 'pycall'

class HashEqualityTest < Minitest::Test
  def test_hashes_are_equal
    fn = 'slab.STRUCT_OUT'
    solid = StructReader.new(fn)
    hash1 = solid.struct
    atoms = PyCall.import_module('ase.io').read(fn)
    hash2 = DataIO.atoms2struct(atoms)
    assert array_equality(solid.lattice_vectors, hash2[:lattice_vectors], 1e-6)
    assert hash_equality(solid.cell_parameters, hash2[:cell_parameters], 1e-6)
    assert array_equality(solid.coordinates, hash2[:coordinates], 1e-6)
    assert hash_equality(hash1, hash2, 1e-6)
    assert_equal(solid.number_of_atoms, atoms.get_global_number_of_atoms)
  end

  private

  def hash_equality(hash1, hash2, tolerance)
    return false unless hash1.keys.sort == hash2.keys.sort

    hash1.each do |key, value|
      case value
      when Hash
        return false unless hash_equality(value, hash2[key], tolerance)
      when Array
        return false unless array_equality(value, hash2[key], tolerance)
      when Float
        return false unless (value - hash2[key]).abs < tolerance
      else
        return false unless value == hash2[key]
      end
    end

    true
  end

  def array_equality(array1, array2, tolerance)
    return false unless array1.size == array2.size

    array1.each_with_index do |element1, index|
      element2 = array2[index]

      case element1
      when Hash
        return false unless hash_equality(element1, element2, tolerance)
      when Array
        return false unless array_equality(element1, element2, tolerance)
      when Float
        return false unless (element1 - element2).abs < tolerance
      else
        return false unless element1 == element2
      end
    end

    true
  end
end
