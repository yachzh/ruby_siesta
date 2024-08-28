# frozen_string_literal: true

def distance(point1, point2)
  x1, y1, z1 = point1
  x2, y2, z2 = point2
  Math.sqrt((x2 - x1)**2 + (y2 - y1)**2 + (z2 - z1)**2)
end

point1 = [0.5,        0.25,       0.75      ]
point2 = [0.5,        0.27272727, 0.72727273]
distance = distance(point1, point2)
puts "The distance between the two points is #{distance}"
