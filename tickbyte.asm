;******************************************************************************
;*
;* Tickbyte AVR main
;*
;******************************************************************************

.include "tn4def.inc"
.include "tickbytedef.inc"
.include "interruptvect.asm"
.include "taskswitcher.asm"
.include "usertasks.asm"


.cseg
;******************************************************************************
; MAIN
;******************************************************************************
RESET:
	;Initialize counters. These should not be zero unless maximum start block
	;time is desired for the particular task
	ldi		T1_count,	0x01
	ldi		T2_count,	0x01
	ldi		T3_count,	0x01

;Uncomment this line for ability to setup timer with increased accuracy
;.equ ACCURATE_TICK = 0x01
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
	rcall	init_tasks

	;Enable interrupts
	sei

IDLE:
	;Reset watchdog timer
	;wdr
	sleep							;Enter sleep mode

	rjmp	IDLE

;***EOF
