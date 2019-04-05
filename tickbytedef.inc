;******************************************************************************
;*
;* Tickbyte AVR definitions
;*
;******************************************************************************

#ifndef _TICKBYTEDEF_INC_
#define _TICKBYTEDEF_INC_

;******************************************************************************
; USE_TASK_YIELD
; Commenting this line will reduce code size for doing context switch. Doing
; so, the programmer promises that block time used in higher priority tasks are
; long enough to not starve lower priority tasks of CPU time, since the CPU is
; placed in sleep mode each time a task blocks instead of yielding
;******************************************************************************
;.equ USE_TASK_YIELD = 0x01

;******************************************************************************
; ACCURATE_TICK
; Uncomment this line for ability to set up timer for tick interrupt with a 
; better defined value for more accurate tick interrupt timing, at the expense
; of more program space usage for initialization of timer. Otherwise the timer
; overflow interrupt mechanism is used as tick interrupt
;******************************************************************************
;.equ ACCURATE_TICK = 0x01

;******************************************************************************
; USE_MAX_START_BLOCK_TIME
; Uncommenting this line will reduce code size for initialization of timers,
; but will cause all tasks to block for the maximum possible block time at
; startup
;******************************************************************************
.equ USE_MAX_START_BLOCK_TIME = 0x01


.def	gen_reg			=		r16	;General register
.def	T1_count		=		r17	;Task 1 counter
.def	T2_count		=		r18	;Task 2 counter
.def	T3_count		=		r19	;Task 2 counter
.def	Ready2run		=		r20	;Ready to run register
.def	CurTask			=		r21	;Register indicating currently running task

.equ	T1readybit		=		1	;Task 1 ready to run bit
.equ	T2readybit		=		2	;Task 2 ready to run bit
.equ	T3readybit		=		3	;Task 3 ready to run bit
.equ	Nottickbit		=		7	;Bit indicating manual ISR call

.equ	T1rdymask		=		0b00000010	;Task 1 ready to run mask
.equ	T2rdymask		=		0b00000100	;Task 2 ready to run mask
.equ	T3rdymask		=		0b00001000	;Task 3 ready to run mask

.equ	Idlcurrent		=		0b00000001	;Idle task currently running
.equ	T1current		=		0b00000010	;Task 1 currently running
.equ	T2current		=		0b00000100	;Task 2 currently running
.equ	T3current		=		0b00001000	;Task 3 currently running


;Reserve space in RAM for task context, which consist only of program counter
.dseg
.org	RAMEND
T1ContAdrL:		.byte	1
.org	RAMEND - 1
T1ContAdrH:		.byte	1
.org	RAMEND - 2
T2ContAdrL:		.byte	1
.org	RAMEND - 3
T2ContAdrH:		.byte	1
.org	RAMEND - 4
T3ContAdrL:		.byte	1
.org	RAMEND - 5
T3ContAdrH:		.byte	1

.ifndef USE_TASK_YIELD

;******************************************************************************
; Macro used for blocking tasks, passing constant
; @0: Timer
; @1: Value to be loaded in timer
;******************************************************************************
.MACRO	blockt
	;Load new value into counter
	ldi		@0,	@1			;Wait number of ticks specified in @1 arguement
	sleep
ExitMacro:
.ENDMACRO

;******************************************************************************
; Macro used for blocking tasks, passing variable in RAM instead of constant
; @0: Timer
; @1: RAM addr containing value to be loaded in timer
;******************************************************************************
.MACRO	blocktv
.MESSAGE "Warning: blocking with variable argument with task yielding disabled"
	;Load new value into counter
	lds		@0,	@1			;Wait number of ticks specified in @1 arguement
	sleep
ExitMacro:
.ENDMACRO

.else

;******************************************************************************
; Macro used for blocking tasks, passing constant
; @0: Timer
; @1: Value to be loaded in timer
;******************************************************************************
.MACRO	blockt
	;Load new value into counter
	ldi		@0,	@1			;Wait number of ticks specified in @1 arguement
	cli
	rcall	TASK_YIELD
.ENDMACRO

;******************************************************************************
; Macro used for blocking tasks, passing variable in RAM instead of constant
; @0: Timer
; @1: RAM addr containing value to be loaded in timer
;******************************************************************************
.MACRO	blocktv
	;Load new value into counter
	lds		@0,	@1			;Wait number of ticks specified in @1 arguement
	cli
	rcall	TASK_YIELD
.ENDMACRO

.endif ; USE_TASK_YIELD

#endif

;***EOF
