# frozen_string_literal: true

#bp = 'GMKG'
#
#label = []
#
#bp.each_char do |k|
#  label << if k == 'G'
#             '\\Gamma'
#           else
#             k
#           end
#end
#
#puts label
#npoints=[1,20,25,30]
#kcoord=[[1.000,1.000,1.000],[0.000,0.000,0.000],[2.000,0.000,0.000],[2.000,2.000,2.000]]
#label=['L','\\Gamma','X','\\Gamma']
#
#%block BandLines
#1   1.000  1.000  1.000  L       
#20  0.000  0.000  0.000  \Gamma  
#25  2.000  0.000  0.000  X       
#30  2.000  2.000  2.000  \Gamma  
#%endblock BandLines
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
npoints = [1, 20, 25, 30]
kcoord = [[1.000, 1.000, 1.000], [0.000, 0.000, 0.000], [2.000, 0.000, 0.000], [2.000, 2.000, 2.000]]
label = ['L', '\\Gamma', 'X', '\\Gamma']

block = []
block << "%block BandLines"
npoints.zip(kcoord, label).each do |np, kc, lb|
  block << "#{format('%3d',np)}  #{kc.map { |x| "%6.3f" % x }.join(' ')}  #{lb}"
end
block << "%endblock BandLines"

puts block
