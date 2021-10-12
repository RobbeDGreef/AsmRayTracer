# RayTracer
VUB second bachelor assembly programming project.

## To run the raytracer
In dosbox execute the following command

    RUN.BAT

## To run the unit tests
In dosbox execute the following command

    TEST.BAT

## Build the ray tracer for linux (x86)
TASM assembly code doesn't normally run on linux, however since the instructions
are more or less the same. We can use a different compiler (NASM) to compile the
actual instructions. The only problem is all the TASM specific syntax. For this
I wrote a small transpiler in python that converts the TASM code to NASM. This
together with NASMs "tasm compatability mode" (very very minimal compatability
but usefull none the less). We can build the code for linux. Ofcourse DOS
specific syscalls had to be replaced with their alternatives but this is not a 
big problem, we can just use `ifdef NASM <nasm code> else <tasm code> endif`
macros.

	make -f LMAKEFILE

## Coding style
### Line limit
No line should be longer than 80 characters. You can use a backtick '\' to split
a line up.

### File names
All file names should be upper case.

### Assembly instructions and directives
Assembly language is case insensitive but try to leave everything lowercase. 

## Todo
- [ ] utility functions
  - [ ] print_float
- [ ] Implement the vec class
  - [x] struct implementation
  - [x] getters and setters
  - [x] vec-vec
  - [x] vec+vec
  - [x] vec*float
  - [x] vec/float
  - [x] length()
  - [x] length_squared()
  - [x] dot product
  - [x] vector cross
  - [ ] unit vector (vec / vec_length)
  - [-] vec_cpy
  - [-] vec_eq
- [x] Frame buffer class
  - [x] Essentially a large buffer that has a function to copy itself to memory
- [ ] Ray class
  - [x] struct implementation 
  - [ ] getters and setters
  - [ ] at(float t) function (origin + t*direction)
- [x] Compatability mode for easier debugging and profiling