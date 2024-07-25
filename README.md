# siesta

A ruby script to call siesta

## Example Usage

To use this project, follow these steps:

1. Clone the repository using the command: `git clone https://github.com/yachzh/ruby_siesta.git`
2. Get the pseudopotentials in psf format for Siesta by running: `git clone https://github.com/yachzh/siesta_pseudo.git`
3. Install Ruby (version >= 2.6.8) and Siesta (version >= 4.1.5)
4. Append ruby_siesta/lib to the Ruby library path using: `export RUBYLIB=/path/to/ruby_siesta/lib`
5. Define the path to siesta_pseudo using: `export SIESTA_PP_PATH=path/to/siesta_pseudo`
6. To run Siesta with 8 CPU cores, set the command to: `export RUBY_SIESTA_COMMAND="mpirun -np 8 siesta PREFIX.fdf > PREFIX.out"`

### Example Code

Here's an example of how to use the project:
```ruby
require 'siesta'

siesta = Siesta.import_from_file('input.STRUCT_OUT') # *.vasp (*poscar*), *.xyz
siesta.label('silicon')
siesta.xc('PBE')
siesta.spin(pol: false)
siesta.kpoint(kmesh: [9, 9, 9])
energy = siesta.energy
puts "Total energy: #{energy} eV" #=> Total energy: -214.178136 eV

