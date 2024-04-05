Init:
	; LOADI 1
	; OUT HSPG_SEL
	;
	; LOADI 100
	; OUT HSPG_MIN_POS
	;
	; LOADI 200
	; OUT HSPG_MAX_POS
	;
	; LOADI 1000
	; OUT HSPG_ROT_TIME
	; -----

Repeat:
	IN Switches
	AND SelMask

	JNEG Sel_1
	JPOS Sel_1
	Sel_0:
		LOADI 0
		OUT HSPG_MIN_POS

		LOADI 100
		OUT HSPG_MAX_POS

		LOADI 0
		OUT HSPG_ROT_TIME
	JUMP After_Sel
	Sel_1:
		LOADI 0
		OUT HSPG_MIN_POS

		LOADI 15
		OUT HSPG_MAX_POS

		LOADI 1000
		OUT HSPG_ROT_TIME
	After_Sel:
	; ----

	IN Switches
	AND PosMask

	OUT LEDs

	OUT HEX0 ; ?
	OUT HEX1 ; ?

	OUT HSPG_POS

	JUMP Repeat
; =========================
SelMask:      DW &B1000000000
PosMask:      DW &B0111111111
	
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


;TODO: Here:
; 	; IN Switches
; 	; OUT LEDs
; 	; OUT HSPG
;
; 	; Set some initial conditions for all 
; 	LOADI -1   ; select all
; 	OUT HSPG_SEL
; 	LOADI -90  ; our min angle is -90 degrees
; 	OUT HSPG_MIN_POS
; 	LOADI 90   ; our max angle is 90 degrees
; 	OUT HSPG_MAX_POS
; 	LOADI 1000 ; 1000ms = 1s, from -90 to 90 degrees
; 	OUT HSPG_ROT_TIME
; 	LOADI 45   ; target angle = 45 degrees
; 	OUT HSPG_POS
;
; 	; Set just the first servo 
; 	; to point the opposite direction
; 	LOADI 0   ; select first
; 	OUT HSPG_SEL
; 	LOADI -45 ; reverse target angle
; 	OUT HSPG_POS
;
;
; 	; ...
;
; HSPG_SEL:           EQU &H50
; HSPG_POS:           EQU &H51
; HSPG_MIN_POS:       EQU &H52
; HSPG_MAX_POS:       EQU &H53
; HSPG_ROT_TIME:      EQU &H54
