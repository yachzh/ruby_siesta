# frozen_string_literal: true

# bp = 'GMKG'

# label = []

# bp.each_char do |k|
#  label << if k == 'G'
#             '\\Gamma'
#           else
#             k
#           end
# end

# puts label
# npoints=[1,20,25,30]
# kcoord=[[1.000,1.000,1.000],[0.000,0.000,0.000],[2.000,0.000,0.000],[2.000,2.000,2.000]]
# label=['L','\\Gamma','X','\\Gamma']
#
# %block BandLines
# 1   1.000  1.000  1.000  L
# 20  0.000  0.000  0.000  \Gamma
# 25  2.000  0.000  0.000  X
# 30  2.000  2.000  2.000  \Gamma
# %endblock BandLines
# npoints = [1, 20, 25, 30]
# kcoord = [[1.000, 1.000, 1.000], [0.000, 0.000, 0.000], [2.000, 0.000, 0.000], [2.000, 2.000, 2.000]]
# label = ['L', '\\Gamma', 'X', '\\Gamma']
# block = []
# block << "%block BandLines"
# npoints.zip(kcoord, label).each do |np, kc, lb|
#   block << "#{np}   #{kc.join('  ')}  #{lb}"
# end

# block << "%endblock BandLines"

# puts block
# npoints = [1, 20, 25, 30]
# kcoord = [[1.000, 1.000, 1.000], [0.000, 0.000, 0.000], [2.000, 0.000, 0.000], [2.000, 2.000, 2.000]]
# label = ['L', '\\Gamma', 'X', '\\Gamma']

# block = []
# block << "%block BandLines"
# npoints.zip(kcoord, label).each do |np, kc, lb|
#   block << "#{format('%3d',np)}  #{kc.map { |x| "%6.3f" % x }.join(' ')}  #{lb}"
# end
# block << "%endblock BandLines"

# puts block
# def generate_npoints(bp: nil, ngrid: 420)
#  return if bp.nil?
#  num_of_bandlines=bp.length - 1
#  puts "Number of band lines #{num_of_bandlines}"
#  np_per_line=ngrid/num_of_bandlines
#  puts "Number of points per line #{np_per_line}"
# end
#
# generate_npoints(bp: 'GMKG')

def generate_npoints(bp, ngrid)
  raise 'Error: bp cannot be nil' if bp.nil?

  num_of_bandlines = bp.split('').length - 1
  puts "Number of band lines #{num_of_bandlines}"
  np_per_line = ngrid / num_of_bandlines
  puts "Number of points per line #{np_per_line}"
  npoints = [1]
  (num_of_bandlines - 1).times { npoints << np_per_line }
  npoints << ngrid - np_per_line * (num_of_bandlines - 1)
  npoints
end

# generate_npoints(['G', 'M', 'K', 'G'], 420)
puts generate_npoints('GMKG', 425)
