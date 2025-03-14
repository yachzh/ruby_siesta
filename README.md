# Siesta
---------------

A Ruby script to call Siesta for simulations of molecules and solids.

### Installation
---------------

To use this project, follow these steps:

1. **Clone the repository**: Run `git clone https://github.com/yachzh/ruby_siesta.git` to download the project.
2. **Get pseudopotentials**: Run `git clone https://github.com/yachzh/siesta_pseudo.git` to obtain the pseudopotentials in psf format for Siesta.
3. **Install dependencies**: Ensure you have Ruby (version >= 2.6.8) and Siesta (version >= 4.1.5) installed on your system.
4. **Set Ruby library path**: Append the `ruby_siesta/lib` directory to the Ruby library path using `export RUBYLIB=/path/to/ruby_siesta/lib`.
5. **Define pseudopotential path**: Set the path to `siesta_pseudo` using `export SIESTA_PP_PATH=path/to/siesta_pseudo`.
6. **Configure Siesta command**: To run Siesta with 8 CPU cores, set the command to `export RUBY_SIESTA_COMMAND="mpirun -np 8 siesta PREFIX.fdf > PREFIX.out"`.

### Example Usage
---------------

Here's an example of how to use the project:
```ruby
# Import the Siesta module
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
```

### Note
Make sure to replace `/path/to/ruby_siesta/lib` and `/path/to/siesta_pseudo` with the actual paths on your system.
