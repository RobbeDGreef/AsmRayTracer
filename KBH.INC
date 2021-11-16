GLOBAL install_keyboard_handler:PROC            ;; void install_keyboard_handler()
GLOBAL uninstall_keyboard_handler:PROC          ;; void uninstall_keyboard_handler()

GLOBAL __keyb_keyboardState:BYTE:128
GLOBAL __keyb_rawScanCode:BYTE
GLOBAL __keyb_keysActive:BYTE
