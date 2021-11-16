IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

include "kbh.inc"

CODESEG
proc install_keyboard_handler ;; might wanna add ebp and esp
    uses eax, ebx, ecx, edx, edi, esi



    mov ecx, (128 / 2) + 1
    mov edi, offset __keyb_keyboardState
    xor eax, eax
    rep stosw ;; we fill the keyboard state with 0

    ;; saving old handler data
    push es
    mov eax, 3509h ; get current interrupt handler 09h
    int 21h
    mov [originalKeyboardHandlerS], es
    mov [originalKeyboardHandlerO], ebx
    pop es

    push ds
    mov ax, cs
    mov ds, ax
    mov edx, offset keyboardHandler 
    mov eax, 2509h
    int 21h
    pop ds

    ret
endp install_keyboard_handler

proc uninstall_keyboard_handler
    uses eax, edx, ds

    mov edx, [originalKeyboardHandlerO]
    mov ds, [originalKeyboardHandlerS]
    mov eax, 2509h
    int 21h

    ret
endp uninstall_keyboard_handler

proc keyboardHandler
    uses eax, ebx, esi, ds

    KEY_BUFFER EQU 60h
    KEY_CONTROL EQU 61h
    PIC_PORT EQU 20h

    mov ax, _DATA 
    mov ds, ax

    in al, KEY_BUFFER ;; store data from buffer in al
    mov bl, al    ;; store for later user
    mov [__keyb_rawScanCode], al ;;store key
    in al, KEY_CONTROL 
    or al, 82h
    out KEY_CONTROL, al
    and al, 7fh 
    out KEY_CONTROL, al
    mov al, 20h ;;reset command
    out PIC_PORT, al ;re-enable interrupt

    ; process the retrieved scan code and update __keyboardState and __keysActive
	; scan codes of 128 or larger are key release codes
    mov al, bl ;; put scancode back in al
    shl ax, 1 ; in ah -> bit 7 is now bit 0
    not ah 
    and ah, 1 ; ah -> 0 if released, 1 if pressed
    shr al, 1 ; al contains actual scan code
    xor ebx, ebx
    mov bl, al ; save scan code in bl
    lea esi, [__keyb_keyboardState + ebx] ;;load adress corresponding to the key
    mov al, [esi]
    ; al = tracked state (0 or 1) of pressed key (the value in memory)
	; ah = physical state (0 or 1) of pressed key
    neg al 
    add al, ah 
    add [__keyb_keysActive], al ;; update active keys counter
    mov al, ah
    mov [esi], al ; update tracked state

    iretd
endp keyboardHandler

DATASEG

    originalKeyboardHandlerS	dw ?			; SELECTOR of original keyboard handler
    originalKeyboardHandlerO	dd ?			; OFFSET of original keyboard handler

    __keyb_keyboardState		db 128 dup(?)	; state for all 128 keys
    __keyb_rawScanCode			db ?			; scan code of last pressed key
    __keyb_keysActive			db ?			; number of actively pressed keys

END