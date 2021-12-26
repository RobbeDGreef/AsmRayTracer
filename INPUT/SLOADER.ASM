IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "input/objload.inc"
include "input/sloader.inc"

include "rt/scene.inc"
include "rt/sphere.inc"
include "rt/vec.inc"

include "rt/mat/lmbrtian.inc"
include "rt/mat/metal.inc"
include "rt/mat/glass.inc"
include "rt/mat/unlit.inc"
include "rt/mat/emissive.inc"

include "rt/texture/solid.inc"
include "rt/texture/image.inc"
include "rt/texture/uv.inc"
include "rt/texture/tiles.inc"

include "utils.inc"
include "mm.inc"

CODESEG

;; This code will load a scene from file and add them to the scene. 
;; The format of these configuration files is:
;; object
;;  <argument>
;;  ...
;; object
;;  <argument>
;;  ...
;; ...
;;
;; As you can see every time you add arguments to an entry you increment the
;; indentation with 1 space.
;; Arguments must be in order
;; object accepts two arguments: 
;; 
;; object
;;  sphere
;;   <location:vec>
;;   <radius:float>
;;   <material>
;;
;; or 
;;
;; object
;;  model
;;   <path:string>
;;   <material>
;;
;; Materials can be of type lambertian, glass, unlit, metal or emissive
;; each have their own arguments
;;
;; lambertian
;;  <texture>
;;
;; metal
;;  <texture>
;;
;; glass
;;  <IOR value:float>
;;  <texture>
;;
;; unlit
;;  <color:vec>
;;
;; emissive
;;  <color:vec>
;;  <strength:float>
;;
;; On top of that we support a wide range of textures:
;; image, solid, tiles, uv
;;
;; image
;;  <path:string>
;; 
;; solid
;;  <color:vec>
;;
;; tiles
;;  <prim color:vec>
;;  <sec color:vec>
;;  <scale:float>
;;
;; uv (takes no arguments
;;

MAX_LINE_LEN equ 128

TYPE_OBJECT     equ 0
TYPE_MODEL      equ 1
TYPE_MATERIAL   equ 2
TYPE_TEXTURE    equ 3
TYPE_VEC        equ 4
TYPE_FLOAT      equ 5
TYPE_STRING     equ 6


;; There is a lot of code that looks similar but is different enough to be 
;; copied. It is annoying but a limitation of assembly.

;; =============================================================================
;; Texture interpretation code
;; =============================================================================
proc interpret_solid
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    local @@vec_buffer:Vec
    uses ebx

    mov eax, [@@indent]
    inc eax
    lea ebx, [@@vec_buffer]

    call interpret_line, [@@scene], [@@file_handle], eax, TYPE_VEC, ebx
    cmp eax, 0
    je @@end

    call alloc, size Solid
    call solid_init, eax, ebx

@@end:
    ret
endp interpret_solid

proc interpret_image
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    local @@path_buf:byte:128
    uses ebx

    mov eax, [@@indent]
    inc eax
    lea ebx, [@@path_buf]
    ;; Read the texture path 
    call interpret_line, [@@scene], [@@file_handle], eax, TYPE_STRING, ebx
    cmp eax, 0
    je @@end

    lea ebx, [@@path_buf]
    call alloc, size Image
    call image_init, eax, ebx

@@end:
    ret
endp interpret_image

proc interpret_tiles
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    local @@prim_vec:Vec, @@sec_vec:Vec
    uses ebx, ecx, edx, edi

    mov ebx, [@@indent]
    inc ebx
    lea ecx, [@@prim_vec]
    ;; Read the primary color 
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_VEC, ecx
    cmp eax, 0
    je @@end

    lea edx, [@@sec_vec]
    ;; Read the secondary color 
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_VEC, edx
    cmp eax, 0
    je @@end

    ;; Finally read the scaling
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_FLOAT, 0
    cmp eax, 0
    je @@end

    mov edi, eax

    call alloc, size Tiles
    call tiles_init, eax, ecx, edx, edi

@@end:
    ret
endp interpret_tiles

proc interpret_uv
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword

    call alloc, size Uv
    call uv_init, eax

@@end:
    ret
endp interpret_uv

;; =============================================================================
;; Material interpretation code
;; =============================================================================

proc interpret_lambertian
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    uses ebx

    mov eax, [@@indent]
    inc eax
    ;; Load the texture
    call interpret_line, [@@scene], [@@file_handle], eax, TYPE_TEXTURE, 0
    cmp eax, 0
    je @@end

    mov ebx, eax

    call alloc, size Lambertian
    call lambertian_init, eax, ebx

@@end:
    ret
endp interpret_lambertian

proc interpret_metal
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    uses ebx

    mov eax, [@@indent]
    inc eax
    ;; Load the texture
    call interpret_line, [@@scene], [@@file_handle], eax, TYPE_TEXTURE, 0
    cmp eax, 0
    je @@end

    mov ebx, eax

    call alloc, size Metal
    call metal_init, eax, ebx

@@end:
    ret
endp interpret_metal

proc interpret_unlit
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    local @@vec_buf:Vec
    uses ebx

    mov eax, [@@indent]
    inc eax
    lea ebx, [@@vec_buf]
    ;; Load the color
    call interpret_line, [@@scene], [@@file_handle], eax, TYPE_VEC, ebx
    cmp eax, 0
    je @@end

    lea ebx, [@@vec_buf]
    call alloc, size Unlit
    call unlit_init, eax, ebx

@@end:
    ret
endp interpret_unlit

proc interpret_emissive
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    local @@vec_buf:Vec
    uses ebx, ecx

    mov ebx, [@@indent]
    inc ebx
    lea eax, [@@vec_buf]
    ;; Load the color
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_VEC, eax
    cmp eax, 0
    je @@end

    ;; Read the strength (a float)
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_FLOAT, 0
    cmp eax, 0
    je @@end

    mov ecx, eax
    lea ebx, [@@vec_buf]
    call alloc, size Unlit
    call unlit_init, eax, ebx, ecx

@@end:
    ret
endp interpret_emissive

proc interpret_glass
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    uses ebx, ecx, edx

    mov ebx, [@@indent]
    inc ebx

    ;; Load the texture
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_TEXTURE, 0
    cmp eax, 0
    je @@end
    mov ecx, eax

    ;; Read the IOR value (float)
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_FLOAT, 0
    mov edx, eax 

    call alloc, size Glass
    call glass_init, eax, ecx, edx

@@end:
    ret
endp interpret_glass

;; =============================================================================
;; Model interpretation code
;; =============================================================================
;; Create a sphere
proc interpret_sphere
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    local @@vec_buf:Vec, @@radius:dword
    uses ebx, ecx

    ;; sphere syntax:
    ;; sphere
    ;;  <location:vec>
    ;;  <radius:float>
    ;;  <material>

    mov ebx, [@@indent]
    inc ebx

    ;; Interpret the location (a vector)
    lea ecx, [@@vec_buf]
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_VEC, ecx
    ;; Return if we had an error
    cmp eax, 0
    je @@end

    ;; Interpret the radius (a float)
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_FLOAT, 0
    cmp eax, 0
    je @@end
    mov [@@radius], eax

    ;; Interpret the material
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_MATERIAL, 0
    cmp eax, 0
    je @@end

    ;; The material pointer
    mov ebx, eax

    ;; Allocate a new sphere and load it with the parsed values, after that
    ;; return
    call alloc, size Sphere
    call sphere_set, eax, ecx, [@@radius], ebx
    call scene_add, [@@scene], eax
    mov eax, 1

@@end:
    ret
endp interpret_sphere

;; Load a wavefront OBJ file.
proc interpret_model
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword
    local @@vec_buf:Vec, @@radius:dword, @@path_buf:byte:128
    uses ebx, ecx

    ;; model syntax:
    ;; model
    ;;  <path:string>
    ;;  <material>

    mov ebx, [@@indent]
    inc ebx

    ;; Read the path
    ;; I don't like allocating a string on the stack but we have to since a
    ;; global variable could overwritten if the code below somewhere in the
    ;; recursion requires a string again. This can even happen with models
    ;; and image textures so we have to be careful.
    lea ecx, [@@path_buf]
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_STRING, ecx
    cmp eax, 0
    je @@end
    
    ;; Load the material
    call interpret_line, [@@scene], [@@file_handle], ebx, TYPE_MATERIAL, 0
    cmp eax, 0
    je @@end

    lea ebx, [@@path_buf]
    call obj_load, [@@scene], eax, ebx
    mov eax, 1

@@end:
    ret
endp interpret_model

;; =============================================================================
;; The main recursive line reader code
;; =============================================================================

;; Helper to check indentation
proc check_indent
    arg @@line:PTR byte, @@indent:dword
    uses ebx

    mov eax, [@@line]
    mov ebx, 0
@@check_loop:
    cmp ebx, [@@indent]
    je @@end_success

    ;; Check if we have an indent
    cmp [byte ptr eax+ebx], ' '
    jne @@end_error

    inc ebx
    jmp @@check_loop

@@end_error:
    mov eax, 0
    jmp @@end

@@end_success:
    mov eax, 1

@@end:
    ret
endp check_indent


;; The type specifies which type of object we are looking for
;; The buffer is an optional argument that can get used by some values when
;; allocating on the stack would be wasteful.
proc interpret_line
    arg @@scene:PTR Scene, @@file_handle:dword, @@indent:dword, @@type:dword,\
        @@buffer:dword
    uses ebx, ecx

    call log_int, [@@type]

    ;; First read a line from the file
    call read_line_from_file, [@@file_handle], offset line_buf, MAX_LINE_LEN
    
    ;; If we read an empty line something is wrong and we must scream in terror 
    cmp [byte line_buf], 0
    je @@end_line_error

    ;; Once the line is valid check if it has valid indentation otherwise, once
    ;; again scream
    call check_indent, offset line_buf, [@@indent]
    cmp eax, 1
    jne @@end_ident_error

    ;; Skip over the spaces in the line
    mov ebx, offset line_buf
    add ebx, [@@indent]

    ;; Now interpreting lines
    ;; -------------------------------------------------------------------------
    ;; Jumptable
    ;; -------------------------------------------------------------------------
    cmp [@@type], TYPE_OBJECT
    je @@check_object
    cmp [@@type], TYPE_MODEL
    je @@check_model
    cmp [@@type], TYPE_MATERIAL
    je @@check_material
    cmp [@@type], TYPE_TEXTURE
    je @@check_texture
    cmp [@@type], TYPE_VEC
    je @@check_vec
    cmp [@@type], TYPE_FLOAT
    je @@check_float
    cmp [@@type], TYPE_STRING
    je @@check_string
    
    ;; None of the above, not a valid type
    call log_str, offset str_invalid_type
    mov eax, 0
    jmp @@end

    ;; -------------------------------------------------------------------------
    ;; Object 
    ;; -------------------------------------------------------------------------
@@check_object:
    ;; Each entry in the file has to start with 'object' (this might change in
    ;; the future). So we will just immediately recurse and return whatever
    ;; the new call to interpret_line yields
    call memcmp, ebx, offset str_object, [str_object_len]
    cmp eax, 0
    jne @@expected_object

    ;; found object specifier, go one indentation deeper and recurse
    mov eax, [@@indent]
    inc eax
    call interpret_line, [@@scene], [@@file_handle], eax, TYPE_MODEL, 0
    ;; return whatever this returns
    jmp @@end

    ;; -------------------------------------------------------------------------
    ;; Models (sphere, OBJ model)
    ;; -------------------------------------------------------------------------
@@check_model:
    call memcmp, ebx, offset str_sphere, [str_sphere_len]
    cmp eax, 0
    jne @@not_sphere
    call interpret_sphere, [@@scene], [@@file_handle], [@@indent]
    jmp @@end

@@not_sphere:
    call memcmp, ebx, offset str_model, [str_model_len]
    cmp eax, 0
    jne @@not_model
    call interpret_model, [@@scene], [@@file_handle], [@@indent]
    jmp @@end
@@not_model:
    jmp @@expected_model

    ;; -------------------------------------------------------------------------
    ;; Materials
    ;; -------------------------------------------------------------------------
@@check_material:
    call memcmp, ebx, offset str_lambertian, [str_lambertian_len]
    cmp eax, 0
    jne @@not_lam
    call interpret_lambertian, [@@scene], [@@file_handle], [@@indent]
    jmp @@end

@@not_lam:
    call memcmp, ebx, offset str_glass, [str_glass_len]
    cmp eax, 0
    jne @@not_glass

    call interpret_glass, [@@scene], [@@file_handle], [@@indent]

    jmp @@end
@@not_glass:
    call memcmp, ebx, offset str_metal, [str_metal_len]
    cmp eax, 0
    jne @@not_metal

    call interpret_metal, [@@scene], [@@file_handle], [@@indent]

    jmp @@end
@@not_metal:
    call memcmp, ebx, offset str_emissive, [str_emissive_len]
    cmp eax, 0
    jne @@not_emissive

    call interpret_emissive, [@@scene], [@@file_handle], [@@indent]

    jmp @@end
@@not_emissive:
    call memcmp, ebx, offset str_unlit, [str_unlit_len]
    cmp eax, 0
    jne @@not_unlit

    call interpret_unlit, [@@scene], [@@file_handle], [@@indent]

    jmp @@end
@@not_unlit:

    jmp @@expected_material

    ;; -------------------------------------------------------------------------
    ;; Textures
    ;; -------------------------------------------------------------------------
@@check_texture:
    call memcmp, ebx, offset str_solid, [str_solid_len]
    cmp eax, 0
    jne @@not_solid

    call interpret_solid, [@@scene], [@@file_handle], [@@indent]
    jmp @@end
@@not_solid:
    call memcmp, ebx, offset str_image, [str_image_len]
    cmp eax, 0
    jne @@not_image

    call interpret_image, [@@scene], [@@file_handle], [@@indent]
    jmp @@end
@@not_image:
    call memcmp, ebx, offset str_tiles, [str_tiles_len]
    cmp eax, 0
    jne @@not_tiles

    call interpret_tiles, [@@scene], [@@file_handle], [@@indent]
    jmp @@end
@@not_tiles:
    call memcmp, ebx, offset str_uv, [str_uv_len]
    cmp eax, 0
    jne @@not_uv

    call interpret_uv, [@@scene], [@@file_handle], [@@indent]
    jmp @@end
@@not_uv:

    jmp @@expected_texture

    ;; -------------------------------------------------------------------------
    ;; Vector & float
    ;; -------------------------------------------------------------------------
@@check_vec:
    cmp [byte ptr ebx], '-'
    je @@allowed_vec_value
    cmp [byte ptr ebx], '0'
    jl @@expected_vec
    cmp [byte ptr ebx], '9'
    jg @@expected_vec

@@allowed_vec_value:
    ;; Store the vector in the given buffer
    mov ecx, [@@buffer]
    
    ;; Read the first float
    call atof, ebx
    mov [ecx], eax

    ;; Floats are split up by spaces so find the next space
    call strchr, ebx, ' '
    mov ebx, eax
    ;; Skip over the space
    inc ebx

    ;; float y
    call atof, ebx
    mov [ecx+4], eax

    call strchr, ebx, ' '
    mov ebx, eax
    inc ebx
    ;; float z
    call atof, ebx
    mov [ecx+8], eax

    mov eax, ecx
    jmp @@end

@@check_float:
    cmp [byte ptr ebx], '-'
    je @@allowed_float_value
    cmp [byte ptr ebx], '0'
    jl @@expected_float
    cmp [byte ptr ebx], '9'
    jg @@expected_float

@@allowed_float_value:
    ;; Load the float
    call atof, ebx
    jmp @@end

    ;; -------------------------------------------------------------------------
    ;; String
    ;; -------------------------------------------------------------------------
@@check_string:
    call strlen, ebx
    inc eax ;; copy the nullbyte
    call memcpy, [@@buffer], ebx, eax
    mov eax, [@@buffer]
    jmp @@end

    ;; -------------------------------------------------------------------------
    ;; Errors
    ;; -------------------------------------------------------------------------
    
    ;; Todo: this is code duplication, use macro
@@expected_material:
    call log_str, offset str_expected_material
    mov eax, 0
    jmp @@end

@@expected_texture:
    call log_str, offset str_expected_texture
    mov eax, 0
    jmp @@end

@@expected_float:
    call log_str, offset str_expected_float
    mov eax, 0
    jmp @@end

@@expected_vec:
    call log_str, offset str_expected_vec
    mov eax, 0
    jmp @@end

@@expected_object:
    call log_str, offset str_expected_object
    mov eax, 0
    jmp @@end

@@expected_model:
    call log_str, offset str_expected_model
    mov eax, 0
    jmp @@end

@@end_line_error:
    call log_str, offset str_read_null_line
    mov eax, 0
    jmp @@end

@@end_ident_error:
    call log_str, offset str_wrong_indent
    mov eax, 0
    jmp @@end

@@end:
    ret
endp interpret_line


;; =============================================================================
;; Loader startup code
;; =============================================================================

;; This function loads a scene from file.
proc scene_load
    arg @@scene:PTR Scene, @@path:PTR byte
    local @@scene_file_handle:dword, @@line:dword
    uses eax

    call open_file, [@@path], 0
    mov [@@scene_file_handle], eax    

@@readline:
    call interpret_line, [@@scene], [@@scene_file_handle], 0, TYPE_OBJECT, 0
    cmp eax, 0
    je @@end

    jmp @@readline

@@end:
    call close_file, [@@scene_file_handle]
    ret
endp scene_load

DATASEG
    line_buf db MAX_LINE_LEN dup (?)
    text_buffer db MAX_LINE_LEN dup (?)

    str_read_null_line  db "Read a null line while parsing object", 0
    str_wrong_indent    db "Read line with wrong indentation (argument expected)", 0

    ;; Object
    str_object      db "object", 0
    str_object_len  dd 6

    ;; Models
    str_sphere      db "sphere", 0
    str_sphere_len  dd 6
    str_model       db "model", 0
    str_model_len  dd 5

    ;; Materials
    str_lambertian      db "lambertian", 0
    str_lambertian_len  dd 10
    str_glass           db "glass", 0
    str_glass_len       dd 5
    str_metal           db "metal", 0
    str_metal_len       dd 5
    str_emissive        db "emissive", 0
    str_emissive_len    dd 8
    str_unlit           db "unlit", 0
    str_unlit_len       dd 5

    ;; Textures
    str_solid       db "solid", 0
    str_solid_len   dd 5
    str_image       db "image", 0
    str_image_len   dd 5
    str_tiles       db "tiles", 0
    str_tiles_len   dd 5
    str_uv          db "uv", 0
    str_uv_len      dd 2

    ;; Errors
    str_unknown_element db "Unknown element", 0
    str_invalid_type db "Invalid type given", 0

    str_expected_model db "Expected a model specifier", 0
    str_expected_object db "Expected a object specifier", 0
    str_expected_vec db "Expected a vector specifier", 0
    str_expected_float db "Expected a float specifier", 0
    str_expected_material db "Expected a material specifier", 0
    str_expected_texture db "Expected a texture specifier", 0

END