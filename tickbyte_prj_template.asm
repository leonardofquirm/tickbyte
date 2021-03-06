;******************************************************************************
; tickbyte project template
;
; Place your highest priority code (most time critical) in TASK3, medium
; priority in TASK2 and lowest priority in TASK1
;******************************************************************************

.include "tickbytedef.inc"
.include "projectdef.inc"
.include "tickbyte.asm"


;******************************************************************************
; Global variables
;******************************************************************************
.dseg
.org		SRAM_START
t3blocktime:	.byte		1
.org		SRAM_START+1
t2blocktime:	.byte		1

.cseg

;******************************************************************************
; TASK1
;******************************************************************************
TASK1:
	blockt	T1_count,	3		;Wait 3 ticks

	rjmp	TASK1


;******************************************************************************
; TASK2
;******************************************************************************
TASK2:
	blocktv	T2_count,	t2blocktime		;Wait 2 ticks

	rjmp	TASK2


;******************************************************************************
; TASK3
;******************************************************************************
TASK3:
	blocktv	T3_count,	t3blocktime		;Wait 5 ticks

	rjmp	TASK3

;***EOF
