# frozen_string_literal: true

require 'matrix'

module Cell
  def self.lattice_vectors(cell_parameters)
    a = cell_parameters[:a]
    b = cell_parameters[:b]
    c = cell_parameters[:c]
    alpha = cell_parameters[:alpha] * Math::PI / 180
    beta = cell_parameters[:beta] * Math::PI / 180
    gamma = cell_parameters[:gamma] * Math::PI / 180

    cos_alpha = Math.cos(alpha)
    cos_beta = Math.cos(beta)
    cos_gamma = Math.cos(gamma)
    sin_gamma = Math.sin(gamma)

    a_vector = Vector[a, 0, 0]
    b_vector = Vector[b * cos_gamma, b * sin_gamma, 0]
    c_vector = Vector[c * cos_beta, c * (cos_alpha - cos_beta * cos_gamma) / sin_gamma,
                      c * Math.sqrt(1 - cos_alpha**2 - cos_beta**2 - cos_gamma**2 + 2 * cos_alpha * cos_beta * cos_gamma) / sin_gamma]

    [a_vector.to_a, b_vector.to_a, c_vector.to_a]
  end

  def self.parameters(lattice_vectors)
    a_ = Vector[*lattice_vectors[0]]
    b_ = Vector[*lattice_vectors[1]]
    c_ = Vector[*lattice_vectors[2]]
    a = a_.magnitude
    b = b_.magnitude
    c = c_.magnitude

    alpha = Math.acos(b_.dot(c_) / (b * c)) * (180 / Math::PI)
    beta = Math.acos(a_.dot(c_) / (a * c)) * (180 / Math::PI)
    gamma = Math.acos(a_.dot(b_) / (a * b)) * (180 / Math::PI)

    { a: a, b: b, c: c, alpha: alpha, beta: beta, gamma: gamma }
  end
end
