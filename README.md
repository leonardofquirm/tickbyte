# tickbyte
## tickbyte real-time kernel
-------------------------------------------------------------------------------
## About
tickbyte (intentionally left lower case to signify small size) is an attempt at
writing one of the worlds smallest real time kernels. The name is derived from
two words: tick, which refers to the system tick; and byte, which is our
(admittedly overambitious) goal of kernel size, 1 byte


## Features for version 0.2
* Project with all 3 tasks already populated with a blockt statement
  - 166 bytes total program memory usage (32.4% for ATtiny4) configured for
    minimum code size
  - 6 bytes RAM usage (18.8% for ATtiny4)
* Typically 3% CPU load consumed by kernel at 1kHz tick rate and 1MHz clock
* Currently only supports ATtiny4/5/9/10


## Usage
* Create a new assembler project with AVRStudio 4.18 or 4.19
* Rename tickbyte_prj_template.asm to your project name
* Configure the following to balance functionality vs code size in
  projectdef.inc:
  - USE_TASK_YIELD
  - USE_ACCURATE_TICK
  - USE_SLEEP_IDLE
* Add initialization code in INIT_TASKS, which is called before kernel is
  started
* In tickbyte.asm, find TASK1, TASK2, and TASK3. Place your highest priority
  code (most time critical) in TASK3, medium priority in TASK2 and lowest
  priority in TASK1.
* Optionally you can add code to the IDLE task for instance resetting watchdog
  timer. Note that no timer exists for IDLE task, hence you can't block in IDLE
  task. IDLE task is not guaranteed to run a complete loop
* To block/delay, load the amount of ticks to delay into the respective task's
  counter, then enter sleep mode. For improved readability, this has been
  included in a macro "blockt". Eg to block for 10 ticks in task2:
  blockt	T2_count,	10			;Wait 10 ticks
* Similarly to block for a variable amount of time you can use "blocktv"
  blockt	T2_count,	varticks	;Wait 10 ticks
  where varticks is the RAM address of variable containing variable declared
* Registers 16 to 20 are reserved for the task switcher, so writing to them may
  cause undesired results. For those interested, refer to tickbytedef.inc
* X register is used by kernel during context switching but can be used by
  tasks, *provided that interrupts are cleared before read/write operations and
  re-enabled again when done*
* Blocking for 1 tick does not allow lower priority tasks to run when
  USE_TASK_YIELD is disabled - it blocks only for 1 tick and is ready to run at
  the next tick interrupt


Dependencies
* Include file for target device e.g. tn4def.inc distributed with AVR Studio
* AVR assembler supporting target MCU


The tickbyte kernel is meant for extremely low memory targets and so needs to
have some functionality removed that is normally included in traditional
kernels. Special care needs to be taken regarding the following:

1. Registers R0 to R31 (or in the case of ATtiny4, R16 to R31) are shared and
so will not be pushed and popped to/from stack during context switching. The
only values saved in memory are the program counter (automatically done by AVR
core during interrupt)

2. The stack is shared by all tasks

3. No formal inter-task communication. Tasks should post messages to each
other by temporarily turning off interrupts during writing to or reading
registers or memory

4. No functions to create and destroy tasks on the fly, all tasks are created
during initialization

5. Maximum of 3 tasks, excluding idle task

6. All tasks differ in priority, with task3 highest priority and task1 lowest
priority

7. When calling a subroutine from a task, do not block from inside the called
subroutine. IE only block in task subroutines themselves

8. Avoid pushing and popping to/from stack. Instead, rather declare variables
directly in RAM

9. As part of an attempt to reduce code size, the idle task runs at startup
instead of Task3

10. During tick interrupt, the status register is not saved on stack,
therefore it's recommended to disable interrupts before executing an operation
that depends on the status register, and enabling interrupts again afterwards.
Also do not block when interrupts are disabled


## Thanks to
* The FreeRTOS team for providing information on how real-time operating
  systems work. Their website contains a wealth of information
  http://www.freertos.org/
* The FemtoOS team for challenging other developers to make even smaller
  operating systems
  http://femtoos.org/
* The Helium OS team. Much inspiration on the task switcher has been drawn from
  their uncomplicated and well commented source code
  http://helium.sourceforge.net/


## Further reading
* ATtiny4/5/9/10 data sheet
  http://www.atmel.com/Images/Atmel-8127-AVR-8-bit-Microcontroller-ATtiny4-ATtiny5-ATtiny9-ATtiny10_Datasheet.pdf
* Once project has been ported to GCC:
  Atmel AVR4027: Tips and Tricks to Optimize Your C Code for 8-bit AVR Microcontrollers
  http://www.atmel.com/Images/doc8453.pdf
  Atmel AT1886: Mixing Assembly and C with AVRGCC 
  http://www.atmel.com/Images/doc42055.pdf
* Only after first implementation of tickbyte, further reading on the topic of
  sharing stack revealed that FreeRTOS already has a similar approach to RAM
  constrained devices, and unsurprisingly, some of the same restrictions
  http://www.freertos.org/co-routine-limitations.html
* How FreeRTOS works. Not the same way tickbyte works, but interesting reading
  for anyone interested in RTOS. Example of implementation on AVR
  http://www.freertos.org/implementation/a00018.html
