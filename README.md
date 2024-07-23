# siesta

A ruby script to call siesta

## Example Usage

To use this project, follow these steps:

1. Clone the repository: `git clone https://github.com/yachzh/ruby_siesta.git`
2. Download the pseudopotentials (psf format) for siesta `git clone https://github.com/yachzh/siesta_pseudo.git` 
3. Install Ruby (version 3.2.2) and Siesta (version 4.1.5)
4. Add ruby_siesta to ruby library path: `export RUBYLIB=/path/to/ruby_siesta`
5. Specify the path to siesta_pseudo `export SIESTA_PP_PATH=path/to/siesta_pseudo`
6. If you want to run siesta using 8 CPU cores, you can set the command `export RUBY_SIESTA_COMMAND="mpirun -np 8 siesta PREFIX.fdf > PREFIX.out"`

### Example Code

Here's an example of how to use the project:
```ruby
require 'siesta'

siesta = Siesta.import_from_file('input.STRUCT_OUT')
siesta.label('silicon')
siesta.xc('PBE')
siesta.spin(pol: false)
siesta.kpoint(kmesh: [9, 9, 9])
energy = siesta.energy
puts "Total energy: #{energy} eV"

