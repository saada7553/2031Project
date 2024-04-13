Init:
	LOADI -1
	OUT HSPG_SEL

	LOADI 0
	OUT HSPG_MIN_POS

	LOADI 1
	OUT HSPG_MAX_POS

	LOADI 1000
	OUT HSPG_ROT_TIME

	LOADI 0
	OUT HSPG_SEL

Loop: 
	IN Switches
	AND SelMask
	OUT HSPG_SEL

	IN Switches
	AND PosMask
	OUT HSPG_POS

	JUMP Loop

SelMask:      DW &B1100000000
PosMask:      DW &B0011111111
	
; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

HSPG_SEL:           EQU &H50
HSPG_POS:           EQU &H51
HSPG_MIN_POS:       EQU &H52
HSPG_MAX_POS:       EQU &H53
HSPG_ROT_TIME:      EQU &H54
HSPG_DONE:          EQU &H55
