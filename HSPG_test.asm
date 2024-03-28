; An empty ASM program ...

Here:
	IN Switches
	OUT LEDs
	OUT HSPG
	JUMP Here
	
; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
HSPG:      EQU &H50
