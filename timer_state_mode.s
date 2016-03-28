.section .data

HOUSE_0_ON:
	.asciz "Routing power to house 0."

HOUSE_1_ON:
	.asciz "Routing power to house 1."
	
HOUSE_0_OFF:
	.asciz "Disconnecting house 0."

HOUSE_1_OFF:
	.asciz "Disconnecting house 1."

.section .text
.include "nios_macros.s"

# address for ADDR_JP1
.equ ADDR_JP1, 0xFF200060

# address for the IRQ line for JP1 (IRQ11)
.equ ADDR_JP1_IRQ, 0x800 

# address for the IRQ line for TIMER (IRQ0)
.equ ADDR_TIMER_IRQ, 0x001

#JTAG address
.equ JTAG, 0xFF201000

#red leds
.equ RED_LEDS, 0xFF200000

#timer
.equ TIMER, 0xFF202000

#time for timer to countdown from
.equ TIME, 0x02FAF080

# address for the TWO IRQ lines for JP1 and TIMER (IRQ11 and IRQ0)
.equ ADDR_JP1_TIMER_IRQ, 0x801

# address for SINGLE IRQ line for JP1
.equ ADDR_JP1_IRQ, 0x800

# address for SINGLE IRQ line for TIMER
.equ ADDR_TIMER_IRQ, 0x001

#memory
.equ HOUSE0_STATE, 0x3000FFFE
.equ HOUSE1_STATE, 0x3000FFF0
.equ SENSOR0_POLL, 0x3000FFE0
.equ SENSOR1_POLL, 0x3000FFEE
.equ SENSOR2_POLL, 0x3000FFDE

# sensor states in value mode
# everything is off except the sensor0 and sensor1 bits
.equ SENSOR0_TIMER, 0xfffffbff
.equ SENSOR1_TIMER, 0xffffefff
.equ SENSOR2_TIMER, 0xffff7fff

.global main

main:

#move the address of JP1 into r8
movia r8, ADDR_JP1
# move the address into the call so that we can use it
mov r4, r8

# clear the edge capture register
movi r10, -1
stwio r10, 12(r8)

# initialize house states to zero
movia r10, HOUSE0_STATE
movi r11, 0
stw r11, 0(r10)

movia r10, HOUSE1_STATE
stw r11, 0(r10)

# initialize sensor data to zero
movia r10, SENSOR0_POLL
stw r11, 0(r10)

movia r10, SENSOR1_POLL
stw r11, 0(r10)

movia r10, SENSOR2_POLL
stw r11, 0(r10)
#***done sensor poll data memory initialization

#let JTAG exist, non-clobbered register
movia r23, JTAG

movia r22, RED_LEDS
stwio r11, 0(r22)

movia r20, HEXLOW
movi r10, 0b000111111
stwio r10, 0(r20)

#setting motor/threshold/sensor bits to output, set states and sensors to inputs; send to direction register
movia r9, 0x07f557ff
stwio r9, 4(r8)

#set threshold for touch to 0xF and load the value into the data register
#enable sensor 0 and sensor 1
movia r9, 0x07bfebff
stwio r9, 0(r8) 

# temporarily disable threshold register and enable state mode
# into data register
movia r9, 0xffdfffff
stwio r9, 0(r8)

# enable interrupts for sensor 0 and sensor 1
#movia r9, 0x18000000
movia r9, 0xf8000000
stwio r9, 8(r8)

# initialize the counter's count down value
# move address of timer into r8 to 
movia r8, TIMER
movui r9, %lo(TIME)
stwio r9, 8(r8)
movui r9, %hi(TIME)
stwio r9, 12(r8)
# clear timeout
stwio r0, (r8)
# no stop, yes start timer, no continue, enable interrupts for timeouts
movui r9, 0b0101
stwio r9, 4(r8)

# done configuring the JP1. Enable the interrupt IRQ lines for the JP1 and TIMER now
movia r8, ADDR_JP1_TIMER_IRQ
wrctl ienable, r8

# for PIE
movia r8, 1
wrctl status, r8



LOOP:
	br LOOP
	

#****************SUBROUTINES FOR EXCEPTION HANDLER******************
#***************LED AND HEX SUBROUTINES***********
LED_HEX:

	#check the states of the houses
	movia r15, HOUSE0_STATE
	movia r14, HOUSE1_STATE
	ldw r13, 0(r15)
	ldw r12, 0(r14)
	add r13, r13, r12
	beq r13, r0, zero			#if nothing on
	movi r12, 1
	beq r13, r12, one			#if one on
	movi r12, 2
	beq r13, r12, two			#if two on
	
	
	zero:
		#set hex 0 to 0
		stwio r0, 0(r22)
		movia r12, HEXLOW
		movi r13, 0b000111111
		stwio r13, 0(r12)
		
		#turn off all leds
		movi r14, 0x0
		stwio r14, 0(r22)
		br exit_handler
		
	one:
		#set hex 0 to 1
		stwio r0, 0(r22)
		movia r12, HEXLOW
		movi r13, 0b000000110
		stwio r13, 0(r12)
		
		#turn off all leds
		movi r14, 0x1
		stwio r14, 0(r22)
		br exit_handler
	
	two:
		#set hex 0 to 2
		stwio r0, 0(r22)
		movia r12, HEXLOW
		movi r13, 0b001011011
		stwio r13, 0(r12)
		
		#turn off all leds
		movi r14, 0x2
		stwio r14, 0(r22)
		br exit_handler
		
act_sensor0:

	write_sensor0:
	
	# check house state
	movia r9, HOUSE0_STATE
	ldw r10, 0(r9)
	beq r10, r0, turn_house_on
	br disconnected_0
	
	turn_house_on:
		# Setting the state to 1, loaded
		movi r10, 1
		stw r10, 0(r9)

		
		#Deal with JTAG. Prints 0/1
		movia r15, HOUSE_0_ON
		Loop_house0:
			ldb r14, 0(r15)
			beq r14, r0, exit_0
			stwio r14, 0(r23)
			addi r15, r15, 1
			
			br Loop_house0

	disconnected_0:
	
		#Setting state to 0, disconnected
		movi r10, 0
		stw r10, 0(r9)

		movia r15, HOUSE_0_OFF
		Loop_house0_disconnect:
			ldb r14, 0(r15)
			beq r14, r0, exit_0
			stwio r14, 0(r23)
			addi r15, r15, 1
			
			br Loop_house0_disconnect
	
	exit_0:
		#new line character
		movi r14, 0xA
		stwio r14, 0(r23)
		
		br LED_HEX
		
	
act_sensor1:

	write_sensor1:
	# check house state
	movia r9, HOUSE1_STATE
	ldw r10, 0(r9)
	beq r10, r0, turn_house_1_on
	br disconnected_1
	
	turn_house_1_on:
		# Setting the state to 1, loaded
		movi r10, 1
		stw r10, 0(r9)
		
		#Deal with JTAG. Prints 0/1
		movia r15, HOUSE_1_ON
		Loop_house1:
			ldb r14, 0(r15)
			beq r14, r0, exit_0
			stwio r14, 0(r23)
			addi r15, r15, 1
			
			br Loop_house1

	disconnected_1:
	
		#Setting state to 0, disconnected
		movi r10, 0
		stw r10, 0(r9)

		movia r15, HOUSE_1_OFF
		Loop_house1_disconnect:
			ldb r14, 0(r15)
			beq r14, r0, exit_1
			stwio r14, 0(r23)
			addi r15, r15, 1
			
			br Loop_house1_disconnect
	
	exit_1:
		#new line character
		movi r14, 0xA
		stwio r14, 0(r23)
		
		br LED_HEX

#***************TIMER_HANDLER SUBROUTINES***********
# the timer_handler has to:
# 0. Disable the IRQ line of that device
# 1. change from state mode to value mode
# 2. poll the sensors for data and store it
# 3. change it back to state mode before returning to the main program		
# 4. acknowledge the timer interrupt

timer_handler:

	# disable IRQ line of the JP1 (we don't want any other interrupts)
	# only enabling the IRQ line of the TIMER
	movia r9, ADDR_TIMER_IRQ
	wrctl ienable, r9
	
	#get address of the JP1
	movia r9, ADDR_JP1
	
loop_sensor0:
	movia r10, SENSOR0_TIMER
	stwio r10, 0(r9)
	# need to check sensor0's valid bit
	ldwio r11, 0(r9)
	# sensor0's valid bit is shifted by 11
	srli r11, r11, 11
	andi r11, r11, 0x1
	bne r0, r11, loop_sensor0
good_sensor0:
	# put result into r14
	ldwio r14, 0(r9)
	# now the 4-bit sensor value is in the lower 4 bits. Convenient.
	srli r14, r14, 27
	andi r14, r14, 0x0f

	#move the r14 sensor value into appropriate memory (in r15)
	movia r15, SENSOR0_POLL
	stw r14, 0(r15)

# done polling sensor0, now do sensor1
loop_sensor1:
	# same process as with SENSOR0_TIMER
	movia r10, SENSOR1_TIMER
	stwio r10, 0(r9)
	# check sensor1 valid bit
	ldwio r11, 0(r9)
	# sensor1's valid bit shifted by 13
	srli r11, r11, 13
	andi r11, r11, 0x1
	bne r0, r11, loop_sensor1
good_sensor1:
	# store contents in r15
	ldwio r14, 0(r9)
	srli r14, r14, 27
	andi r14, r14, 0x0f
	# store contents into memory now

	movia r15, SENSOR1_POLL
	stw r14, 0(r15)

# done polling sensor1, now do sensor2
loop_sensor2:
	movia r10, SENSOR2_TIMER
	stwio r10, 0(r9)
	ldwio r11, 0(r9)
	srli r11, r11, 15
	andi r11, r11, 0x1
	bne r0, r11, loop_sensor2
good_sensor2: 
	ldwio r14, 0(r9)
	srli r14, r14, 27
	andi r14, r14, 0x0f

	movia r15, SENSOR2_POLL
	stw r14, 0(r15)
# sensor0, sensor1, and sensor2 data stored in memory
# do something with the data? I guess?
	
	#change back to state mode
	#set threshold for touch to 0xF and load the value into the data register
	#enable sensor 0 and sensor 1
	movia r10, 0x07bfebff
	stwio r10, 0(r9) 

	# temporarily disable threshold register and enable state mode
	# into data register
	movia r10, 0xffdfffff
	stwio r10, 0(r9)

	# enable interrupts for sensor 0 and sensor 1
	#movia r10, 0x18000000
	movia r10, 0xf8000000
	stwio r10, 8(r9)

	# clear the edge capture register immediately before re-enabling
	# suggested by Henry Wong
	movi r9, -1
	stwio r9, 12(r4)
	
	# re-enable the JP1 IRQ line
	# once again, the JP1 AND the TIMER are allowed to interrupt
	movia r9, ADDR_JP1_TIMER_IRQ
	wrctl ienable, r9
	
	#acknowledge timer interrupt
	#the last thing we do
	movia r9, TIMER
	stwio r0, 0(r9)
	
	br exit_handler

#***************************EXCEPTION*HANDLER********************************		
.section .exceptions, "ax"
.global exception_handler

#NOTE: when an interrupt occurs, PIE automatically becomes 0 

# have to write to this register in order to acknowledge
# edge reg is 12(base) for JP1
.equ ADDR_JP1_EDGE, 0xFF20006C
.equ SENSOR0, 0x08000000
.equ SENSOR1, 0x10000000
.equ HEXLOW, 0xFF200020

exception_handler:

addi sp, sp, -24
stw r9, 0(sp)
stw r10, 4(sp) 
stw r11, 8(sp)
stw r12, 12(sp)
stw r13, 16(sp)
stw r14, 20(sp)
stw r15, 24(sp)

# check the interrupt pending register to see if there is a result (an interrupt)
rdctl et, ipending
#make copy of et in r10
mov r10, et

# check to see if the interrupt is from IRQ line 0 (TIMER)
# r10 has a copy of et, so it is essentially "and r11, r11, et"
and r11, r11, r10
# if it is the timer
bne r11, r0, timer_handler

movia r9, ADDR_JP1_IRQ
# check to see if the interrupt is from IRQ line 11 (JP1)
and r9, r9, et
movia r11, ADDR_TIMER_IRQ
beq r9, r0, exit_handler

movia r9, ADDR_JP1_EDGE
# check the edge capture register JP1
ldwio et, 0(r9)

# need to compare and see if it was sensor1 vs sensor0, so need a copy of base result
mov r10, et

movia r11, SENSOR0
# check sensor0 first
and r9, et, r11
# it's sensor0 that interrupted
movia r15, SENSOR0
beq r9, r15, act_sensor0

movia r12, SENSOR1
# check sensor1 next
and r10, et, r12
beq r9, r0, act_sensor1

# if it's neither one that interrupted, then exit_handler
br exit_handler
		
exit_handler:

#write to the edge register to acknowledge
movi r13, -1
stwio r13, 12(r4)

ldw r15, 24(sp)
ldw r14, 20(sp)
ldw r13, 16(sp)
ldw r12, 12(sp)
ldw r11, 8(sp)
ldw r10, 4(sp)
ldw r9, 0(sp)
addi sp, sp, 24

subi ea, ea, 4

eret


.end

















































