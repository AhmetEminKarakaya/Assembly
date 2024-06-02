;Some definitions have been made in this area

start_address EQU 0x20000400		;Start address was defined
iteration_number EQU 16             ;Iteration number was defined
data EQU 0xA0A0F0F0                 ;Data was defined
value_mask_1 EQU 0xFFFF0000         ;Value of mask 1 was defined
value_mask_2 EQU 0x0000FFFF         ;Value of mask 2 was defined
searched_data EQU 0xA4	            ;Searched data was defined 
default_data EQU 0xFF               ;Default data was defined
address_increment EQU 0x00000020	;Address increment was defined
mask EQU 0x2000040F				    ;Mask was defined
address_to_compare EQU 0x20000430	;Address to compare was defined
new_mask EQU 0x2000041F		        ;New mask was defined 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	AREA MYCODE, CODE
		ALIGN
		ENTRY
		EXPORT __main	

__main

;Here, the defined values are placed in the registers

		LDR R0, =start_address      ;The first address given to address 1 is written to register R0
		LDR R1, =iteration_number   ;The number of iterations written to the R1 register
		LDR R2, =data               ;Data written to R2 register
		LDR R3, =address_increment  ;Address increment written to R3 register
		LDR R4, =value_mask_1       ;Mask value1 written to R4 register
		LDR R5, =value_mask_2       ;Mask value2 written to R5 register
		AND R6,R2,R4                ;The first 4 bits of the data from the left are masked and the output value is written to the R6 register
		LSR R6,R6,#16               ;Data right-justified by shifting the R6 register 16 bits right
		AND R7,R2,R5                ;Right 4 bits of data are masked and written to register R7
		LDR R8, =mask				;Mask written to register R8 register
		LDR R9, =address_to_compare;Address_to_compare written to R9 register
		LDR R10, =new_mask			;New mask value written to R10 register
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;A cycle has been established here. The aim in this loop is to fill the values as desired to the given address

WRITING 
		STRH R6,[R0]                ;It writes the value in R6 to the address of the R0 register.
		ORR R0,R0,R3				;Switched to the appropriate address to write the value in the R7 register
		STRH R7,[R0],#2   			;It writes the value in R7 to the address carried by the R0 register.
		CMP R0,R9					;Address value compared to 0x20000430 because we need to change my mask value
		MOVEQ R8,R10				;New mask value assigned to current mask value
		AND R0,R0,R8				;Switched to the appropriate address to write the value in the R6 register again	
		ADD R6,R6,#0x01				;Its value in the R6 register is increased by 1
		ADD R7,R7,#0x01				;Its value in the R7 register is increased by 1
		SUB R1,R1,#1				;Number of iterations reduced by 1
		CMP R1,#0					;The iteration count is compared to 0 and if it is not equal to 0 it will loop again
		BNE WRITING					
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		LDR R0, =start_address		;Since address1 has changed above, its first address is written again
		ADD R1,R1, #32              ;32 has been added to the reset iteration count because I need 32 more iterations in the other loop
	
;Here, a loop structure was set up again and it was checked whether the values in the addresses whose value was written in the previous loop were included. 
;If there is, the desired value is written to the R11 register. If not, the default value is written to the R11 register.	
	
SEARCHING
		CMP R1,#0					;Comparison with iteration 2 number 0
		MOVEQ R11,default_data	    ;If the number of iterations is equal to 0, the default data is written to the R10 register
		BEQ EXIT 					;Searched data not found and jumped to EXIT loop
		LDRB R12,[R0]				;Hovered over data at address R0
		ADD R0,R0,#2				;R0 register increased by 2
		SUB R1,R1,#1				;Number of iterations reduced by 1
		CMP R12,searched_data		;Compared with the searched data with the data on
		BEQ FOUND					;FOUND jumped to loop if match result is found
		B SEARCHING					;If not found, looped again and continued searching
		

FOUND 
	MOV R11,searched_data			;Search data is written to register R10, so data is found
	
EXIT B EXIT							;Infinitely looped
	END