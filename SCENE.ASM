IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "scene.inc"
include "ray.inc"
include "hit.inc"
include "utils.inc"
include "mm.inc"

CODESEG

proc scene_init
    arg @@scene:PTR Scene
    uses eax

    mov eax, [@@scene]
    mov [eax+Scene.head], 0

    ret
endp scene_init

proc scene_add
    arg @@scene:PTR Scene, @@object:PTR Object
    uses eax, ebx, ecx, edx
    mov ebx, [@@scene]
    mov ecx, [ebx+Scene.head]
    
    call alloc, size SceneElement
    mov [eax+SceneElement.next], ecx
    mov [ebx+Scene.head], eax
    mov edx, [@@object]
    mov [eax+SceneElement.object], edx

    ret
endp scene_add

proc scene_hit
    arg @@scene:PTR Scene, @@ray:PTR Ray, @@t_min:dword, @@t_max:dword,\
        @@hit:PTR Hit
    uses ebx, ecx, edx 

    mov ebx, [@@scene]
    mov ecx, [ebx+Scene.head]
    
@@objectloop:
    cmp ecx, 0
    je @@no_hit

    mov edx, [ecx+SceneElement.object]
    call [edx+Object.hit_function], edx, [@@ray], [@@t_min], [@@t_max], [@@hit]
    cmp eax, 1
    je @@end

    mov ecx, [ecx+SceneElement.next]
    jmp @@objectloop

@@no_hit: 
    mov eax, 0

@@end:
    ret
endp scene_hit

END