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

proc bvh_list_length
    arg @@head:PTR BvhNode
    uses ebx

    mov ebx, [@@head]
    xor eax,eax
@@count_loop:
    cmp ebx, 0
    je @@end

    inc eax
    mov ebx, [ebx+BvhNode.left]
    jmp @@count_loop

@@end:
    ret
endp bvh_list_length

proc compare_axis
    arg @@node1:PTR BvhNode, @@node2:PTR BvhNode, @@axis:dword
    uses ebx, ecx

    ;; node1.box.min[axis]
    mov eax, [@@node1]
    mov eax, [eax+BvhNode.right]
    lea eax, [eax+Object.bounding_box]
    lea eax, [eax+Aabb.min]
    call vec_get_idx, eax, [@@axis]
    mov ebx, eax

    ;; node2.box.min[axis]
    mov ecx, [@@node2]
    mov ecx, [ecx+BvhNode.right]
    lea ecx, [ecx+Object.bounding_box]
    lea ecx, [ecx+Aabb.min]
    call vec_get_idx, ecx, [@@axis]

    ;; Now we compare the two values. eax will equal 1 if left is smaller than
    ;; the right after this function.
    call flt, ebx, eax
    ret
endp compare_axis

proc bvh_list_sort_by_axis
    arg @@head:PTR BvhNode, @@count:dword, @@axis:dword
    local @@start:PTR BvhNode, @@sorted:PTR BvhNode, @@smallest:PTR BvhNode, \
          @@smallest_prev:PTR BvhNode
    uses ebx, ecx, edi, esi

    ;; Pseudocode for insertion sort algorithm:
    ;; sorted = NULL
    ;; start = head
    ;; for i in range(count):
    ;;     smallest = start
    ;;     smallest_prev = null
    ;;     iter = start.next
    ;;     prev = NULL
    ;;     for j in range(count - i - 1):
    ;;         if iter < smallest:
    ;;             smallest = iter
    ;;             smallest_prev = prev
    ;;         
    ;;         prev = iter
    ;;         iter = iter.next
    ;; 
    ;;     if smallest_prev != 0:
    ;;        smallest_prev.next = smallest.next
    ;;     else:
    ;;        start = start.next
    ;; 
    ;;     smallest.next = sorted
    ;;     sorted = smallest
 
    ;; ecx will be the mainloop counter, the loop starts at 0 and runs $count 
    ;; times
    mov ecx, 0
    mov eax, [@@head]
    mov [@@start], eax
    mov [@@sorted], 0

@@mainloop:
    cmp ecx, [@@count]
    je @@end

    ;; Smallest is initially the start of the list. If we find an element 
    ;; smaller than it we will set smallest and smallest_prev to iter and prev
    ;; respectively
    mov eax, [@@start]
    mov [@@smallest], eax
    mov [@@smallest_prev], 0

    ;; iter and prev are held in edi en esi respectively
    ;; iter starts at start.next because smallest is already equal to start
    ;; so we can reduce the loop by 1
    mov edi, [@@start]
    mov edi, [edi+BvhNode.left]
    mov esi, [@@start]

    ;; We run for count - ecx - 1 times.
    ;; -1 because as previously stated iter starts at start+1 
    mov ebx, [@@count]
    sub ebx, ecx
    dec ebx
    @@search_loop:
        cmp ebx, 0
        jle @@found_element

        ;; compare iter and smallest and if smallest is smaller we set smaller
        ;; and smaller_prev to iter and prev
        call compare_axis, [@@smallest], edi, [@@axis]
        cmp eax, 1
        jne @@no_new_element
        
        mov [@@smallest], edi
        mov [@@smallest_prev], esi

        @@no_new_element:
        ;; Then just loop around and set prev to iter and iter to next
        mov esi, edi
        mov edi, [edi+BvhNode.left]

        dec ebx
        jmp @@search_loop

    @@found_element:

    ;; Once we went through the loop we are sure smaller contains the smallest
    ;; element in the list. Now we check if smallest_prev is equal to 0 or not.
    ;; If it is it means smallest is the first element in the list. If this is
    ;; the case we want to set start to start.next and we don't have to change
    ;; anything else in the list.
    cmp [@@smallest_prev], 0
    je @@smallest_is_at_front

    mov eax, [@@smallest_prev]
    mov ebx, [@@smallest]
    mov ebx, [ebx+BvhNode.left]
    mov [eax+BvhNode.left], ebx

    jmp @@list_restructure_done
@@smallest_is_at_front:
    ;; If it is not the case we will use smaller_prev to set its next pointer to
    ;; the next pointer of smaller.next, essentially cutting the 'smaller' 
    ;; element out of the list.
    mov eax, [@@start]
    mov eax, [eax+BvhNode.left]
    mov [@@start], eax

@@list_restructure_done:

    ;; Now all that is left is to add the smaller element to the sorted list.
    ;; we will do this by setting smaller.next to 'sorted' and setting sorted
    ;; to smaller.
    mov eax, [@@smallest]
    mov ebx, [@@sorted]
    mov [eax+BvhNode.left], ebx
    mov [@@sorted], eax

    inc ecx
    jmp @@mainloop

@@end:
    mov eax, [@@sorted]
    ret
endp bvh_list_sort_by_axis

;; Helper function. Displays a list until 0 is found. Usefull for debugging
proc display_list
    arg @@head:PTR BvhNode

    mov ebx, [@@head]

@@display_loop:
    cmp ebx, 0
    je @@end

    call log_hex, ebx
    
    mov ebx, [ebx+BvhNode.left]
    jmp @@display_loop

@@end:
    ret
endp display_list

;; Function used to check if the sort worked
proc test_sort
    arg @@head:PTR BvhNode, @@count:dword, @@axis:dword
    uses eax, ebx, ecx, edx

    call log_char, 'T'
    call log_int, [@@count]
    call log_int, [@@axis]

    mov ecx, 0
    mov ebx, [@@head]
@@testloop:
    cmp ecx, [@@count]
    je @@end

    mov edx, [ebx+BvhNode.right]
    lea edx, [edx+Object.bounding_box]
    lea edx, [edx+Aabb.min]

    call vec_get_idx, edx, [@@axis]
    call print_float, eax
    call print_newline

    mov ebx, [ebx+BvhNode.left]
    inc ecx
    jmp @@testloop

@@end:
    ret
endp test_sort

proc bvh_construct
    arg @@node:PTR BvhNode, @@count:dword
    local @@half_count:dword, @@firstnode:PTR BvhNode, @@middlenode:PTR BvhNode
    uses ebx, ecx, edx
    ;; This is a recursive function that will construct a bounding volume 
    ;; hierarchy tree (BVH). This is the single largest optimization of this 
    ;; entire project and it will transorm the hit function from O(n) to 
    ;; O(log(n)) it has a very significant impact on performance. Tests
    ;; indicated up to 26 times fasters for the monkey scene.
    ;; Essentially we build a binary search tree for ray intersections where 
    ;; each node has its own bounding volume box that has a size of its sub
    ;; children.
    ;;
    ;; bvh_construct:
    ;; 
    ;; if count == 1:
    ;;     return node.right
    ;; 
    ;; if count == 2:
    ;;     node.left.left = node.right
    ;;     node.left.box = surroundingBox(node.left.left, node.left.right)
    ;;     return node.left
    ;; 
    ;; else:
    ;;     randomAxis = randomInt(0, 2)
    ;;     sort(node, count, randomAxis)
    ;;     half_count = count/2     
    ;;
    ;;     firstnode = node
    ;;     middlenode = node
    ;;     for i in range(half_count):
    ;;         middlenode = middlenode.left
    ;;
    ;;     newnode.left = bvh_construct(firstnode, half_count)
    ;;     newnode.right = bvh_construct(middlenode, count - half_count)
    ;;     newnode.box = surroundingBox(newnode.left, newnode.right)
    ;;     return newnode
 
    ;; This algorithm is not in place sadly, but we do reuse some of the 
    ;; previously allocated nodes. Making it in place is REALLY hard so we 
    ;; waste some memory when allocating new nodes. 

    mov ebx, [@@node]

    cmp [@@count], 1
    jne @@check_count_2

    ;; Since we only have one object we will directly hang it in the tree,
    ;; so we return the object
    mov eax, [ebx+BvhNode.right]
    jmp @@end

@@check_count_2:
    cmp [@@count], 2
    jne @@divide

    ;; Set the second nodes left to this nodes right. We will use the second 
    ;; node to hold the previous two 
    mov eax, [ebx+BvhNode.left]
    mov ecx, [ebx+BvhNode.right]
    mov [eax+BvhNode.left], ecx

    ;; Don't forget to set the hit function of this Object
    mov [eax+Object.hit_function], offset bvh_hit

    ;; Calculate the surrounding bounding box
    lea ebx, [eax+Object.bounding_box]
    lea edx, [ecx+Object.bounding_box]
    mov ecx, [eax+BvhNode.right]
    lea ecx, [ecx+Object.bounding_box]
    call aabb_surrounding, ebx, ecx, edx

    ;; eax still holds the 2nd node so we can just return
    jmp @@end

@@divide:
    ;; sort the list and divide it up
    call random_int
    xor edx, edx
    mov ecx, 3
    div ecx
    ;; edx contains the modulo of 3, in other words a random number between 0 
    ;; and 2 inclusive. We will use this as a random axis to divide by

    ;; Sort the list by axis
    call bvh_list_sort_by_axis, ebx, [@@count], edx
    mov ebx, eax

    ;; calculate the middle of the list
    mov eax, [@@count]
    shr eax, 1          ;; same as divide by 2
    mov [@@half_count], eax
    
    ;; Save the first node of this list for later
    mov [@@firstnode], ebx

    ;; Grab the middle element of the list
    mov ecx, [@@half_count]
@@find_middle_loop:
    cmp ecx, 0
    je @@found_middle
    
    ;; Jump to the next node
    mov ebx, [ebx+BvhNode.left]
    dec ecx
    jmp @@find_middle_loop

@@found_middle:
    mov [@@middlenode], ebx

    ;; Allocate a new node
    call alloc, size BvhNode
    mov ebx, eax

    call bvh_construct, [@@firstnode], [@@half_count]
    mov [ebx+BvhNode.left], eax

    mov eax, [@@count]
    sub eax, [@@half_count]
    call bvh_construct, [@@middlenode], eax
    mov [ebx+BvhNode.right], eax

    ;; Don't forget to set the hit function of this Object
    mov [ebx+Object.hit_function], offset bvh_hit

    ;; Calculate the surrounding bounding box
    lea eax, [ebx+Object.bounding_box]
    mov ecx, [ebx+BvhNode.left]
    lea ecx, [ecx+Object.bounding_box]
    mov edx, [ebx+BvhNode.right]
    lea edx, [edx+Object.bounding_box]
    call aabb_surrounding, eax, ecx, edx

    mov eax, ebx

@@end:
    ret
endp bvh_construct

proc bvh_hit
    arg @@object:PTR Object, @@ray:PTR Ray, @@t_min:dword, @@t_max:dword,\
        @@hit:PTR Hit
    uses ebx, ecx, edx

    ;; If we don't hit our AABB, we didn't hit any of its subchildren so we can
    ;; return false
    mov ebx, [@@object]
    lea ecx, [ebx+Object.bounding_box]
    call aabb_hit, ecx, [@@ray], [@@t_min], [@@t_max]
    cmp eax, 1
    jne @@end

    ;; Now that we are certain we hit somehwere in this range of the subchildren
    ;; check each child and or the results at the end
    mov ecx, [ebx+BvhNode.left]
    call [ecx+Object.hit_function], ecx, [@@ray], [@@t_min], [@@t_max], [@@hit]
    mov edx, eax

    mov eax, [@@t_max]
    cmp edx, 1
    jne @@check_right
    
    ;; If we hit something, we are going to check whether or not the right
    ;; has an object that is closer. So we set our t_max to the t of our 
    ;; previous hit (is smaller than t_max).
    mov ecx, [@@hit]
    mov eax, [ecx+Hit.t]

@@check_right:
    mov ecx, [ebx+BvhNode.right]
    call [ecx+Object.hit_function], ecx, [@@ray], [@@t_min], eax, [@@hit]
    
    or eax, edx
@@end:
    ret
endp bvh_hit

proc scene_build_bvh
    arg @@scene:PTR Scene
    uses eax, ebx 

    ;; To build the BVH we will choose an axis to divide along, sort the 
    ;; list along that axis, and then split the list in 2 and do the same
    ;; until we only have 1 or 2 items left

    ;; Since this is a recursive process we will use a helper function that will
    ;; do the heavy lifting.
    ;; this function is merely the entry point to the process

    mov ebx, [@@scene]
    lea ebx, [ebx+Scene.head]
    call bvh_list_length, [ebx]
    call bvh_construct, [ebx], eax
    mov [ebx], eax

    ret
endp scene_build_bvh

proc scene_add
    arg @@scene:PTR Scene, @@object:PTR Object
    uses eax, ebx, ecx, edx

    ;; Since we run on a system that already has little memory we are going to
    ;; reuse the BVH nodes as a linked list. So when constructing the scene we 
    ;; just add elements to this "linked list" and then when we are going to 
    ;; start our render we convert it to an actual BVH tree while reusing the
    ;; previously allocated nodes. This will make the conversion from scene to
    ;; BVH more expensive because we have to do operations on O(n) lists instead
    ;; of O(1) vectors but that is a cost we have to make. Writing a memory 
    ;; manager could fix this but the added complexity is simply too much.
    ;;
    ;; So our linked list will exist of: 
    ;; - left: ptr to the next item in the list
    ;; - right: ptr to the object itself in memory
    
    mov ebx, [@@scene]
    mov ecx, [ebx+Scene.head]
    
    ;; We allocate a node for the linked list on the heap
    call alloc, size BvhNode
    mov [eax+BvhNode.left], ecx
    mov [ebx+Scene.head], eax
    mov edx, [@@object]
    mov [eax+BvhNode.right], edx

    ret
endp scene_add

proc scene_hit
    arg @@scene:PTR Scene, @@ray:PTR Ray, @@t_min:dword, @@t_max:dword,\
        @@hit:PTR Hit

    mov eax, [@@scene]
    mov eax, [eax+Scene.head]
    call [eax+Object.hit_function], eax, [@@ray], [@@t_min], [@@t_max], [@@hit]

    ret
endp scene_hit

END