Init:
	LOADI -1
	OUT HSPG_SEL

	LOADI 0
	OUT HSPG_MIN_POS

	LOADI 100
	OUT HSPG_MAX_POS

	LOADI 1000
	OUT HSPG_ROT_TIME

	LOADI 0
	OUT HSPG_SEL
	
	LOAD JAVA_BIG_INTEGER
	OUT HSPG_ROT_TIME

	JUMP UpdateLoop

JAVA_BIG_INTEGER: DW 10000

NumServos: DW 4

FanIndexArr: ; []
	DW 500

FanPosArr: ; [] -- TODO (use later)
	DW 600

; input = servo-index
ServoIndex: DW 0
TempFanPtr: DW 0

GetFanPos: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	CALL GetFanIndex

	ADD FanPosArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

GetFanIndex: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	LOAD ServoIndex
	ADD FanIndexArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

TempFanSetInput: DW 0
SetFanIndex: ; input = new-fan-i, ServoIndex = servo-index
	STORE TempFanSetInput
	
	LOAD ServoIndex
	ADD FanIndexArr
	STORE TempFanPtr ; addr

	LOAD TempFanSetInput ; ac = val
	ISTORE TempFanPtr ; addr
	
	RETURN

UpdateFan:
	STORE ServoIndex
	OUT HSPG_SEL

	CALL GetFanPos
	OUT HSPG_POS

	LOAD ServoIndex
	IN HSPG_DONE
	OUT LEDs
	JZERO NoIncFan
		CALL GetFanIndex
		ADDI 1 ; fan_idx++
		SUB FanPosCount

		JZERO WrapFan
		JUMP SkipWrapFan
		WrapFan:
			LOADI 0
			JUMP FanIndexDone
		SkipWrapFan:
			ADD FanPosCount
		FanIndexDone:
		CALL SetFanIndex
	NoIncFan:
	
	RETURN

; SetModeArr:
; 	; LOAD ModeArrIndex
; 	; SUB
; 	RETURN
;
; GetModeArr:
; 	RETURN

ModeArrValue: DW &H00
ModeArrIndex: DW &H00

ModeArr0: DW &H00
ModeArr1: DW &H00
ModeArr2: DW &H00
ModeArr3: DW &H00

UpdateLoop:
	LOADI 0
	CALL UpdateFan

	LOADI 1
	CALL UpdateFan

	LOADI 2
	CALL UpdateFan

	LOADI 3
	CALL UpdateFan

	; LOADI 1
	; CALL UpdateFan
	;
	; LOADI 2
	; CALL UpdateFan
	;
	; LOADI 3
	; CALL UpdateFan
	; IN Switches
	; AND SelMask
	;
	; JNEG Sel_1
	; JPOS Sel_1
	; Sel_0:
	; 	LOADI 0
	; 	OUT HSPG_MIN_POS
	;
	; 	LOADI 100
	; 	OUT HSPG_MAX_POS
	;
	; 	LOADI 0
	; 	OUT HSPG_ROT_TIME
	; JUMP After_Sel
	; Sel_1:
	; 	LOADI 0
	; 	OUT HSPG_MIN_POS
	;
	; 	LOADI 15
	; 	OUT HSPG_MAX_POS
	;
	; 	LOADI 1000
	; 	OUT HSPG_ROT_TIME
	; After_Sel:
	; ; ----
	;
	; IN Switches
	; AND PosMask
	;
	; OUT HEX0 ; ?
	; OUT HEX1 ; ?
	;
	; OUT HSPG_POS
	;
	; ; show if servo is done
	; IN HSPG_DONE
	; OUT LEDs

	JUMP UpdateLoop
; =========================
SelMask:      DW &B1000000000
PosMask:      DW &B0111111111
	
; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
; Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

HSPG_SEL:           EQU &H50
HSPG_POS:           EQU &H51
HSPG_MIN_POS:       EQU &H52
HSPG_MAX_POS:       EQU &H53
HSPG_ROT_TIME:      EQU &H54
HSPG_DONE:          EQU &H55

ORG 500 ; FanIndexArr
	DW 0
	DW 0
	DW 0
	DW 0

; ORG 600 ; FanPosArr
; 	DW 0
; 	DW 1

ORG 600 ; FanPosArr
	DW 0
	DW 50
	DW 25
	DW 75
	DW 50
	DW 100
	DW 50
	DW 75
	DW 25
	DW 50

	; DW 0
	; DW 20
	; DW 10
	; DW 30
	; DW 20
	; DW 40
	; DW 30
	; DW 50
	; DW 60
	; DW 50
	; DW 70
	; DW 60
	; DW 80
	; DW 90
	; DW 100
	; DW 90
	; DW 80
	; DW 60
	; DW 70
	; DW 50
	; DW 60
	; DW 50
	; DW 30
	; DW 40
	; DW 20
	; DW 30
	; DW 10
	; DW 20

; FanPosCount: DW 28
FanPosCount: DW 10

; ORG 700 ; SprinklerPosArr
; 	DW 0
; 	DW 0
; 	DW 0
; 	DW 0


; ; old working program -> shows sel for 2
; Init:
; 	LOADI -1
; 	OUT HSPG_SEL
;
; 	LOADI 0
; 	OUT HSPG_MIN_POS
;
; 	LOADI 100
; 	OUT HSPG_MAX_POS
;
; 	LOADI 1000
; 	OUT HSPG_ROT_TIME
;
; 	LOADI 0
; 	OUT HSPG_SEL
;
; Loop: 
; 	IN Switches
; 	AND SelMask
; 	OUT HSPG_SEL
;
; 	IN Switches
; 	AND PosMask
; 	OUT HSPG_POS
;
; 	JUMP Loop
;
; SelMask:      DW &B0000000001
; PosMask:      DW &B1111111110
; 	
; ; IO address constants
; Switches:  EQU 000
; LEDs:      EQU 001
; Timer:     EQU 002
; Hex0:      EQU 004
; Hex1:      EQU 005
;
; HSPG_SEL:           EQU &H50
; HSPG_POS:           EQU &H51
; HSPG_MIN_POS:       EQU &H52
; HSPG_MAX_POS:       EQU &H53
; HSPG_ROT_TIME:      EQU &H54
; HSPG_DONE:          EQU &H55
