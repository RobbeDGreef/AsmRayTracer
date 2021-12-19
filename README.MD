# RayTracer
VUB second bachelor assembly programming project.

## To run the raytracer
In dosbox execute the following command

    RUN.BAT

Since the concept of a raytracer is inherently slow, it is adivced to hold 
increase dosbos' cyles. This can be done by pressing CTRL+F12 multiple times
or set it in the dosbox.conf file. Setting it to about 3GHz (3000000 cycles)
should be enough to speed up the raytracer significantly.

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

### Requirements
You need to have `make`, `nasm`, `ld` and `python3` installed. On top of that
you need 32 bit linux C libraries and your operating system needs to be able to 
run 32 bit executables. **For example if you want to run this on windows,
WSL 1 is not able to do this you will need WSL 2**.

	make -f LMAKEFILE

*The code currently contains a bug which doesn't show the ray traced ball in
linux mode but this bug will soon be fixed*

## Current state of things
![Suzanne render](saved/metal_suzanne.bmp?raw=true "Loaded object")
![Sphere reflections](saved/positional_camera.bmp?raw=true "Reflections")

## Coding style
### Line limit
No line should be longer than 80 characters. You can use a backtick '\' to split
a line up.

### File names
All file names should be upper case.

### Assembly instructions and directives
Assembly language is case insensitive but try to leave everything lowercase. 

## Todo
- [x] utility functions
  - [x] print_float
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
  - [x] vec_cpy
  - [x] vec_eq
- [x] Frame buffer class
  - [x] Essentially a large buffer that has a function to copy itself to memory
- [x] Ray class
  - [x] struct implementation 
  - [x] getters and setters
  - [x] at(float t) function (origin + t*direction)
- [x] Compatability mode for easier debugging and profiling
- [x] Multiple samples
- [x] Shading
- [x] Camera
  - [x] Positioned
  - [x] ViewAt
- [ ] Materials
  - [ ] Diffuse materials
    - [x] Simple perfect diffuse
    - [ ] Configurable diffuse
  - [ ] metallic materials
    - [x] Simple perfect metallic
    - [ ] Configurable metallic
  - [x] Unlit
  - [x] UV
  - [ ] Dielectric (maybe)
- [ ] Scene system
  - [x] Simple linked list
  - [ ] BVH trees (maybe)
- [x] Objects
  - [x] Spheres
  - [x] Triangles
  - [x] Loading wavefront OBJ files