; An empty ASM program ...

Here:
	; IN Switches
	; OUT LEDs
	; OUT HSPG
	LOADI 0
	OUT HSPG_SEL

	LOADI 100
	OUT HSPG_POS

	JUMP Here
	
; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
HSPG_SEL:      EQU &H50
HSPG_POS:      EQU &H51
HSPG_MIN:      EQU &H52
HSPG_MAX:      EQU &H53
HSPG_SPD:      EQU &H54
