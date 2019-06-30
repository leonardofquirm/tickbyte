;******************************************************************************
;*
;* Tickbyte AVR definitions
;*
;******************************************************************************

#ifndef _TICKBYTEDEF_INC_
#define _TICKBYTEDEF_INC_

;******************************************************************************
; Make sure file included here itself includes AVR model include file
;******************************************************************************
.include "projectdef.inc"

;******************************************************************************
; Set output compare match register when USE_ACCURATE_TICK is enabled
; TickRate = CPU_FREQ / (CmpMatch - 1). Default is to set tick rate at 1kHz
;******************************************************************************
.equ	CmpMatchH		=		0x03
.equ	CmpMatchL		=		0xE7


.def	T1_count		=		r16	;Task 1 counter
.def	T2_count		=		r17	;Task 2 counter
.def	T3_count		=		r18	;Task 2 counter
.def	CurTask			=		r19	;Register indicating currently running task

.equ	Idlebit			=		0	;Idle bit in ready to run
.equ	T1readybit		=		1	;Task 1 ready to run bit
.equ	T2readybit		=		2	;Task 2 ready to run bit
.equ	T3readybit		=		3	;Task 3 ready to run bit
.equ	Nottickbit		=		7	;Bit indicating manual ISR call

.equ	Idlcurrent		=		(1<<Idlebit)	;Idle task currently running
.equ	T1current		=		(1<<T1readybit)	;Task 1 currently running
.equ	T2current		=		(1<<T2readybit)	;Task 2 currently running
.equ	T3current		=		(1<<T3readybit)	;Task 3 currently running


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

#if !defined(USE_TASK_YIELD)

;******************************************************************************
; Macro used for blocking tasks, passing constant
; @0: Timer
; @1: Value to be loaded in timer
;******************************************************************************
.MACRO	blockt
	;Load new value into counter
	ldi		@0,	@1			;Wait number of ticks specified in @1 arguement
	sleep
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
.ENDMACRO

#else

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

#endif ; USE_TASK_YIELD

#endif

;***EOF
