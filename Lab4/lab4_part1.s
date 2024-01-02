               .equ      EDGE_TRIGGERED,    0x1
               .equ      LEVEL_SENSITIVE,   0x0
               .equ      CPU0,              0x01    // bit-mask; bit 0 represents cpu0
               .equ      ENABLE,            0x1

               .equ      KEY0,              0b0001
               .equ      KEY1,              0b0010
               .equ      KEY2,              0b0100
               .equ      KEY3,              0b1000

               .equ      IRQ_MODE,          0b10010
               .equ      SVC_MODE,          0b10011

               .equ      INT_ENABLE,        0b01000000
               .equ      INT_DISABLE,       0b11000000
/*********************************************************************************
 * Initialize the exception vector table
 ********************************************************************************/
                .section .vectors, "ax"

                B        _start             // reset vector
                .word    0                  // undefined instruction vector
                .word    0                  // software interrrupt vector
                .word    0                  // aborted prefetch vector
                .word    0                  // aborted data vector
                .word    0                  // unused vector
                B        IRQ_HANDLER        // IRQ interrupt vector
                .word    0                  // FIQ interrupt vector

/*********************************************************************************
 * Main program
 ********************************************************************************/
                .text
                .global  _start
_start:        
                /* Set up stack pointers for IRQ and SVC processor modes */
                
				
				//IRQ MODE SP
				MOV		R0, #0b11010010   
				MSR		CPSR_c, R0
				LDR		SP, =0x40000
				
				//SVC MODE SP
				MOV		R0, #0b11010011 
				MSR		CPSR, R0
				LDR		SP, =0x20000
		

                BL       CONFIG_GIC              // configure the ARM generic interrupt controller

                // Configure the KEY pushbutton port to generate interrupts
                LDR		R0, =0xFF200050
				MOV		R1, #0xF
				STR		R1, [R0, #0x8]
				
				

                // enable IRQ interrupts in the processor
                MOV		R1, #0b01010011
				MSR		CPSR_c, R1
				
IDLE:
                B        IDLE                    // main program simply idles

IRQ_HANDLER:
                PUSH     {R0-R7, LR}
    
                /* Read the ICCIAR in the CPU interface */
                LDR      R4, =0xFFFEC100
                LDR      R5, [R4, #0x0C]         // read the interrupt ID

CHECK_KEYS:
                CMP      R5, #73
UNEXPECTED:     BNE      UNEXPECTED              // if not recognized, stop here
    
                BL       KEY_ISR
EXIT_IRQ:
                /* Write to the End of Interrupt Register (ICCEOIR) */
                STR      R5, [R4, #0x10]
    
                POP      {R0-R7, LR}
                SUBS     PC, LR, #4

/*****************************************************0xFF200050***********************************
 * Pushbutton - Interrupt Service Routine                                
 *                                                                          
 * This routine checks which KEY(s) have been pressed. It writes to HEX3-0
 ***************************************************************************************/
                .global  KEY_ISR
KEY_ISR:	
				PUSH	{LR}
				LDR		R3, =0xFF200000 //R3 gets general IO address 
				LDR		R2, [R3, #0x5C] //load button edge
				STR		R2, [R3, #0x5C] //clear interrupt
				MOV		R1, #0
				LDR		R0, [R3, #0x20] //check whats on hex right now		
				
				CMP		R2, #1
				BLEQ	DISPLAY_ZERO //check if key 0
				
				CMP		R2, #2
				BLEQ	DISPLAY_ONE//check if key 1
				
				CMP		R2, #4
				BLEQ	DISPLAY_TWO//key two
				
				CMP		R2, #8
				BLEQ	DISPLAY_THREE//key three
				
				
                POP		{PC}

//ands the register with all 0s except ones 
//where I want to determine if there is a pattern or not already to determine if i
//will blank or display
//Display zero stuff has comments others dont because its redundant
DISPLAY_ZERO:	PUSH 	{LR}
				MOV		R2, R0	
				AND		R2, R2, #0xff //and with 0s and 8 1s to get pattern
				CMP		R2, #0x3f //the pattern exists
				BLEQ	BLANK_ZERO //lets blank it oiut
				
				CMP		R2, #0x0 //its already blank
				BLEQ	DIS_ZERO //lets display it

				POP		{PC}

DISPLAY_ONE:	PUSH	{LR}
				MOV		R2, R0
				AND		R2, R2, #0xff00
				CMP		R2, #0x600
				BLEQ	BLANK_ONE
				
				CMP		R2, #0x0
				BLEQ	DIS_ONE

				POP		{PC}

DISPLAY_TWO:	PUSH	{LR}
				MOV		R2, R0
				AND		R2, R2, #0xff0000
				CMP		R2, #0x5b0000
				BLEQ	BLANK_TWO
				
				CMP		R2, #0x0
				BLEQ	DIS_TWO

				POP		{PC}

DISPLAY_THREE:	PUSH	{LR}
				MOV		R2, R0
				AND		R2, R2, #0xff000000
				CMP		R2, #0x4f000000
				BLEQ	BLANK_THREE
				
				CMP		R2, #0x0
				BLEQ	DIS_THREE

				POP		{PC}

BLANK_ZERO:		LSR		R0, #8  //shift the bits out and back in to clear whats 
//in the right most (HEX0Bits) area, i change this later for a more effective means
//but shifting out the bits is viable for things in the corners
				LSL		R0, #8	
				STR		R0, [R3, #0x20]
				MOV		PC,LR

DIS_ZERO:		MOV		R2, #0b00111111 //not blank
				ORR		R0, R2 //orr the pattern into the complete pattern
				STR		R0, [R3, #0x20] //display it
				MOV		PC,LR
				
BLANK_ONE:		MOV		R2, #0xffff00ff //and the pattern with all 1s and 0s where i
				//want to get rid of (blank it out) in this case in the 1s bits
				AND		R0, R2, R0
				STR		R0, [R3, #0x20]
				MOV		PC,LR

DIS_ONE:		MOV		R2, #0x600
				ORR		R0, R2, R0
				STR		R0, [R3, #0x20]
				MOV		PC,LR
				
BLANK_TWO:		MOV		R2, #0xff00ffff
				AND		R0, R2, R0
				STR		R0, [R3, #0x20]
				MOV		PC,LR

DIS_TWO:		MOV		R2, #0x5b0000
				ORR		R0, R2, R0
				STR		R0, [R3, #0x20]
				MOV		PC,LR
				
BLANK_THREE:	MOV		R2, #0x00ffffff
				AND		R0, R2, R0
				STR		R0, [R3, #0x20]
				MOV		PC,LR

DIS_THREE:		MOV		R2, #0x4f000000
				ORR		R0, R2, R0
				STR		R0, [R3, #0x20]
				MOV		PC,LR

/* 
 * Configure the Generic Interrupt Controller (GIC)
*/
                .global  CONFIG_GIC
CONFIG_GIC:
                PUSH     {LR}
                /* Enable the KEYs interrupts */
                MOV      R0, #73
                MOV      R1, #CPU0
                /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
                BL       CONFIG_INTERRUPT

                /* configure the GIC CPU interface */
                LDR      R0, =0xFFFEC100        // base address of CPU interface
                /* Set Interrupt Priority Mask Register (ICCPMR) */
                LDR      R1, =0xFFFF            // enable interrupts of all priorities levels
                STR      R1, [R0, #0x04]
                /* Set the enable bit in the CPU Interface Control Register (ICCICR). This bit
                 * allows interrupts to be forwarded to the CPU(s) */
                MOV      R1, #1
                STR      R1, [R0]
    
                /* Set the enable bit in the Distributor Control Register (ICDDCR). This bit
                 * allows the distributor to forward interrupts to the CPU interface(s) */
                LDR      R0, =0xFFFED000
                STR      R1, [R0]    
    
                POP      {PC}

/* 
 * Configure registers in the GIC for an individual interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and Interrupt 
 * Processor Target Registers (ICDIPTRn). The default (reset) values are used for 
 * other registers in the GIC
 * Arguments: R0 = interrupt ID, N
 *            R1 = CPU target
*/
CONFIG_INTERRUPT:
                PUSH     {R4-R5, LR}
    
                /* Configure Interrupt Set-Enable Registers (ICDISERn). 
                 * reg_offset = (integer_div(N / 32) * 4
                 * value = 1 << (N mod 32) */
                LSR      R4, R0, #3               // calculate reg_offset
                BIC      R4, R4, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED100
                ADD      R4, R2, R4               // R4 = address of ICDISER
    
                AND      R2, R0, #0x1F            // N mod 32
                MOV      R5, #1                   // enable
                LSL      R2, R5, R2               // R2 = value

                /* now that we have the register address (R4) and value (R2), we need to set the
                 * correct bit in the GIC register */
                LDR      R3, [R4]                 // read current register value
                ORR      R3, R3, R2               // set the enable bit
                STR      R3, [R4]                 // store the new register value

                /* Configure Interrupt Processor Targets Register (ICDIPTRn)
                  * reg_offset = integer_div(N / 4) * 4
                  * index = N mod 4 */
                BIC      R4, R0, #3               // R4 = reg_offset
                LDR      R2, =0xFFFED800
                ADD      R4, R2, R4               // R4 = word address of ICDIPTR
                AND      R2, R0, #0x3             // N mod 4
                ADD      R4, R2, R4               // R4 = byte address in ICDIPTR

                /* now that we have the register address (R4) and value (R2), write to (only)
                 * the appropriate byte */
                STRB     R1, [R4]
    
                POP      {R4-R5, PC}

                .end   
