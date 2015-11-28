# tickbyte
tickbyte real-time kernel
-------------------------------------------------------------------------------
About
tickbyte (intentionally left lower case to signify small size) is an attempt at
writing one of the worlds smallest real time kernels. The name is derived from
two words: tick, which refers to the system tick; and byte, which is our
(admittedly overambitious) goal of kernel size, 1 byte


Features for version 0.1
* Project with all 3 tasks already populated with a blocking statement
  - 224 bytes program memory usage (43.8% for ATiny4)
  - 6 bytes RAM usage (18.8% for ATtiny4)
* Typically 3% CPU load consumed by kernel at 1kHz tick rate
* Currently only supports ATtiny4/5/9/10


Usage:
* Originally developed on AVR Studio V4.18. Just add all *.asm files to the
  "Source Files" folder after creating a new project
* In tickbyte.asm, find TASK1, TASK2, and TASK3. Place your highest priority
  code (most time critical) in TASK3, medium priority in TASK2 and lowest
  priority in TASK1.
* Optionally you can add code to the IDLE task for instance resetting watchdog
  timer. Note that no timer exists for IDLE task, hence you can't block in IDLE
  task.
* To block/delay, load the amount of ticks to delay into the respective task's
  counter, then enter sleep mode. For improved readability, this has been
  included in a macro "blockt". Eg to block for 10 ticks in task2:
  blockt	T2_count,	10			;Wait 10 ticks
* Registers 17 to 21 are reserved for the task switcher, so writing to them may
  cause undesired results. For those interested, refer to tickbytedef.inc
* Blocking for 1 tick does not allow lower priority tasks to run - it blocks
  only for 1 tick and is ready to run at the next tick interrupt!


Dependencies:
* tn4def.inc distributed with AVR Studio
* AVR assembler supporting target MCU


The tickbyte kernel is meant for extremely low memory targets and so needs to
have some functionality removed that is normally included in traditional
kernels. Special care needs to be taken regarding the following:

(1) Registers R0 to R31 (or in the case of ATtiny4, R16 to R31) are shared and
so will not be pushed and popped to/from stack during context switching. The
only values saved in memory are the program counter (automatically done by AVR
core during interrupt)

(2) The stack is shared by all tasks

(3) No formal inter-task communication. Tasks should post messages to each
other using a single byte register or stack address, or temporarily turn off
interrupts during writing to or reading from multiple byte messages.

(4) No functions to create and destroy tasks on the fly, all tasks are created
during initialization

(5) Maximum of 3 tasks, excluding idle task

(6) All tasks differ in priority, with task3 highest priority and task1 lowest
priority

(7) When calling a subroutine from a task, do not block from inside the called
subroutine. IE only block in task subroutines themselves

(8) Avoid pushing and popping to/from stack. Instead, rather declare variables
directly in RAM

(9) Binary semaphores can be implemented by creating a variable in RAM

(10) As part of an attempt to reduce code size, the idle task runs at startup
instead of Task3

(11) During tick interrupt, the status register is not saved on stack,
therefore it's recommended to disable interrupts before executing an operation
that depends on the status register, and enabling interrupts again afterwards.
Also do not block when interrupts are disabled

(12) If a task blocks, the kernel waits until the next tick interrupt to give
other tasks CPU time. In other words, processing time is wasted by going into
sleep when other tasks may be ready to run. Ideally, one would like to have
other tasks get processor time in the same tick period

(13) The timer used to generate the systick interrupt is currently set to
interrupt on overflow, therefore the tick rate is not adjustable


Todo
* Port to GCC
* After having ported to GCC, allow tasks to be written in C
* Implement mechanism to allow other tasks that are ready to run to get
  processor time without waiting for the next tick interrupt
* Add option of specifying tick rate and letting the tick interrupt trigger on
  timer compare match instead of a timer overflow. This might slightly increase
  code size
* Investigate possibility of removing ready to run register and selecting next
  task to run solely on timer values


Thanks to
* The FreeRTOS team for providing information on how real-time operating
  systems work. Their website contains a wealth of information
  http://www.freertos.org/
* The FemtoOS team for challenging other developers to make even smaller
  operating systems
  http://femtoos.org/
* The Helium OS team. Much inspiration on the task switcher has been drawn from
  their uncomplicated and well commented source code
  http://helium.sourceforge.net/


Further reading
* ATtiny4/5/9/10 data sheet
  http://www.atmel.com/Images/Atmel-8127-AVR-8-bit-Microcontroller-ATtiny4-ATtiny5-ATtiny9-ATtiny10_Datasheet.pdf
* Once project has been ported to GCC:
  Atmel AVR4027: Tips and Tricks to Optimize Your C Code for 8-bit AVR Microcontrollers
  http://www.atmel.com/Images/doc8453.pdf
  Atmel AT1886: Mixing Assembly and C with AVRGCC 
  http://www.atmel.com/Images/doc42055.pdf
* Only after first implementation of tickbyte, further reading on the topic if
  sharing stack revealed that FreeRTOS already has a similar approach to RAM
  constrained devices, and unsurprisingly, some of the same restrictions
  http://www.freertos.org/co-routine-limitations.html
* How FreeRTOS works. Not the same way tickbyte works, but interesting reading
  for anyone interested in RTOS. Example of impementation on AVR
  http://www.freertos.org/implementation/a00018.html
