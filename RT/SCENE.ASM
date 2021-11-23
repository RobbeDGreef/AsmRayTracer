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

    ;; Sets the linked list head to NULL, essentially creating an empty list
    mov eax, [@@scene]
    mov [eax+Scene.head], 0

    ret
endp scene_init

proc scene_add
    arg @@scene:PTR Scene, @@object:PTR Object
    uses eax, ebx, ecx, edx

    ;; Adds the object to the front of the linked list.
    mov ebx, [@@scene]
    mov ecx, [ebx+Scene.head]
    
    ;; We allocate a node for the linked list on the "heap"
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

    ;; Calculates the intersection points with all objects in the scene and 
    ;; returns the closest one. This makes sure our Z layering is correct.
    mov eax, [@@t_max]
    mov [@@closest_hit], eax
    mov [@@hit_something], 0

    mov ebx, [@@scene]
    mov ecx, [ebx+Scene.head]

@@objectloop:
    cmp ecx, 0
    je @@end

    ;; Call the object specific hit function.
    lea eax, [@@temp_hit]
    mov edx, [ecx+SceneElement.object]
    call [edx+Object.hit_function], edx, [@@ray], [@@t_min], [@@closest_hit], \
         eax
    cmp eax, 1
    jne @@no_hit

    ;; If we hit something, check if it is closer by than the last hit. If it
    ;; was closer, we will overwrite the previous hit and closest_hit values.
    mov [@@hit_something], 1
    lea eax, [@@temp_hit]
    call hit_cpy, [@@hit], eax
    mov eax, [eax+Hit.t]
    mov [@@closest_hit], eax

@@no_hit:
    ;; Next scene element
    mov ecx, [ecx+SceneElement.next]
    jmp @@objectloop

@@end:
    mov eax, [@@hit_something]
    ret
endp scene_hit

END