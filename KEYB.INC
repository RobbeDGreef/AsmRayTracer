;-------------------------------------------------------------------
; 32-bit Keyboard functionality.
;-------------------------------------------------------------------

GLOBAL keyboard_install_handler:PROC
GLOBAL keyboard_uninstall_handler:PROC

GLOBAL keyb_keyboard_state:BYTE:128
GLOBAL keyb_raw_scan_code:BYTE
GLOBAL keyb_keys_active:BYTE

;-------------------------------------------------------------------
; Scancodes
;   see: http://www.ee.bgu.ac.il/~microlab/MicroLab/Labs/ScanCodes.htm
;-------------------------------------------------------------------
