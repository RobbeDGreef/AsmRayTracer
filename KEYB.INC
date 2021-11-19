;-------------------------------------------------------------------
; 32-bit Keyboard functionality.
;-------------------------------------------------------------------

GLOBAL __keyb_install_keyboard_handler:PROC
GLOBAL __keyb_uninstall_keyboard_handler:PROC

GLOBAL __keyb_keyboard_state:BYTE:128
GLOBAL __keyb_raw_scan_code:BYTE
GLOBAL __keyb_keys_active:BYTE

;-------------------------------------------------------------------
; Scancodes
;   see: http://www.ee.bgu.ac.il/~microlab/MicroLab/Labs/ScanCodes.htm
;-------------------------------------------------------------------
