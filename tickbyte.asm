;******************************************************************************
;*
;* tickbyte kernel containing
;* - Initialization
;* - Task switcher
;*
;******************************************************************************
.include "tickbytedef.inc"

.cseg

;******************************************************************************
;*
;* tickbyte AVR interrupt vectors
;*
;******************************************************************************
;******************************************************************************
; Interrupt vectors
;******************************************************************************
.org	0X0000
	rjmp	RESET					;the reset vector: jump to "RESET"

.org	OVF0addr
	rjmp 	TIM0_OVF				;timer 0 overflow interrupt vector


;******************************************************************************
;*
;* tickbyte AVR main
;*
;******************************************************************************
;******************************************************************************
; MAIN
;******************************************************************************
RESET:
	;Initialize counters. These should not be zero unless maximum start block
	;time is desired for the particular task
.ifndef USE_MAX_START_BLOCK_TIME
	ldi		T1_count,	0x01
	ldi		T2_count,	0x01
	ldi		T3_count,	0x01
.endif ; USE_MAX_START_BLOCK_TIME

.ifndef ACCURATE_TICK
;Setup timer 0
	ldi		gen_reg,	1<<CS00		;Clock source = system clock, no prescaler
	out		TCCR0B,		gen_reg

	ldi		gen_reg,	1<<TOV0		;Clear pending interrupt
	out		TIFR0,		gen_reg

	ldi		gen_reg,	1<<TOIE0	;Enable timer 0 overflow interrupt
	out		TIMSK0,		gen_reg
	
.else

;Setup timer 0
	;For 1kHz tick rate at 8MHz div 8 clock, OCR0A must be loaded with 499
	;Load high byte of 499
	ldi		gen_reg,	0x01
	out		OCR0AH,		gen_reg
	;Load low byte of 499
	ldi		gen_reg,	0xF3
	out		OCR0AL,		gen_reg
	
	ldi		gen_reg,	1<<CS00		;Clock source = system clock, no prescaler
	out		TCCR0B,		gen_reg
	
	ldi		gen_reg,	1<<OCF0A	;Clear pending interrupt
	out		TIFR0,		gen_reg

	ldi		gen_reg,	1<<OCIE0A	;Enable output compare A match interrupt
	out		TIMSK0,		gen_reg
	
.endif

	;Setup sleep mode
	;For now we'll use the default idle sleep mode, no need to set SMCR
	;ldi		gen_reg,	0x00
	;out		SMCR,		gen_reg

	;Initialize stack pointer
	ldi		gen_reg,	RAMEND - 6
	out		SPL,		gen_reg

	;Initialize program counter of task 1
	ldi		gen_reg,	LOW( TASK1 )
	sts		T1ContAdrL,	gen_reg
	ldi		gen_reg,	HIGH( TASK1 )
	sts		T1ContAdrH,	gen_reg
	;Initialize program counter of task 2
	ldi		gen_reg,	LOW( TASK2 )
	sts		T2ContAdrL,	gen_reg
	ldi		gen_reg,	HIGH( TASK2 )
	sts		T2ContAdrH,	gen_reg
	;Initialize program counter of task 3
	ldi		gen_reg,	LOW( TASK3 )
	sts		T3ContAdrL,	gen_reg
	ldi		gen_reg,	HIGH( TASK3 )
	sts		T3ContAdrH,	gen_reg

	;All tasks ready to run
	ldi		Ready2run,	0b00001110

	;Idle task currently running
	ldi		CurTask,	Idlcurrent

	;Enable sleep mode
	ldi		gen_reg,	1<<SE		
	out		SMCR,		gen_reg		;Write SE bit in SMCR to logic one

	;Initialize tasks
	rcall	INIT_TASKS

	;Enable interrupts
	sei

IDLE:
	;Reset watchdog timer
	;wdr
	sleep							;Enter sleep mode

	rjmp	IDLE


;******************************************************************************
;*
;* tickbyte AVR task switcher
;*
;******************************************************************************
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
