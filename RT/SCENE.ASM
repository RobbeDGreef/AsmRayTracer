IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "utils.inc"
include "mm.inc"

include "rt/scene.inc"
include "rt/ray.inc"
include "rt/hit.inc"

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
    local @@closest_hit:dword, @@temp_hit:Hit, @@hit_something:dword
    uses ebx, ecx, edx 

    mov eax, [@@t_max]
    mov [@@closest_hit], eax
    mov [@@hit_something], 0

    mov ebx, [@@scene]
    mov ecx, [ebx+Scene.head]

@@objectloop:
    cmp ecx, 0
    je @@end

    lea eax, [@@temp_hit]
    mov edx, [ecx+SceneElement.object]
    call [edx+Object.hit_function], edx, [@@ray], [@@t_min], [@@closest_hit], \
         eax
    cmp eax, 1
    jne @@no_hit


    mov [@@hit_something], 1
    lea eax, [@@temp_hit]
    call hit_cpy, [@@hit], eax
    mov eax, [eax+Hit.t]
    mov [@@closest_hit], eax

@@no_hit:
    mov ecx, [ecx+SceneElement.next]
    jmp @@objectloop

@@end:
    mov eax, [@@hit_something]
    ret
endp scene_hit

END