;=============================================================================
; 32-bit Assembler Mouse library.
; (Significantly modified by Robbe De Greef)
;
; For use under DMPI 0.9 protected mode.
;
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
; Copyright (c) 2015, Tim Bruylants <tim.bruylants@gmail.com>
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;    this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from this
;    software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.
;
;=============================================================================

IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "gui/mouse.inc"
include "utils.inc"

CODESEG

;; Checks whether or not the mouse driver is loaded in dos.
;; Returns eax = 1 if it is, 0 otherwise
proc mouse_present
    mov     eax, 0
    int     33h
    and     eax, 1
    ret
endp mouse_present

;; Resets the mouse driver
proc mouse_reset
    uses eax
    mov eax, 0
    int 33h
    ret
endp mouse_reset

;; Internal mouse handler that is given to dos. 
proc mouse_internal_handler
    push    ds
    push    es
    push    ax

    mov     ax, [word cs:theDS]
    mov     ds, ax
    mov     es, ax

    pop     ax

    ;; We divide the mouse height by 2 when setting it originally. We do this
    ;; because for some reason dos' mouse moves left and right twice as fast as
    ;; up and down. So by multiplying by 2 we speed the y axis up by 2
    shl     dx, 1 ; * 2
    call    [custom_mouse_handler]
    
    pop     es
    pop     ds
    
    retf

    ;; Internal variable to keep track of DS
    ;; I don't fully understand why it has to be saved in the code segment but
    ;; it doesn't work otherwise so we'll just leave it here
    theDS   dw  0
endp mouse_internal_handler

;; Installs the mouse handler
proc mouse_install
    arg @@custom_handler:dword, @@width:dword, @@height:dword
    uses eax, ecx, edx, es

    call mouse_present
    cmp eax, 1
    jne @@no_mouse

    mov eax, [@@custom_handler]
    mov [custom_mouse_handler], eax

    push ds
    mov ax, cs
    mov ds, ax
    ASSUME  ds:_TEXT
    mov [word theDS], ax
    ASSUME  ds:FLAT
    pop ds

    mov eax, 0ch    ;; Install user defined mouse handler
    mov ecx, 255    ;; event mask: mouse movement, left released, right released
    push cs
    pop es
    mov edx, offset mouse_internal_handler
    int 33h

    ;; Define the window size

    mov ax, 7h
    mov cx, 0
    mov edx, [@@width]
    sub edx, 8
    int 33h
    
    mov ax, 8h
    mov cx, 0
    mov edx, [@@height]
    ;; We divide the height by 2 because dos's mouse y is twice as slow as 
    ;; its mouse x. In the mouse handler we will multiply the value by 2 again
    ;; to get the desired uniform mouse speed
    shr edx, 1 ;; / 2
    sub edx, 8
    int 33h

@@no_mouse:
    ret
endp mouse_install

;; Uninstalls the mouse handler
proc mouse_uninstall
    uses eax, ecx, edx

    ;; Reset the user defined mouse handler to 0
    mov eax, 0ch
    mov ecx, 0
    mov edx, 0
    int 33h
    call mouse_reset

    ret
endp mouse_uninstall

DATASEG
    custom_mouse_handler    dd 0

END

