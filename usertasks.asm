;******************************************************************************
;*
;* Tickbyte AVR tasks
;*
;******************************************************************************

;******************************************************************************
;Place your highest priority code (most time critical) in TASK3, medium
;priority in TASK2 and lowest priority in TASK1
;******************************************************************************

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
	blockt	T2_count,	2		;Wait 2 ticks

	rjmp	TASK2


;******************************************************************************
; TASK3
;******************************************************************************
TASK3:
	blockt	T3_count,	5		;Wait 5 ticks

	rjmp	TASK3

;***EOF
