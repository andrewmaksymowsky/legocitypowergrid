#This File measures the position of the solar panels and turns the panel

.section .text
.equ ADC, 0xFF204000
.equ ADC_Data, 0x0300FFFF
.equ ADDR_JP1, 0xFF200060


.global panel_control

#subroutine for positioning the panels
panel_control:

	#Free up Registers
	#subi sp, sp, 32
	#stw ra,  32(sp)
	#stw r8,  28(sp)
	#stw r9,  24(sp)
	#stw r10, 20(sp)
	#stw r11, 16(sp)
	#stw r12, 12(sp)
	#stw r13, 8(sp)
	#stw r12, 4(sp)
	#stw r13, 0(sp)

	#Get the Current Position of the Panels
		#Refresh the data in the ADC registers
		movia r8, ADC
		movi r9, 0x01
		stwio r9, 0(r8)
		
		#Load in the Data From the ADC
		ldwio r9, 0(r8)
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
		movi r9, 0x07
		movi r10, 0x0F
	
	#Decide which way to turn and turn that way
		bgtu r9, r10, turn_left
		bgtu r10, r9, turn_right
		br no_turn
			
		turn_left:
			#make sure not already pointed all the way left
			movia r11, ADC_Data
			ldw r12, 0(r11)
			movi r13, 0x0FFF
			bgeu r12, r13, no_turn
			
			#otherwise turn left
			movia r11, 0x07f557ff
			stwio r11, 4(r8)
			movia r12, 0xfffffffe
			stwio r12, 0(r8)
			br no_turn
		
		turn_right:
			#make sure not already pointed all the way right
			movia r11, ADC_Data
			ldw r12, 0(r11)
			movi r13, 0x05
			bleu r12, r13, no_turn
			
			#otherwise turn right
			movia r11, 0x07f557ff
			stwio r11, 4(r8)
			movia r12, 0xfffffffc
			stwio r12, 0(r8)
			br no_turn
			
		no_turn:
			#wait 600 cycles -> let the motor turn the panels
			#NEED TO DO: make this start the timer and use an interrupt
			#from timer two to turn off the motors
			movi r13, 600
			wait:
			subi r13, r13, 1
			bne r13, r0, wait
			
			#turn the motor off
			movia r9, 0x07f557ff
			stwio r9, 4(r8)
			movia r10, 0xFFFFFFFF
			stwio r9, 0(r8)
			
	#clear off the stack		
		#ldw ra,  32(sp)
		#ldw r8,  28(sp)
		#ldw r9,  24(sp)
		#ldw r10, 20(sp)
		#ldw r11, 16(sp)
		#ldw r12, 12(sp)
		#ldw r13, 8(sp)
		#ldw r12, 4(sp)
		#ldw r13, 0(sp)
		#addi sp, sp, 32
			#Panel 1: X Watts
			#Panel 2: Y Watts
			
br panel_control
	