# frozen_string_literal: true

# control fdf parameters
class Fdf
  attr_reader :fdf_parameters

  def initialize(parah)
    @fdf_parameters = parah
  end

  def update_parameters(input_hash)
    @fdf_parameters.merge!(input_hash)
  end

  def self.default_parameters
    { 'PAO.BasisSize' => 'DZP',
      'PAO.EnergyShift' => '0.02 Ry',
      'Mesh.Cutoff' => '300 Ry',
      'SaveElectrostaticPotential' => false,
      'WriteMullikenPop' => 0,
      'MullikenInSCF' => false,
      'WriteCoorXmol' => false,
      'Write.Denchar' => false,
      'SaveBaderCharge' => false,
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

  def self.custom
    { basis: ['PAO.BasisSize', 'DZP'],
      energyshift: ['PAO.EnergyShift', '50 meV'],
      meshcutoff: ['Mesh.Cutoff', '200 Ry'],
      write_pot: ['SaveElectrostaticPotential', false],
      mulliken: ['WriteMullikenPop', 1],
      print_pop: ['MullikenInSCF', false],
      write_xyz: ['WriteCoorXmol', true],
      write_denchar: ['Write.Denchar', false],
      write_bader: ['SaveBaderCharge', false],
      beta: ['SCF.Mixer.Weight', 0.07],
      nmaxold: ['SCF.Mixer.History', 5],
      kickstep: ['SCF.Mixer.Kick', 0],
      dmtol: ['SCF.DM.Tolerance', 1e-4],
      require_hconv: ['SCF.H.Converge', true],
      htol: ['SCF.H.Tolerance', '1.0 meV'],
      maxcycl: ['MaxSCFIterations', 2000],
      use_savedm: ['DM.UseSaveDM', true],
      occfun: %w[OccupationFunction MP],
      occmporder: ['OccupationMPOrder', 4],
      temperature: ['ElectronicTemperature', '1000 K'],
      charge: ['NetCharge', 0],
      dipcorr: ['Slab.DipoleCorrection', false] }
  end
end
