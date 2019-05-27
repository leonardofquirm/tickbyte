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
	;Initialize counters. These should not be zero unless maximum start block
	;time is desired for the particular task
#if !defined(USE_MAX_START_BLOCK_TIME)
	ldi		T1_count,	0x01
	ldi		T2_count,	0x01
	ldi		T3_count,	0x01
#endif ; USE_MAX_START_BLOCK_TIME

#if !defined(USE_ACCURATE_TICK)
;Setup timer 0
	ldi		gen_reg,	1<<CS00		;Clock source = system clock, no prescaler
	out		TCCR0B,		gen_reg

	ldi		gen_reg,	1<<TOIE0	;Enable timer 0 overflow interrupt
	out		TIMSK0,		gen_reg
	
#else

;Setup timer 0
	;Load high byte
	ldi		gen_reg,	CmpMatchH
	out		OCR0AH,		gen_reg
	;Load low byte
	ldi		gen_reg,	CmpMatchL
	out		OCR0AL,		gen_reg
	
	ldi		gen_reg,	(1<<CS00)|(1<<WGM02)		;Clock source = system clock, no prescaler
	out		TCCR0B,		gen_reg

	ldi		gen_reg,	1<<OCIE0A	;Enable output compare A match interrupt
	out		TIMSK0,		gen_reg
	
#endif ; USE_ACCURATE_TICK

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
	ldi		Ready2run,	~((1<<T1readybit)|(1<<T2readybit)|(1<<T3readybit))

	;Idle task currently running
	ldi		CurTask,	Idlcurrent

; If USE_SLEEP_IDLE and USE_TASK_YIELD are both disabled, task blocking can't
; occur unless AVR sleep mode is enabled
#if (defined(USE_SLEEP_IDLE) || (!defined(USE_SLEEP_IDLE) && !defined(USE_TASK_YIELD)))
	;Enable sleep mode
	ldi		gen_reg,	1<<SE		
	out		SMCR,		gen_reg		;Write SE bit in SMCR to logic one
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
	mov		gen_reg,	CurTask
	or		Ready2run,	gen_reg		;Currently running task no longer ready to run
	cbr		Ready2run,	(1 << Nottickbit)
	;rjmp	TICK_ISR
#endif ; USE_TASK_YIELD
;******************************************************************************
; RTOS tick interrupt
;******************************************************************************
TICK_ISR:							;ISR_TOV0
SAVE_CONTEXT:
	;Save context of task currently running: Check which task is running
	cpi		CurTask,	Idlcurrent
	breq	DUMMY_SAVE_IDL
	cpi		CurTask,	T1current
	breq	SAVECONT1
	cpi		CurTask,	T2current
	breq	SAVECONT2

SAVECONT3:
	;Save context of task 3
	pop		gen_reg
	sts		T3ContAdrH,	gen_reg
	pop		gen_reg
	sts		T3ContAdrL,	gen_reg
	rjmp	DEC_COUNTERS

SAVECONT2:
	;Save context of task 2
	pop		gen_reg
	sts		T2ContAdrH,	gen_reg
	pop		gen_reg
	sts		T2ContAdrL,	gen_reg
	rjmp	DEC_COUNTERS

SAVECONT1:
	;Save context of task 1
	pop		gen_reg
	sts		T1ContAdrH,	gen_reg
	pop		gen_reg
	sts		T1ContAdrL,	gen_reg
	rjmp	DEC_COUNTERS

DUMMY_SAVE_IDL:
	;Dummy save context: pop from stack to prevent stack overflow
	pop		gen_reg
	pop		gen_reg

DEC_COUNTERS:
	;Decrement counters
#if defined (USE_TASK_YIELD)
	sbrs	Ready2run,	Nottickbit	;Don't decrement counters on task yield
	rjmp	REST_CONTEXT
#endif ; USE_TASK_YIELD
T1_DEC:
	;Decrement counter 1
	dec		T1_count
	brbs	SREG_Z,		SET_T1_BIT	;Check if sign bit in status reg is set
CLR_T1_BIT:
	sbr		Ready2run,	T1rdymask
	rjmp	T2_DEC
SET_T1_BIT:
	cbr		Ready2run,	T1rdymask
	inc		T1_count				;Clear counter

T2_DEC:
	;Decrement counter 2
	dec		T2_count
	brbs	SREG_Z,		SET_T2_BIT	;Check if sign bit in status reg is set
CLR_T2_BIT:
	sbr		Ready2run,	T2rdymask
	rjmp	T3_DEC
SET_T2_BIT:
	cbr		Ready2run,	T2rdymask
	inc		T2_count				;Clear counter

T3_DEC:
	;Decrement counter 3
	dec		T3_count
	brbs	SREG_Z,		SET_T3_BIT	;Check if sign bit in status reg is set
CLR_T3_BIT:
	sbr		Ready2run,	T3rdymask
	rjmp	REST_CONTEXT
SET_T3_BIT:
	cbr		Ready2run,	T3rdymask
	inc		T3_count				;Clear counter
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
	sbrs	Ready2run,	T3readybit
	rjmp	RUN_TASK3

	sbrs	Ready2run,	T2readybit
	rjmp	RUN_TASK2

	sbrs	Ready2run,	T1readybit
	rjmp	RUN_TASK1

RUN_IDLE:
	;Idle task running
	ldi		CurTask,	Idlcurrent

	ldi		gen_reg,	LOW( IDLE )
	push	gen_reg
	ldi		gen_reg,	HIGH( IDLE )
	push	gen_reg
	reti

RUN_TASK3:
	;Task1 running
	ldi		CurTask,	T3current

	lds		gen_reg,	T3ContAdrL
	push	gen_reg
	lds		gen_reg,	T3ContAdrH
	push	gen_reg
	reti

RUN_TASK2:
	;Task1 running
	ldi		CurTask,	T2current

	lds		gen_reg,	T2ContAdrL
	push	gen_reg
	lds		gen_reg,	T2ContAdrH
	push	gen_reg
	reti

RUN_TASK1:
	;Task1 running
	ldi		CurTask,	T1current

	lds		gen_reg,	T1ContAdrL
	push	gen_reg
	lds		gen_reg,	T1ContAdrH
	push	gen_reg
	reti

;***EOF
