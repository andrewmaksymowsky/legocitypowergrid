
.section .text
.include "nios_macros.s"

# address for ADDR_JP1
.equ ADDR_JP1, 0xFF200060

# address for the IRQ line for JP1 (IRQ11)
.equ ADDR_JP1_IRQ, 0x800 

#JTAG address
.equ JTAG, 0x10001020

.global main

main:

#move the address of JP1 into r8
movia r8, ADDR_JP1

#let JTAG exist, non-clobbered register
movia r23, JTAG

#setting motor/threshold/sensor bits to output, set states and sensors to inputs; send to direction register
movia r9, 0x07f557ff
stwio r9, 4(r8)

#set threshold for touch to 0xF and load the value into the data register
#enable sensor 0 and sensor 1
movia r9, 0xe7bfdbff
stwio r9, 0(r8) 

# temporarily disable threshold register and enable state mode
# into data register
movia r9, 0xffdfffff
stwio r9, 0(r8)

# time to enable interrupts for sensor 0 and sensor 1
movia r9, 0x18000000
stwio r9, 8(r8)

# done configuring the JP1. Enable the interrupts for the JP1 now
movia r8, ADDR_JP1_IRQ
wrctl ienable, r8

# for PIE
movia r8, 1
wrctl status, r8

LOOP:
	br LOOP
	

.section .exceptions, "ax"

# have to write to this register in order to acknowledge
# edge reg is 12(base) for JP1
.equ ADDR_JP1_EDGE, 0xFF20006C
.equ SENSOR0, 0x08000000
.equ SENSOR1, 0x10000000
exception_handler:

addi sp, sp, -20
stw r2, 0(sp)
stw r3, 4(sp) 
stw r4, 8(sp)
stw r5, 12(sp)
stw r6, 16(sp)
stw r7, 20(sp)

# check the interrupt pending register to see if there is a result (an interrupt)
rdctl et, ipending
movia r2, ADDR_JP1_IRQ
# check to see if the interrupt is from IRQ line 11 (JP1)
and r2, r2, et
beq r2, r0, exit_handler

movia r2, ADDR_JP1_EDGE
# check the edge capture register JP1
ldwio et, 0(r2)

# need to compare and see if it was sensor1 vs sensor0, so need a copy of base result
mov r2, r3


movia r4, SENSOR0
# check sensor0 first
and r2, et, r4
# it's sensor0 that interrupted
bne r2, r0, act_sensor0

movia r5, SENSOR1
# check sensor1 next
and r3, et, r5
bne r2, r0, act_sensor1

# if it's neither one that interrupted, then exit_handler
br exit_handler

exit_handler:

ldw r7, 20(sp)
ldw r6, 16(sp)
ldw r5, 12(sp)
ldw r4, 8(sp)
ldw r3, 4(sp)
ldw r2, 0(sp)
addi sp, sp, 20

eret

act_sensor0:

write:
ldwio r6, 4(r23)
srli r6, r6, 16
beq r6, r6, write
br write

act_sensor1:






















































