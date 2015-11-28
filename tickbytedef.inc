;******************************************************************************
;*
;* Tickbyte AVR definitions
;*
;******************************************************************************

#ifndef _TICKBYTEDEF_INC_
#define _TICKBYTEDEF_INC_

.def	gen_reg			=		r16	;General register
.def	T1_count		=		r17	;Task 1 counter
.def	T2_count		=		r18	;Task 2 counter
.def	T3_count		=		r19	;Task 2 counter
.def	Ready2run		=		r20	;Ready to run register
.def	CurTask			=		r21	;Register indicating currently running task

.equ	T1readybit		=		1	;Task 1 ready to run bit
.equ	T2readybit		=		2	;Task 2 ready to run bit
.equ	T3readybit		=		3	;Task 3 ready to run bit

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

;Macro used for blocking tasks
.MACRO	blockt	;@0:Timer	;@1:Value to be loaded in timer
	;Load new value into counter
	ldi		@0,	@1			;Wait number of ticks specified in @1 arguement
	;Enter sleep mode
	sleep	
ExitMacro:
.ENDMACRO

#endif

;***EOF
