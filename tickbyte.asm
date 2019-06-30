;******************************************************************************
;*
;* tickbyte kernel containing
;* - Initialization
;* - Task switcher
;*
;******************************************************************************
.include "tickbytedef.inc"
.include "projectdef.inc"

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
#if !defined(USE_ACCURATE_TICK)
.org	OVF0addr
	rjmp 	TICK_ISR				;timer 0 overflow interrupt vector
#else
.org	OC0Aaddr
	rjmp 	TICK_ISR				;timer 0 output compare match A interrupt vector
#endif ; USE_ACCURATE_TICK

;******************************************************************************
;*
;* tickbyte AVR main
;*
;******************************************************************************
;******************************************************************************
; MAIN
;******************************************************************************
RESET:
#if !defined(USE_ACCURATE_TICK)
;Setup timer 0
	ldi		XH,			1<<CS00		;Clock source = system clock, no prescaler
	out		TCCR0B,		XH

	ldi		XH,			1<<TOIE0	;Enable timer 0 overflow interrupt
	out		TIMSK0,		XH
#else
;Setup timer 0
	;Load high byte
	ldi		XH,			CmpMatchH
	out		OCR0AH,		XH
	;Load low byte
	ldi		XL,			CmpMatchL
	out		OCR0AL,		XL
	
	ldi		XH,			(1<<CS00)|(1<<WGM02)		;Clock source = system clock, no prescaler
	out		TCCR0B,		XH

	ldi		XH,			1<<OCIE0A	;Enable output compare A match interrupt
	out		TIMSK0,		XH
#endif ; USE_ACCURATE_TICK

	;Setup sleep mode
	;For now we'll use the default idle sleep mode, no need to set SMCR
	;ldi		XH,			0x00
	;out		SMCR,		XH

	;Initialize stack pointer
	ldi		XL,			RAMEND - 6
	out		SPL,		XL

	;Initialize program counter of task 1
	ldi		XL,			LOW( TASK1 )
	sts		T1ContAdrL,	XL
	ldi		XH,			HIGH( TASK1 )
	sts		T1ContAdrH,	XH
	;Initialize program counter of task 2
	ldi		XL,			LOW( TASK2 )
	sts		T2ContAdrL,	XL
	ldi		XH,			HIGH( TASK2 )
	sts		T2ContAdrH,	XH
	;Initialize program counter of task 3
	ldi		XL,			LOW( TASK3 )
	sts		T3ContAdrL,	XL
	ldi		XH,			HIGH( TASK3 )
	sts		T3ContAdrH,	XH

	;Idle task currently running
	ldi		CurTask,	Idlcurrent

; If USE_SLEEP_IDLE and USE_TASK_YIELD are both disabled, task blocking can't
; occur unless AVR sleep mode is enabled
#if (defined(USE_SLEEP_IDLE) || (!defined(USE_SLEEP_IDLE) && !defined(USE_TASK_YIELD)))
	;Enable sleep mode
	ldi		XH,			1<<SE		
	out		SMCR,		XH		;Write SE bit in SMCR to logic one
#endif

	;Initialize tasks
	INIT_TASKS

	;Enable interrupts
	sei

IDLE:
	;Reset watchdog timer
	;wdr
#if defined(USE_SLEEP_IDLE)
	sleep
#endif ; USE_SLEEP_IDLE

	rjmp	IDLE


;******************************************************************************
;*
;* tickbyte AVR task switcher
;*
;******************************************************************************
;******************************************************************************
; Task yield. Called from a task to force context switch
;******************************************************************************
#if defined(USE_TASK_YIELD)
TASK_YIELD:
	mov		XH,			CurTask
	or		Ready2run,	XH		;Currently running task no longer ready to run
	cbr		Ready2run,	(1 << Nottickbit)
	;rjmp	TICK_ISR
#endif ; USE_TASK_YIELD
;******************************************************************************
; RTOS tick interrupt
;******************************************************************************
TICK_ISR:							;ISR_TOV0
SAVE_CONTEXT:
	pop		XH
	pop		XL
	;Save context of task currently running: Check which task is running
	cpi		CurTask,	Idlcurrent
	breq	DEC_COUNTERS
	cpi		CurTask,	T1current
	breq	SAVECONT1
	cpi		CurTask,	T2current
	breq	SAVECONT2

SAVECONT3:
	;Save context of task 3
	sts		T3ContAdrH,	XH
	sts		T3ContAdrL,	XL
	rjmp	DEC_COUNTERS

SAVECONT2:
	;Save context of task 2
	sts		T2ContAdrH,	XH
	sts		T2ContAdrL,	XL
	rjmp	DEC_COUNTERS

SAVECONT1:
	;Save context of task 1
	sts		T1ContAdrH,	XH
	sts		T1ContAdrL,	XL
	;rjmp	DEC_COUNTERS

DEC_COUNTERS:
	;Decrement counters
#if defined (USE_TASK_YIELD)
	sbrs	Ready2run,	Nottickbit	;Don't decrement counters on task yield
	rjmp	REST_CONTEXT
#endif ; USE_TASK_YIELD
T1_DEC:
	;Decrement counter 1
	cpi		T1_count,	0
	breq	T2_DEC
	dec		T1_count

T2_DEC:
	;Decrement counter 2
	cpi		T2_count,	0
	breq	T3_DEC
	dec		T2_count

T3_DEC:
	;Decrement counter 3
	cpi		T3_count,	0
	breq	REST_CONTEXT
	dec		T3_count
	;rjmp	REST_CONTEXT	

REST_CONTEXT:
#if defined (USE_TASK_YIELD)
	sbr		Ready2run,	(1 << Nottickbit)
#endif ; USE_TASK_YIELD
	;Check which task to run next, restore context
	;Task switcher based on the model of:
	; - Task 3 highest priority
	; - Task 2 medium priority
	; - Task 1 lowest priority
	;If Ready to run register = 0 (No tasks ready to run, therefore run idle task)
	cpi		T3_count,	0
	breq	RUN_TASK3

	cpi		T2_count,	0
	breq	RUN_TASK2

	cpi		T1_count,	0
	breq	RUN_TASK1

RUN_IDLE:
	;Idle task running
	ldi		CurTask,	Idlcurrent
	ldi		XL,			LOW( IDLE )
	ldi		XH,			HIGH( IDLE )
	rjmp	PUSH_RETI

RUN_TASK3:
	;Task1 running
	ldi		CurTask,	T3current
	lds		XL,			T3ContAdrL
	lds		XH,			T3ContAdrH
	rjmp	PUSH_RETI

RUN_TASK2:
	;Task1 running
	ldi		CurTask,	T2current
	lds		XL,			T2ContAdrL
	lds		XH,			T2ContAdrH
	rjmp	PUSH_RETI

RUN_TASK1:
	;Task1 running
	ldi		CurTask,	T1current
	lds		XL,			T1ContAdrL
	lds		XH,			T1ContAdrH
	;rjmp	PUSH_RETI

PUSH_RETI:
	push	XL
	push	XH
	reti

;***EOF
