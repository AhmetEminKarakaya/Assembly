; GPIO base addresses of port A and D
gpioDbase	EQU		0x4005B000 ; inp
gpioAbase	EQU		0x40058000 ; out
	
; GPIO offsets, least significant 8 bits (mostly)
gpioData	EQU		0x000	; 'data' add relevant gpio data mask offset for masking, to read or write all values add 0x3FC to base which is sum of all bit constants
gpioDir		EQU		0x400	; 'direction' 0 for inp, 1 for out, inp by default
gpioAfsel	EQU		0x420	; 'alterrnate function select' 0 for standard gpio and gpio register used in this time, 1 for path over selected alternate hardware function, hardware function selection is done by gpiopctl register control, 0 default
gpioPctrl	EQU		0x52C	; 'port control' see documentation
gpioLock	EQU		0x520	; to unlock 0x4c4f434b shoulb be written, any other write locks back, enables write access to gpiocr
gpioCr		EQU		0x524	; 'commit' gpioafsel, pur, pdr, den can only be changed with setting bit in cr, only modified when unlock gpiolock
gpioAmsel	EQU		0x528	; 'analog mode select' only valid for pins of adc, set for analog, 
gpioDen		EQU		0x51c	; 'digital enable' 

; GPIO data mask offset constant, [9:2] in address are ussed for [7:0] bits masking 
; to only write to pin 5 of any port 'five' offset should be added to gpiodata
; to only write to pins 2 and 5 of any port data should be written dataregister address + 'two'+'five' offset address remainings left unchange in output 0 in input mode
gpioDataZero	EQU		0x004
gpioDataOne		EQU		0x008
gpioDataTwo		EQU		0x010
gpioDataThree	EQU		0x020
gpioDataFour	EQU		0x040
gpioDataFive	EQU		0x080
gpioDataSix		EQU		0x100
gpioDataSeven	EQU		0x200

; GPIO Interrupt registers, least significant 8 bits (mostly)
gpioIs		EQU		0x404	; 'interrupt sense' 1 for level sensitivity, 0 for edge sensitivity
gpioIbe		EQU		0x408	; 'interrupt both edges' if 1 regardless of gpioie register interrupt occur for both edge, if 0 gpioie register define which edge, default 0 all
gpioIev		EQU		0x40C	; 'interrupt evet' 1 for rising edge, 0 for falling edge, 0 default
gpioIm		EQU		0x410	; 'interrupt mask' 1 to sendt interrupt co interrupt controller, 0 default
gpioRis		EQU		0x414	; 'raw interrupt status' read only, set automatically if interrupt occur if gpioim is set interrupt sent is to interrupt controller, if level detectin signal must be held until serviced, if edge write 1 to gpioicr to erase relavent gpioris, gpiomis is the masked value of gpioris
gpioMis		EQU		0x418	; 'masked interrupt status' readonly, if 1 sent to interrupt controller, if 0 no interrupt or masked
gpioIcr		EQU		0x41C	; 'interrupt clear' for edge sensitivity write 1 clears gpiomis and gpioris, no effect on level detect, no effect writing 0
	
; GPIO Pad control registers
gpioDr2r	EQU		0x500	; '2ma drive select' if select dr4r, dr8r cleared automatically, all set default
gpioDr4r	EQU		0x504
gpioDr8r	EQU		0x508	; used for high current applications
gpioOdr		EQU		0x50C	; 'open drain select' set for open drain, if set corresponding gpioden bit should also be set, gpiodr2r, 4r,8r, gpioslr should be used for desired fall time, if pin is imput no effect 
gpioPur		EQU		0x510	; 'pullup select' set to add 20k ohm pullup, if set gpiopdr automatically cleared, write access protected by gpiocr register
gpioPdr		EQU		0x514	; 'pulldownselect' 
gpioSlr		EQU		0x518	; 'slew rate sontrol select' available only when 8ma strength used

; GPIO clck gating register 
; default 0 and disabled by clck blocking
; bit #0 for port A and #1 for port B should be set to enable ports
; after setting 3 clck cycle is needed to reach port registers properly
rcgcgpio	EQU		0x400FE608	
	
high_frequency_value EQU 0x4C0000   ; high_frequency_value defined(When I observe in the simulation I am making the value 3 of it. To be able to observe.)
low_frequency_value  EQU 0x0C0000   ; low_frequency_value defined
delay_address  EQU 0x20000400       ; Delay_address defined
	

	AREA INTRPT, CODE
		ALIGN
		;EXTERN checkblink

		EXPORT ISRD
ISRD    PROC

		NOP
		
		LDR R2, =low_frequency_value   ; Low_frequency_value written to register R2
		LDR R3, =delay_address         ; Delay_address written to R3 register
		STR R2, [R3]                   ; Low_frequency_value is written to delay address

		LDR R1, =gpioAbase
		ADD R1, #0x100                 ; R1 stores address of data reg port A (make sure not to change in any branch)
		LDR R0, [R1]
	
		ORR R0, R0, #0x01
		STR R0, [R1]                   ; Makes Buzzer's state logic 1. So it makes it ring.
		BL delay_isrd
	
		LDR R0, [R1]
	
		BIC R0, R0, #0x01
		STR R0, [R1]                   ; Makes Buzzer's state logic 0. So it makes it doesn't ring.
		BL delay_isrd
					        
delay_isrd
		LDR R4, [R3]		   ; The value at address R3, which holds the delaying time, is written to register R4
				
wait_isrd
		SUB R4, R4, #1         ; Delay time reduced by 1
		CMP R4, #0             ; Comparing whether the delay time is 0
		BNE wait_isrd          ; If not 0 it went back to the beginning of the loop
		BX   LR
				
		;clear flag for further interrupts
		LDR R0,=gpioDbase 
		ADD R0,R0, #gpioIcr
		LDR R1,[R0]
		ORR R1,R1,#1
		STR R1,[R0]
		
		BX LR
		ENDP
	ALIGN


  AREA MYCODE, CODE
	  ALIGN
	  EXTERN  initializegpio
	  ENTRY
	  EXPORT __main
		  
__main

		NOP
		BL initializegpio			 


high_frequency_ringing
				LDR R2, =high_frequency_value  ; High_frequency_value written to register R2
				LDR R3, =delay_address         ; Delay_address written to R3 register
				STR R2, [R3]                   ; High_frequency_value is written to delay address

				LDR R1, =gpioAbase
				ADD R1, #0x100                 ; R1 stores address of data reg port A (make sure not to change in any branch)
				LDR R0, [R1]
	
				ORR R0, R0, #0x01
				STR R0, [R1]                   ; Makes Buzzer's state logic 1. So it makes it ring.
				BL delay
	
				LDR R0, [R1]
	
				BIC R0, R0, #0x01
				STR R0, [R1]                   ; Makes Buzzer's state logic 0. So it makes it doesn't ring.
				BL delay
				
				B high_frequency_ringing       ;The code went back to the high frequency ringing branch to continue the loop.
	
delay
				LDR R4, [R3]				   ; The value at address R3, which holds the delaying time, is written to register R4
				
wait
				SUB R4, R4, #1                 ; Delay time reduced by 1
				CMP R4, #0                     ; Comparing whether the delay time is 0
				BNE wait                       ; If not 0 it went back to the beginning of the loop
				BX   LR
				
				
				ALIGN
				END