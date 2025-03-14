# frozen_string_literal: true

module Phys
  ELEMENTARY_CHARGE = 1.6021766208e-19 # C
  AVOGADRO_CONSTANT = 6.022140857e23 # mol^-1
  BOLTZMANN_CONSTANT = 1.38064852e-23 # kB
  J = 1 / ELEMENTARY_CHARGE

  def self.eV
    1.0
  end

  def self.kJ
    1000 * J
  end

  def self.kcal
    4.184 * kJ
  end

  def self.mol
    AVOGADRO_CONSTANT
  end

  def self.J
    J
  end

  def self.kB
    BOLTZMANN_CONSTANT / ELEMENTARY_CHARGE
  end
end
