# frozen_string_literal: true

# control fdf parameters
class Fdf
  attr_reader :allowed_parameters

  def initialize
    @allowed_parameters = {
      'PAO.BasisSize' => 'DZP',
      'PAO.EnergyShift' => '50 meV',
      'WriteMullikenPop' => 1,
      'WriteCoorXmol' => true,
      'DM.MixingWeight' => 0.01,
      'DM.NumberPulay' => 5,
      'DM.UseSaveDM' => true,
      'DM.Tolerance' => 0.0001,
      'MaxSCFIterations' => 2000,
      'SCF.H.Converge' => true,
      'SCF.H.Tolerance' => '1.0 meV',
      'OccupationFunction' => 'MP',
      'OccupationMPOrder' => 4
    }
  end

  def get_parameter(key)
    @allowed_parameters[key]
  end

  def update_parameter(key, value)
    raise "Key #{key} does not exist" unless @allowed_parameters.key?(key)

    @allowed_parameters[key] = value
  end

  def delete_parameter(key)
    @allowed_parameters.delete(key)
  end

  def add_parameter(key, value)
    raise "Key #{key} already exists" if @allowed_parameters.key?(key)

    @allowed_parameters[key] = value
  end

  def print_parameters
    @allowed_parameters.each do |key, value|
      puts "#{key} => #{value}"
    end
  end
end

# Example usage:

controller = Fdf.new

puts 'Initial parameters:'
controller.print_parameters

controller.update_parameter('PAO.BasisSize', 'TZP')
puts 'Updated PAO.BasisSize:'
puts controller.get_parameter('PAO.BasisSize')

# controller.add_parameter('NewParameter', 'NewValue')
# puts 'Added new parameter:'
# controller.print_parameters

controller.delete_parameter('WriteMullikenPop')
puts 'Deleted WriteMullikenPop:'
controller.print_parameters
