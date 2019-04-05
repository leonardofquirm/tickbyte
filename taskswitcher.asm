;******************************************************************************
;*
;* Tickbyte AVR task switcher
;*
;******************************************************************************

.cseg

;******************************************************************************
; Task yield. Called from a task to force context switch
;******************************************************************************
.ifdef USE_TASK_YIELD
TASK_YIELD:
	mov		gen_reg,	CurTask
	com		gen_reg					;If inverted logic is used for Ready2run, this instruction can be removed
	and		Ready2run,	gen_reg		;Currently running task no longer ready to run
	sbr		Ready2run,	(1 << Nottickbit)
	;rjmp	TIM0_OVF
.endif ; USE_TASK_YIELD
;******************************************************************************
; TIMER 0 overflow interrupt service routine. AKA RTOS tick
;******************************************************************************
TIM0_OVF:							;ISR_TOV0
SaveContext:
	;Save context of task currently running: Check which task is running
	cpi		CurTask,	Idlcurrent
	breq	Dummysaveidl
	cpi		CurTask,	T1current
	breq	Savecont1
	cpi		CurTask,	T2current
	breq	Savecont2

Savecont3:
	;Save context of task 3
	pop		gen_reg
	sts		T3ContAdrH,	gen_reg
	pop		gen_reg
	sts		T3ContAdrL,	gen_reg
	rjmp	DecCounters

Savecont2:
	;Save context of task 2
	pop		gen_reg
	sts		T2ContAdrH,	gen_reg
	pop		gen_reg
	sts		T2ContAdrL,	gen_reg
	rjmp	DecCounters

Savecont1:
	;Save context of task 1
	pop		gen_reg
	sts		T1ContAdrH,	gen_reg
	pop		gen_reg
	sts		T1ContAdrL,	gen_reg
	rjmp	DecCounters

Dummysaveidl:
	;Dummy save context: pop from stack to prevent stack overflow
	pop		gen_reg
	pop		gen_reg

DecCounters:
	;Decrement counters
.ifdef USE_TASK_YIELD
	sbrc	Ready2run,	Nottickbit	;Don't decrement counters on task yield
	rjmp	RestContext
.endif ; USE_TASK_YIELD
T1Dec:
	;Decrement counter 1
	dec		T1_count
	brbs	SREG_Z,		SetT1Bit	;Check if sign bit in status reg is set
ClearT1Bit:
	cbr		Ready2run,	T1rdymask
	rjmp	T2Dec
SetT1bit:
	sbr		Ready2run,	T1rdymask
	inc		T1_count				;Clear counter

T2Dec:
	;Decrement counter 2
	dec		T2_count
	brbs	SREG_Z,		SetT2Bit	;Check if sign bit in status reg is set
ClearT2Bit:
	cbr		Ready2run,	T2rdymask
	rjmp	T3Dec
SetT2bit:
	sbr		Ready2run,	T2rdymask
	inc		T2_count				;Clear counter

T3Dec:
	;Decrement counter 3
	dec		T3_count
	brbs	SREG_Z,		SetT3Bit	;Check if sign bit in status reg is set
ClearT3Bit:
	cbr		Ready2run,	T3rdymask
	rjmp	RestContext
SetT3bit:
	sbr		Ready2run,	T3rdymask
	inc		T3_count				;Clear counter
	;rjmp	RestContext	

RestContext:
.ifdef USE_TASK_YIELD
	cbr		Ready2run,	(1 << Nottickbit)
.endif ; USE_TASK_YIELD
	;Check which task to run next, restore context
	;Task switcher based on the model of:
	; - Task 3 highest priority
	; - Task 2 medium priority
	; - Task 1 lowest priority
	;If Ready to run register = 0 (No tasks ready to run, therefore run idle task)
	sbrc	Ready2run,	T3readybit
	rjmp	RunTask3

	sbrc	Ready2run,	T2readybit
	rjmp	RunTask2

	sbrc	Ready2run,	T1readybit
	rjmp	RunTask1

RunIdle:
	;Idle task running
	ldi		CurTask,	Idlcurrent

	ldi		gen_reg,	LOW( IDLE )
	push	gen_reg
	ldi		gen_reg,	HIGH( IDLE )
	push	gen_reg
	reti

RunTask3:
	;Task1 running
	ldi		CurTask,	T3current

	lds		gen_reg,	T3ContAdrL
	push	gen_reg
	lds		gen_reg,	T3ContAdrH
	push	gen_reg
	reti

RunTask2:
	;Task1 running
	ldi		CurTask,	T2current

	lds		gen_reg,	T2ContAdrL
	push	gen_reg
	lds		gen_reg,	T2ContAdrH
	push	gen_reg
	reti

RunTask1:
	;Task1 running
	ldi		CurTask,	T1current

	lds		gen_reg,	T1ContAdrL
	push	gen_reg
	lds		gen_reg,	T1ContAdrH
	push	gen_reg
	reti

;***EOF
