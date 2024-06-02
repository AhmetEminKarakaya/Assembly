; GPIO base addresses of port A,D and NVIC
gpioDbase	EQU		0x4005B000 ; inp
gpioAbase	EQU		0x40058000 ; out
nvicBase    EQU     0xE000E000 ; nvic	
	
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
gpioIev		EQU		0x40C	; 'interrupt event' 1 for rising edge, 0 for falling edge, 0 default
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

nvicEN0     EQU     0x100  ; offset value of NVICEN0 register
	
	
	AREA INIT, CODE, READONLY
		EXPORT initializegpio


initializegpio
				; enable clck for ports A and D
				LDR R1, =rcgcgpio
				LDR R0, [R1]
				ORR R0, R0, #0x09
				STR R0, [R1]
				NOP
				NOP
				NOP
				
				; out port A
				LDR R1, =gpioAbase
				ADD R1, R1, #gpioDir
				LDR R0, [R1]
				ORR R0, R0, #0x3F
				STR R0, [R1]
				
				; afsel
				LDR R1, =gpioDbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				
				LDR R1, =gpioAbase
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
				
				LDR R1, =gpioAbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				
				;interrupt mask for portD first pin
				LDR R1,=gpioDbase
				ADD R1, R1, #gpioIm
				LDR R0,[R1]
				ORR R0, R0, #0x01
				STR R0, [R1]
				
				LDR R1,=gpioDbase
				ADD R1, R1, #gpioIev
				LDR R0,[R1]
				ORR R0, R0, #0x01
				STR R0, [R1]
				
				;NVIC for portD
				LDR R1, =nvicBase
				ADD R1, R1, #nvicEN0
				LDR R0, [R1]
				ORR R0, R0, #0x8 ; for port D
				STR R0, [R1]
				
				BX LR
		
				ALIGN
				END