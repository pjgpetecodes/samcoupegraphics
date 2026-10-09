;
; -----------------------------------------------------------------------------------
; |                                                                                 |
; | Program:    SAM Coupe Sprites Tutorial 1 - Part 0                               |
; | Filename:   Sprites0.asm                                                        |
; | Version:    1.0                                                                 |
; | Date:       12/10/2017                                                          |
; | Author:     Pete Gallagher - PJG Creations Ltd                                  |
; |                                                                                 |
; -----------------------------------------------------------------------------------
;
                autoexec		        ; Automatically Execute the Program
		        ORG 	32768		    ; Store the program in User Address Space
;
; Our Equates
;
LMPR:           EQU     250             ; The Lower Memory Page Register Address 
HMPR:           EQU     251             ; The Higher Memory Page Register Address 
VMPR:           EQU     252             ; The Video Memory Page Register Address 
;
; Get the Current Screen Page and set the LMPR register up so we can write to the screen
;
                IN      A,(VMPR)        ; Get the VMPR Register, which holds info about...
                                        ; ... which Page the Screen is Paged Into
                AND     0B00011110      ; We're only interested in the Screen Page, so mask off everything but the Page Bits...
                                        ; ... The result will be stored in the A Register
                OR      0B00100000      ; Set Bit 5 which, when loaded into the LMPR register, will Set the RAM in Page 0
                OUT     (LMPR),A        ;
;
; Print a sprite in the top left corner
;
                LD      HL,0x0000       ; Point to the Top Left corner of our screen
                LD      (HL),0xFF       ; Set the colour of this pixel

                LD      HL,0x0080       ; 
                LD      (HL),0x44       ; Set the colour of this pixel

                LD      HL,0x0001       ; 
                LD      (HL),0xFF       ; Set the colour of this pixel

                LD      HL,0x0081       ; 
                LD      (HL),0x44       ; Set the colour of this pixel

                LD      HL,0x0100       ; 
                LD      (HL),0xFF       ; Set the colour of this pixel

                LD      HL,0x0180       ; 
                LD      (HL),0x44       ; Set the colour of this pixel

                LD      HL,0x0101       ; 
                LD      (HL),0xFF       ; Set the colour of this pixel

                LD      HL,0x0181       ; 
                LD      (HL),0x44       ; Set the colour of this pixel                
;
; We must remember to switch BASIC back into Page 0
;
                LD      A,0x1f          ;
                OUT     (LMPR), A       ;
;
; Exit back to BASIC
;
                RET                     ;