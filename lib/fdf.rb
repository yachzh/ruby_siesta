# frozen_string_literal: true

# control fdf parameters
class Fdf
  attr_reader :allowed_parameters

  def initialize
    @allowed_parameters = { 'PAO.BasisSize' => 'DZP',
                            'PAO.EnergyShift' => '50 meV',
                            'Mesh.Cutoff' => '200 Ry',
                            'WriteMullikenPop' => 1,
                            'MullikenInSCF' => false,
                            'WriteCoorXmol' => true,
                            'SCF.Mixer.Weight' => 0.01,
                            'SCF.Mixer.History' => 5,
                            'SCF.Mixer.Kick' => 0,
                            'SCF.DM.Tolerance' => 1e-4,
                            'SCF.H.Converge' => true,
                            'SCF.H.Tolerance' => '1.0 meV',
                            'MaxSCFIterations' => 2000,
                            'DM.UseSaveDM' => true,
                            'OccupationFunction' => 'MP',
                            'OccupationMPOrder' => 4,
                            'ElectronicTemperature' => '1000 K',
                            'NetCharge' => 0,
                            'Slab.DipoleCorrection' => false }
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

# controller = Fdf.new

# puts 'Initial parameters:'
# controller.print_parameters

# controller.update_parameter('PAO.BasisSize', 'TZP')
# puts 'Updated PAO.BasisSize:'
# puts controller.get_parameter('PAO.BasisSize')

# controller.add_parameter('NewParameter', 'NewValue')
# puts 'Added new parameter:'
# controller.print_parameters

# controller.delete_parameter('WriteMullikenPop')
# puts 'Deleted WriteMullikenPop:'
# controller.print_parameters
