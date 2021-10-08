# RayTracer
VUB second bachelor assembly programming project.

## To run the raytracer
In dosbox execute the following command

    RUN.BAT

## To run the unit tests
In dosbox execute the following command

    TEST.BAT

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
- [ ] Frame buffer class
  - [ ] Essentially a large buffer that has a function to copy itself to memory
- [ ] Ray class
  - [x] struct implementation 
  - [ ] getters and setters
  - [ ] at(float t) function (origin + t*direction)