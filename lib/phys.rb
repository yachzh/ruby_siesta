# frozen_string_literal: true

module PHYS
  ELEMENTARY_CHARGE = 1.6021766208e-19 # C
  AVOGADRO_CONSTANT = 6.022140857e23 # mol^-1
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
end
