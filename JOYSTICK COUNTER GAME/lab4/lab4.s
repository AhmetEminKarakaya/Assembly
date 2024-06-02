; GPIO base addresses of port D,E and H
gpioDbase	EQU		0x4005B000 ; inp
gpioEbase	EQU		0x4005C000 ; out
gpioHbase   EQU     0x4005F000 ; inp 
 	
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
delay_time  EQU     4
delay_real  EQU     0X0C0000
game_time   EQU	    0x0
game_total_time EQU 20	
	
	
 AREA MYCODE, CODE	
	 ENTRY
	 EXPORT __main
__main

		NOP
		BL initializegpio						; porte is adjusted as output and portd as input use porte bit 0 and 1 and portd bit 0 for this experiment for the following code blocks

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In this branch, a playtime value is assigned to the R5 register. A counter with an initial value of 0 is assigned to increment the R4 register. 
;Then, the button on D port 0 bit was read and if it was 0, it did not start the game and went to the finish_game branch.
;If the button was pressed, it went to the start_game branch to start the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

checkSwitch		
				LDR R5, =game_total_time
				LDR R4, =game_time
				LDR R1, =gpioDbase
				ADD R1, #0x04
				LDR R0, [R1]					; data read in R0
				;MOV R0, #0x01                   ;Assigned to debug simulation. In normal code this is not valid.
				
				CMP R0, #0 
				BEQ finish_game
				BNE start_game
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In this branch, the game starts and compares the game time first. If the game time has not expired, it returns to the game again. Done ends the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_game 				
				CMP R4,R5
				BEQ finish_game
				BNE restart_game

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In this branch, the code is trying to determine the position of the joystick. When it finds the joystick's position, it does the led operations accordingly. 
;If it is idle, it goes to the start game branch again. While doing this, it also increases the game time.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

restart_game    
				ADD R4, R4, #1
				
				LDR R1, =gpioHbase
				ADD R1, #0x200           ; 7th bit control of H port
				LDR R0, [R1]
				;MOV R11, #1              ;Assigned to debug simulation. In normal code this is not valid.
	
				;CMP R11, #1              ;Assigned to debug simulation. In normal code this is not valid.
				CMP R0, #0                ;I compared it to 0 because the joystick pull-up is a button. If it was pull-down then we need to compare with 1.
				BEQ on_all_leds
					
				LDR R1, =gpioHbase
				ADD R1, #0x100           ;6th bit control of H port
				LDR R0, [R1]

				;CMP R11, #2              ;Assigned to debug simulation. In normal code this is not valid.
				CMP R0, #0				  ;I compared it to 0 because the joystick pull-up is a button. If it was pull-down then we need to compare with 1.
				BEQ off_all_leds
				
				LDR R1, =gpioHbase
				ADD R1, #0x80            ;5th bit control of H port 
				LDR R0, [R1]

				;CMP R11, #3              ;Assigned to debug simulation. In normal code this is not valid.
				CMP R0, #0				  ;I compared it to 0 because the joystick pull-up is a button. If it was pull-down then we need to compare with 1.
				BEQ increasing_blink
				
				LDR R1, =gpioHbase
				ADD R1, #0x40            ;4th bit control of H port
				LDR R0, [R1]

				;CMP R11, #4              ;Assigned to debug simulation. In normal code this is not valid.
				CMP R0, #0                ;I compared it to 0 because the joystick pull-up is a button. If it was pull-down then we need to compare with 1.
				BEQ decreasing_blink

				BL start_game            ;If the joystick is idle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In this branch, all the leds on the E port are turned on.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
				
on_all_leds	    LDR R1, =gpioEbase
				ADD R1, #0x3C			
			    LDR R0, [R1]			
			
				ORR R0, R0, #0xF	
				STR R0, [R1]	   
				BL   start_game	
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In this branch, all the leds on the E port are turned off.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

off_all_leds	LDR R1, =gpioEbase
				ADD R1, #0x3C				
			    LDR R0, [R1]			
		
				BIC R0, R0, #0xF	
				STR R0, [R1]
				BL start_game 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In this branch, the LEDs in the E port are turned on using binary increments.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

increasing_blink   	
				LDR R1, =gpioEbase
				ADD R1, #0x3C				
			    LDR R0, [R1]

				CMP R0, #0x0F
				BEQ start_game
				
				ADD R0, R0, #0x01
				STR R0, [R1]
				BL delay
				CMP R0, #0x0F
				BEQ	start_game	
				BNE increasing_blink
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;In this branch, the LEDs in the E port are turned off using binary increments.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

decreasing_blink   	
				
				LDR R1, =gpioEbase
				ADD R1, #0x3C				
			    LDR R0, [R1]	
				CMP R0, #0x0
				BEQ start_game
		
				SUB R0, R0, #0x01
				STR R0, [R1]
				BL delay
				CMP R0, #0x0
				BEQ	start_game	
				BNE decreasing_blink				

				
delay			LDR R3,=delay_real   ;The durations between LEDs turn on are assigned to the R3 register.
				;LDR R3,=delay_time  ;Assigned to debug simulation. In normal code this is not valid.
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;				
;During the delay time given in this branch, the code returns here as much as the delay time.				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait   			SUB R3, R3, #1 
				CMP R3, #0     
				BNE wait 
				BX   LR
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;This branch will run when the game time is over or if the key on port D is 0.
;Here, it will wait until the new game starts with the last state of the leds and after waiting, the leds are cleared and it goes to the checkSwitch branch to check the switch on the D port and the code continues in that way.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

finish_game	    
				LDR R4,=game_time
				BL delay
				LDR R1, =gpioEbase
				ADD R1, #0x3C				
			    LDR R0, [R1]			
		
				BIC R0, R0, #0xF	
				STR R0, [R1]
				B	checkSwitch   ;When the game was over, the code went to the chechswitch branch to check the button on the D port again.


initializegpio
				; enable clck for ports D,E and H
				LDR R1, =rcgcgpio
				LDR R0, [R1]
				ORR R0, R0, #0x98 ;BEN YAZDIM
				STR R0, [R1]
				NOP
				NOP
				NOP
				; out port E
				LDR R1, =gpioEbase
				ADD R1, R1, #gpioDir
				LDR R0, [R1]
				ORR R0, R0, #0x3F
				STR R0, [R1]
				; afsel
				LDR R1, =gpioEbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioDbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioHbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				
				; den 1 for ports
				LDR R1, =gpioDbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioEbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioHbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				
				BX LR

				ALIGN
				END