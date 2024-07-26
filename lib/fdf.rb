# frozen_string_literal: true

# control fdf parameters
class Fdf
  attr_reader :fdf_parameters

  def initialize(parah)
    @fdf_parameters = parah
  end

  def self.default_parameters
    { 'PAO.BasisSize' => 'DZP',
      'PAO.EnergyShift' => '0.02 Ry',
      'Mesh.Cutoff' => '300 Ry',
      'WriteMullikenPop' => 0,
      'MullikenInSCF' => false,
      'WriteCoorXmol' => false,
      'SCF.Mixer.Weight' => 0.25,
      'SCF.Mixer.History' => 2,
      'SCF.Mixer.Kick' => 0,
      'SCF.DM.Tolerance' => 1e-4,
      'SCF.H.Converge' => true,
      'SCF.H.Tolerance' => '1.0 meV',
      'MaxSCFIterations' => 1000,
      'DM.UseSaveDM' => false,
      'OccupationFunction' => 'FD',
      'OccupationMPOrder' => 1,
      'ElectronicTemperature' => '300 K',
      'NetCharge' => 0,
      'Slab.DipoleCorrection' => false }
  end

  def update_parameters(input_hash)
    # TODO: check the validity of input keys
    @fdf_parameters.merge!(input_hash)
  end
end
