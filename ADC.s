#This File measures the position of the solar panels and turns the panel

.section .text
.equ ADC, 0xFF204000
.equ ADC_Data, 0x0300FFFF
.equ ADDR_JP1, 0xFF200060
.equ Panel_Position, 0x0300FFF0

.equ SENSOR2_POLL, 0x3000FFEE
.equ SENSOR3_POLL, 0x3000FFDE

.equ TIMER_2, 0xFF202020

.global panel_control

#subroutine for positioning the panels
panel_control:

	#Free up Registers
	subi sp, sp, 48
	stw ra,  48(sp)
	stw r8,  44(sp)
	stw r9,  40(sp)
	stw r10, 36(sp)
	stw r11, 32(sp)
	stw r12, 28(sp)
	stw r13, 24(sp)
	stw r14, 20(sp)
	stw r15, 16(sp)
	stw r16, 12(sp)
	stw r17, 8(sp)
	stw r18, 4(sp)
	stw r19, 0(sp)

	#Get the Current Position of the Panels
		#Refresh the data in the ADC registers
		movia r8, ADC
		movi r9, 0x01
		stwio r9, 0(r8)
		
		#Load in the Data From the ADC
		ldwio r9, 0(r8)
		movi r9, 0x0fff # ADC not working right now for some reason.
		ldwio r10, 4(r8)
		ldwio r11, 8(r8)
		ldwio r12, 12(r8)
		
		#Store the Data Into Memory
		movia r8, ADC_Data
		stw r9,  0(r8)
		stw r10, 4(r8)
		stw r11, 8(r8)
		stw r12, 12(r8)
		
	#Set up the Lego Controller for turning the motors
		movia r8, ADDR_JP1
		
	#Get the light sensor data
		#LOAD DATA IN FROM Memory
		movia r11, SENSOR2_POLL
		ldw r9, 0(r11)
		movia r11, SENSOR3_POLL
		ldw r10, 0(r11)
		
	#Get current panel position and put the comparison values in registers
		movia r11, Panel_Position
		ldw r12, 0(r11)
	
		movia r18, 0x00021CC2  #
		movia r19, 0x00000E34  #0CD2f
	
	#Decide which way to turn and turn that way
		addi r10, r10, 2
		bgtu r9, r10, turn_left
		subi r10, r10, 2
		addi r9, r9, 2
		bgtu r10, r9, turn_right
		br turn_center
		
		turn_center:
			#figure out which way we should be turning
			movia r15, 0x0000ffff
			bgtu r12, r15, turn_right
			bgtu r15, r12, turn_left
			movia r13, 500
			beq r12, r15, no_turn
			
			
			
		turn_right:
			#make sure not already pointed all the way left
			movia r13, 500
			beq r12, r19, no_turn
			
			#otherwise turn left and decrement the panel position
			ldw r13, (r8)
			movia r12, 0xfffffffe
			and r9, r12, r13
			stwio r9, 0(r8)
			
			movia r11, Panel_Position
			ldw r12, 0(r11)
			subi r12, r12, 0x01
			stw r12, 0(r11)
			
			movia r13, 150
			
			br no_turn
			
		turn_left:
			#make sure not already pointed all the way right
			movia r13, 500
			beq r12, r18, no_turn
			
			#otherwise turn right and increment the panel position
			ldw r13, (r8)
			movia r12, 0xfffffffc
			and r10, r12, r13
			stwio r10, 0(r8)
			
			movia r11, Panel_Position
			ldw r12, 0(r11)
			addi r12, r12, 0x01
			stw r12, 0(r11)
			
			movia r13, 40
			
			br no_turn
				
		no_turn:
		
			wait:
			subi r13, r13, 1
			bne r13, r0, wait
				
			movia r8, ADDR_JP1
			ldw r13, 0(r8)
			movia r12, 0x00000000f   #code to turn motor off and leave everything else the way it is
			or r10, r12, r13
			stwio r10, 0(r8)
			

		
	clear_stack:		
	#clear off the stack		
		ldw ra,  48(sp)
		ldw r8,  44(sp)
		ldw r9,  40(sp)
		ldw r10, 36(sp)
		ldw r11, 32(sp)
		ldw r12, 28(sp)
		ldw r13, 24(sp)
		ldw r14, 20(sp)
		ldw r15, 16(sp)
		ldw r16, 12(sp)
		ldw r17, 8(sp)
		ldw r18, 4(sp)
		ldw r19, 0(sp)
		addi sp, sp, 48
			
ret
	
