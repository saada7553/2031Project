Init:
	; init --
	LOADI -1
	OUT HSPG_SEL

	LOADI 0
	OUT HSPG_MIN_POS

	LOADI 100
	OUT HSPG_MAX_POS

	; each

	LOADI 0
	OUT HSPG_SEL

	LOAD Manual_Spd_0
	OUT HSPG_ROT_TIME

	LOADI 1
	OUT HSPG_SEL

	LOAD Manual_Spd_1
	OUT HSPG_ROT_TIME

	LOADI 2
	OUT HSPG_SEL

	LOAD Manual_Spd_2
	OUT HSPG_ROT_TIME

	LOADI 3
	OUT HSPG_SEL

	LOAD Manual_Spd_3
	OUT HSPG_ROT_TIME
	; --

	LOADI 0
	OUT HSPG_SEL
	;
	; LOADI 500
	; OUT HSPG_ROT_TIME
	
	; LOAD JAVA_BIG_INTEGER
	; OUT HSPG_ROT_TIME

	JUMP UpdateLoop

; JAVA_BIG_INTEGER: DW 10000

NumServos: DW 4

FanIndexArr: ; []
	DW 500
FanWaitTickArr: ; []
	DW 520
ModeArr: ; []
	DW 540

ManualSpeedArr: ; []
	DW 560
NonManualSpeedArr: ; []
	DW 570

MinRangeArr: ; []
	DW 580
MaxRangeArr: ; []
	DW 590

FanWaitTicksMax: DW 100

FanPosArr: ; [FanPosCount]
	DW 600

FanSpeedArr: ; [FanPosCount]
	DW 700

; input = servo-index
ServoIndex: DW 0
TempFanPtr: DW 0
TempFanSetInput: DW 0

GetFanPos: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	CALL GetFanIndex

	ADD FanPosArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

GetFanSpeed: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	CALL GetFanIndex

	ADD FanSpeedArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

GetManualSpeed: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	CALL GetSpeedIndex

	ADD ManualSpeedArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

GetNonManualSpeed: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	CALL GetSpeedIndex

	ADD NonManualSpeedArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

GetMinRange: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	CALL GetRangeIndex

	ADD MinRangeArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

GetMaxRange: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	CALL GetRangeIndex

	ADD MaxRangeArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

GetFanIndex: ; ServoIndex = servo-i: return --> FanIndexArr[servo-i]
	LOAD ServoIndex
	ADD FanIndexArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

SetFanIndex: ; input = new-fan-i, ServoIndex = servo-index
	STORE TempFanSetInput
	
	LOAD ServoIndex
	ADD FanIndexArr
	STORE TempFanPtr ; addr

	LOAD TempFanSetInput ; ac = val
	ISTORE TempFanPtr ; addr
	
	RETURN

GetFanWaitTicks: ; ServoIndex = servo-i: return --> FanWaitTickArr[servo-i]
	LOAD ServoIndex
	ADD FanWaitTickArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

SetFanWaitTicks: ; input = new_fan_ticks, ServoIndex = servo-index
	STORE TempFanSetInput
	
	LOAD ServoIndex
	ADD FanWaitTickArr
	STORE TempFanPtr ; addr

	LOAD TempFanSetInput ; ac = val
	ISTORE TempFanPtr ; addr
	
	RETURN

GetMode: ; ServoIndex = servo-i: return --> FanWaitTickArr[servo-i]
	LOAD ServoIndex
	ADD ModeArr
	STORE TempFanPtr
	ILOAD TempFanPtr
	
	RETURN

SetMode: ; input = new_fan_ticks, ServoIndex = servo-index
	STORE TempFanSetInput
	
	LOAD ServoIndex
	ADD ModeArr
	STORE TempFanPtr ; addr

	LOAD TempFanSetInput ; ac = val
	ISTORE TempFanPtr ; addr
	
	RETURN

UpdateServo:
	STORE ServoIndex
	OUT HSPG_SEL
	
	CALL GetMode
	JZERO Update_TL_Manual ; mode == 0 --> manual
	JUMP Update_TL_Fan     ; mode != 0 --> fan
	Update_TL_Manual:
		CALL UpdateManual
		JUMP Update_TL_Done
	Update_TL_Fan:
		CALL UpdateFan
		JUMP Update_TL_Done
	Update_TL_Done:

	RETURN

UpdateManual:
	LOAD ServoIndex
	OUT HSPG_SEL

	LOADI 0
	OUT HSPG_MIN_POS

	LOADI 127
	OUT HSPG_MAX_POS

	CALL IsCurrentSelected
	JZERO ManualNotSelected
		LOAD SwitchVal
		AND Mask_Pos
		OUT HSPG_POS
		OUT LEDs
	ManualNotSelected:
	
	RETURN

UpdateFan: ; ServoIndex = servo-i
	LOAD ServoIndex
	OUT HSPG_SEL

	; CALL GetFanSpeed
	; OUT HSPG_ROT_TIME

	CALL GetFanPos
	OUT HSPG_POS
	OUT LEDs

	LOAD ServoIndex 
	OUT HSPG_SEL

	IN HSPG_DONE
	; LOAD SwitchVal ; toby

	; OUT LEDs
	JZERO NoIncFan

		; CALL GetFanWaitTicks
		; ADDI 1
		; SUB FanWaitTicksMax
		;
		; JZERO Sad
		; JUMP Happy
		; Sad:
		; JUMP 
		; Happy:
		;
		; Done:

		; CALL SetFanWaitTicks
		; ADDI 1
		; SUB FanWaitTicksMax
		; ADDI
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

GetModeBit:
	LOAD SwitchVal
	AND Mask_FanMode

	RETURN

DoConfigFan: ; i in ServoIndex
	LOAD ServoIndex
	OUT HSPG_SEL

	CALL GetNonManualSpeed
	OUT HSPG_ROT_TIME

	CALL GetMinRange
	OUT HSPG_MIN_POS

	CALL GetMaxRange
	OUT HSPG_MAX_POS

	RETURN

DoConfigManual: ; i in ServoIndex
	LOAD ServoIndex
	OUT HSPG_SEL

	CALL GetManualSpeed
	OUT HSPG_ROT_TIME

	RETURN

UpdateConfigMode:
	CALL IsCommit
	JZERO NoConfigCommit
		CALL GetSel
		STORE ServoIndex

		CALL GetModeBit
		CALL SetMode

		CALL GetModeBit
		JZERO ConfigManualMode
			CALL DoConfigFan
			
			JUMP NoConfigCommit
		ConfigManualMode:
			CALL DoConfigManual
			
			JUMP NoConfigCommit

		; CALL GetModeBit - TOBYY
	NoConfigCommit:
	RETURN

Mask_Config: DW &B1000000000
Mask_ConfigCommit: DW &B0001000000
Mask_Sel: DW &B0110000000
Mask_Pos: DW &B0001111111
Mask_FanMode: DW &B0000000001
Mask_Speed: DW &B0000000110
Mask_Range: DW &B0000011000

Manual_Spd_0: DW 0
Manual_Spd_1: DW 500
Manual_Spd_2: DW 1000
Manual_Spd_3: DW 2000

IsConfigMode:
	LOAD SwitchVal
	AND Mask_Config

	RETURN

GetSpeedIndex:
	LOAD SwitchVal
	AND Mask_Speed
	SHIFT -1

	RETURN

GetRangeIndex:
	LOAD SwitchVal
	AND Mask_Range
	SHIFT -3

	RETURN

GetSel:
	LOAD SwitchVal
	AND Mask_Sel
	SHIFT -7

	RETURN

IsCurrentSelected:
	CALL GetSel
	SUB ServoIndex

	JZERO ItIsSelected
		LOADI 0
		RETURN
	ItIsSelected:
		LOADI 1
		RETURN

IsCommit:
	LOAD SwitchVal
	AND Mask_ConfigCommit

	JZERO DoNotCommit
		LOADI 1
		RETURN
	DoNotCommit:
		LOADI 0
		RETURN

GetManualInputPos:
	LOAD SwitchVal
	AND Mask_Sel
	SHIFT -7

	RETURN

SwitchVal: DW 0
UpdateLoop:
	IN SWITCHES
	STORE SwitchVal

	CALL IsConfigMode

	JNEG Update_LP_Config
	JPOS Update_LP_Config
	JUMP Update_LP_Update
	Update_LP_Config:

		CALL UpdateConfigMode

		JUMP Update_LP_Done
	Update_LP_Update:

		LOADI 0
		CALL UpdateServo

		LOADI 1
		CALL UpdateServo

		LOADI 2
		CALL UpdateServo

		LOADI 3
		CALL UpdateServo

		JUMP Update_LP_Done
	Update_LP_Done:

	JUMP UpdateLoop
; =========================
	
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

ORG 500 ; FanIndexArr
	DW 0
	DW 0
	DW 0
	DW 0

ORG 520 ; FanWaitTickArr
	DW 0
	DW 0
	DW 0
	DW 0

ORG 540 ; ModeArr
	DW 0
	DW 0
	DW 0
	DW 0

ORG 560 ; ManualSpeedArr
	DW 0
	DW 500
	DW 1000
	DW 2000

ORG 570 ; NonManualSpeedArr
	DW 500
	DW 1000
	DW 1500
	DW 2000

ORG 580 ; MinRangeArr
	DW 0
	DW 0
	DW -100
	DW -50

ORG 590 ; MaxRangeArr
	DW 100
	DW 200
	DW 100
	DW 150

; ORG 600 ; FanPosArr
; 	DW 0
; 	DW 1

FanPosCount: DW 2
ORG 600 ; FanPosArr
	DW 0
	DW 100



	; DW 0
	; DW 25
	; DW 50
	; DW 75
	; DW 100
	; DW 75
	; DW 50
	; DW 25

	; DW 0
	; DW 50
	; DW 25
	; DW 75
	; DW 50
	; DW 100
	; DW 50
	; DW 75
	; DW 25
	; DW 50

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


; ORG 700 ; FanSpeedArr
; 	DW 3000
; 	DW 2500
; 	DW 2000
; 	DW 1500
; 	DW 1500
; 	DW 2000
; 	DW 2500
; 	DW 3000
