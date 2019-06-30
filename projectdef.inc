;******************************************************************************
;*
;* Project specific definitions for project running on tickbyte
;*
;******************************************************************************

#ifndef _PROJECTDEF_INC_
#define _PROJECTDEF_INC_

;******************************************************************************
; Specify AVR model include file here
;******************************************************************************
.include "tn4def.inc"

;******************************************************************************
; USE_TASK_YIELD
; Commenting this line will reduce code size for doing context switch. Doing
; so, the programmer promises that block time used in higher priority tasks are
; long enough to not starve lower priority tasks of CPU time, since the CPU is
; placed in sleep mode each time a task blocks instead of yielding
;******************************************************************************
;#define USE_TASK_YIELD 0x01

;******************************************************************************
; USE_ACCURATE_TICK
; Uncomment this line for ability to set up timer for tick interrupt with a 
; better defined value for more accurate tick interrupt timing, at the expense
; of more program space usage for initialization of timer. Otherwise the timer
; overflow interrupt mechanism is used as tick interrupt
;******************************************************************************
;#define USE_ACCURATE_TICK 0x01

;******************************************************************************
; USE_MAX_START_BLOCK_TIME
; Uncommenting this line will reduce code size for initialization of timers,
; but will cause all tasks to block for the maximum possible block time at
; startup
;******************************************************************************
#define USE_MAX_START_BLOCK_TIME 0x01

;******************************************************************************
; USE_SLEEP_IDLE
; Commenting this line will reduce code size by removing need for sleep when
; idle, but will likely result in increased power consumption
;******************************************************************************
;#define USE_SLEEP_IDLE 0x01

.def	gen_reg		=		r21	;General register

;******************************************************************************
; INIT_TASKS: Task initialization called at startup
; Place initialization code here, e.g. I/O port data direction
;******************************************************************************
.MACRO INIT_TASKS
	ldi		gen_reg,	2
	sts		t2blocktime,	gen_reg
	ldi		gen_reg,	5
	sts		t3blocktime,	gen_reg
.ENDMACRO

#endif

;***EOF
