# Import the Siesta module
$LOAD_PATH << '../../lib'
require 'siesta'

# Create a new Siesta instance from a file
siesta = Siesta.import_from_file('input.STRUCT_OUT') # Supports *.STRUCT_OUT, *.vasp (*poscar*), *.xyz files

# Set the label for the simulation
siesta.label('silicon')

# Set the exchange-correlation functional
siesta.xc('PBE')

# Set the spin polarization
siesta.spin(pol: false)

# Set the k-point mesh
siesta.kpoint(kmesh: [9, 9, 9])

# Calculate the total energy
energy = siesta.energy

# Print the result
puts "Total energy: #{energy} eV" #=> Total energy: -214.148814 eV
