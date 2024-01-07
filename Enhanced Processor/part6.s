.define LED_ADDRESS 0x10	
.define SW_ADDRESS 0x30
             mvt     r0, #LED_ADDRESS//leds
             mvt     r1, #SW_ADDRESS//sw
             mv     r2, #0 //count
	

DISPLAY: 
             st     r2, [r0]
             mvt     r1, #SW_ADDRESS//sw
             ld     r1, [r1]
DELAY:
             mvt     r3, #0xF
             add     r3, #0xFF
             mv     r1, r1
             beq     LOOP
             and     r1, #0x2
             beq     SLOWER
             //go faster
             mvt     r3, #0x9
	
	
LOOP:
             sub     r3, #1
             bne     LOOP
INCR: 
             add     r2, #1
             b     DISPLAY

SLOWER:
             mvt     r3, #0x1F
             add     r3, #0xFF
             b     LOOP
	
