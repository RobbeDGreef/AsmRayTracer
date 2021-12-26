IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "rt/vec.inc"
include "rt/scene.inc"
include "rt/mat/mat.inc"
include "input/objload.inc"
include "rt/triangle.inc"
include "mm.inc"

CODESEG

MAX_LINE_LEN equ 128

;; This file implements Wavefront (triangulated) OBJ loading. However it isn't
;; fullproof. It breaks easily if you try to load models that are structured 
;; correctly according to spec but not in the way you would expect. For example.
;; if you were to add two spaces between vertices instead of one, our loader 
;; would fail. However, we are aiming to support models created by blender and
;; that works fine since blender doesn't do such annoying things.

;; This function interprets a facet (triangle) and adds it to the scene.
;; It looks the vertex locations up in our vertex table
proc interpret_face
    arg @@scene:PTR Scene, @@mat:PTR Mat
    local @@x:dword, @@y:dword, @@z:dword
    uses eax, ebx, ecx, edx, edi, esi
    ;; A facet line has the format 'f x/xt/xv y/yt/yv z/zt/zv'

    mov ebx, offset line_buf
    
    ;; Skip over 'f '
    add ebx, 2

    ;; Problem is, the xt and xv are optional. We will not use them
    ;; (at least for now, but I don't think we have time to implement texture 
    ;; coordinates etc)

    call atoi, ebx
    ;; Indexes of vertexes in OBJ files start at 1. But since we use indexes
    ;; that start at 0 we have to decrement by 1
    dec eax
    mov [@@x], eax

    ;; Search for the next space in the string
    call strchr, ebx, ' '
    mov ebx, eax
    
    ;; skip over that space so we end up at the next int value
    inc ebx

    call atoi, ebx
    dec eax
    mov [@@y], eax

    ;; Search for the final space in the string
    call strchr, ebx, ' '
    mov ebx, eax
    
    ;; skip over the space
    inc ebx

    call atoi, ebx
    dec eax
    mov [@@z], eax

    ;; Allocate the triangle on the heap
    call alloc, size Triangle
    mov ebx, eax

    ;; Find x in the vertex table
    mov eax, VEC_SIZE
    mul [@@x]
    add eax, [vertex_table]
    mov ecx, eax

    ;; Find y in the vertex table
    mov eax, VEC_SIZE
    mul [@@y]
    add eax, [vertex_table]
    mov edi, eax

    ;; Find z in the vertex table
    mov eax, VEC_SIZE
    mul [@@z]
    add eax, [vertex_table]
    mov edx, eax

    ;; Finally now that we have all the face info we can add it to the scene
    call triangle_set, ebx, ecx, edi, edx, [@@mat]
    call scene_add, [@@scene], ebx
    
    ret
endp interpret_face

proc interpret_vec
    local @@x:dword, @@y:dword, @@z:dword
    uses eax, ebx
    ;; Vertexes are in the format 'v x y z [w]' with an optional w
    ;; but we will not use the optional w (i've also never actually seen it
    ;; being used so I don't know what it means)

    mov ebx, offset line_buf
    
    ;; skip over characters 'v '
    add ebx, 2

    call atof, ebx
    mov [@@x], eax

    ;; Search for the next space in the string
    call strchr, ebx, ' '
    mov ebx, eax
    
    ;; skip over the space
    inc ebx

    call atof, ebx
    mov [@@y], eax

    ;; Search for the final space in the string
    call strchr, ebx, ' '
    mov ebx, eax
    
    ;; skip over the space
    inc ebx

    call atof, ebx
    mov [@@z], eax

    ;; now add our parsed vertex to the vertex table
    cmp [vertex_table], 0
    jne @@increase_table

    call alloc, VEC_SIZE
    mov [vertex_table], eax

@@increase_table:
    inc [vertex_table_size]

ifdef NASM
    ;; See the comment below. We can't do this for linux since here we have an
    ;; actual proper memory manager. So what we *can* do is reallocate the 
    ;; vertex table. Now this works but this is INCREDIBLY inefficient. And 
    ;; the inefficiency is notable. Loading a model on linux takes a significant
    ;; amount of time. However we are not focussing on optimizing for linux
    ;; so for now this hack will do.
    mov eax, VEC_SIZE
    mul [vertex_table_size]
    call realloc, [vertex_table], eax
    mov [vertex_table], eax
else
    ;; Because of the way our memory manager works we can just alloc and it will
    ;; come right after the previous allocation in memory. Now this is hacky 
    ;; because we break abstraction here. I don't like it. However, writing an 
    ;; ENTIRE memory manager right now at the end of the project seems out of 
    ;; scope and overkill. Memory managers take a while to get right and prone 
    ;; to hard to track bugs so for now this will do.
    call alloc, VEC_SIZE
endif

    ;; Finally add the vertex to the vertex buffer
    mov eax, VEC_SIZE
    mul [vertex_table_size]
    sub eax, VEC_SIZE
    add eax, [vertex_table]
    call vec_set, eax, [@@x], [@@y], [@@z]

@@end:
    ret
endp interpret_vec

;; This function loads an object from file in wavefront OBJ file format and 
;; adds it to the scene. It doesn't support transformations and objects HAVE to
;; be triangulated. If they are not, only one triangle of your facet will be 
;; visible and the model will have holes in it.
proc obj_load
    arg @@scene:PTR Scene, @@mat:PTR Mat, @@path:PTR byte
    local @@obj_file_handle:dword, @@line:dword
    uses eax

    call open_file, [@@path], 0
    mov [@@obj_file_handle], eax    

    ;; We just read one line at a time since OBJ formats are build up like that.
@@readline:
    call read_line_from_file, [@@obj_file_handle], offset line_buf, MAX_LINE_LEN
    cmp [byte line_buf], 0
    je @@end
    mov [@@line], offset line_buf

    ;; Vertex lines start with a 'v ' (the space is important since there are 
    ;; other types of objects in this file that start with a v but have multiple
    ;; letters, for example 'vt' or 'vn')
    cmp [byte line_buf], 'v'
    jne @@add_face
    cmp [byte line_buf+1], ' '
    jne @@add_face

    call interpret_vec

    jmp @@skipline

@@add_face:
    ;; Facet lines start with a 'f '. I don't know of any other objects that 
    ;; start with an 'f' but it seems good practice to look for the space
    cmp [byte line_buf], 'f'
    jne @@skipline
    cmp [byte line_buf+1], ' '
    jne @@skipline
    
    call interpret_face, [@@scene], [@@mat]

@@skipline:
    jmp @@readline

@@end:
    call close_file, [@@obj_file_handle]
    ret
endp obj_load

DATASEG
    vertex_table dd 0
    vertex_table_size dd 0
    line_buf db MAX_LINE_LEN dup (?)

END