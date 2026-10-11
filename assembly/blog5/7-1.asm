;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 7 - Part 1: Keyboard Control             |
; | Filename:   blog5\7-1.asm                                                       |
; | Based on:   Tutorial 6 part 4 (blog4\6-4.asm)                                   |
; -----------------------------------------------------------------------------------
;
; The flicker-free animation from Tutorial 6 now reacts to the keyboard. Press any
; key to play the jump sequence once; Dizzy then returns to the idle sequence.
; The keyboard is read straight from port 0xFE. Reset to stop the demo.
;
; ***********************************************************************************
; *                                 Program Setup                                   *
; ***********************************************************************************
;
                ORG     0x8000
                DUMP    1,0
                AUTOEXEC
;
LMPR:           EQU     250             ; Lower Memory Page Register
VMPR:           EQU     252             ; Video Memory Page Register
JCLSBL:         EQU     334             ; ROM clear-screen routine
;
Frame_Delay:    EQU     5               ; Hold each frame for five 50 Hz interrupts
;
; ***********************************************************************************
; *                                Application Start                                *
; ***********************************************************************************
;
Start:          DI                      ; Disable interrupts
                LD      (System_SP+1),SP; Save BASIC's stack pointer before paging screen RAM
                CALL    Clear_Screen    ; Clear the displayed screen while the ROM is paged in
                DI                      ; Disable interrupts before paging screen RAM
                IN      A,(VMPR)        ; Read the current screen page
                AND     0b00011110      ; Keep only the page number
                LD      (Display_Page),A ; This page is the one being displayed
                LD      SP,0xFF00       ; Use a safe stack above the program and its 24 frames
                CALL    Clear_Hidden_Page ; Blank the page we will draw on
;
                LD      HL,Idle_Animation ; Start with the idle sequence
                CALL    Set_Animation   ; Draw the first frame on the hidden page
;
Animation_Loop: HALT                    ; Wait for the next 50 Hz interrupt
                CALL    Show_Pending_Frame ; Swap pages if a new frame is ready
                CALL    Choose_Animation ; Idle or jump, depending on the keyboard
                CALL    Update_Animation ; Change frame when the delay expires
                JR      Animation_Loop  ; Repeat forever
;
Exit:           DI                      ; Not reached while the loop runs, kept from 5.asm
System_SP:      LD      SP,0            ; Restore BASIC's original stack pointer
                EI                      ; Enable interrupts
                RET                     ; Return to BASIC
;
Clear_Screen:   XOR     A               ; Clear the A register to clear the full screen
                CALL    JCLSBL          ; Call the system clear-screen routine
                DI                      ; Disable interrupts before continuing
                RET                     ; Return to the caller
;
; The ROM only clears the displayed screen, so we blank the hidden page ourselves.
; A MODE 4 screen is 24 KB, so we clear the first 0x6000 bytes of the paged-in RAM.
;
Clear_Hidden_Page:
                LD      A,(Display_Page)
                XOR     0b00000100      ; Select the page that is not displayed
                OR      0b00100000      ; Map RAM into the lower memory area
                OUT     (LMPR),A        ; Page the hidden screen RAM in
                LD      HL,0
                LD      DE,1
                LD      BC,0x5FFF
                LD      (HL),0          ; Colour zero, as the ROM clear uses
                LDIR                    ; Fill the rest of the screen with zeros
                LD      A,0x1F          ; Page ROM 0 back into the lower memory area
                OUT     (LMPR),A
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                         Show a Finished Frame (Page Flip)                       *
; ***********************************************************************************
; Only swap pages once a complete frame has been drawn on the hidden page.
;
Show_Pending_Frame:
                LD      A,(Frame_Pending)
                OR      A
                RET     Z               ; Nothing new to show
                XOR     A
                LD      (Frame_Pending),A
                LD      A,(Display_Page)
                XOR     0b00000100      ; The hidden page becomes the displayed page
                LD      (Display_Page),A
                OR      0b01100000      ; Keep MODE 4
                OUT     (VMPR),A        ; Display the finished frame in a single step
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                           Choose and Update the Animation                       *
; ***********************************************************************************
;
Choose_Animation:
                LD      HL,(Current_Animation)
                LD      DE,Idle_Animation
                OR      A               ; Clear the carry flag
                SBC     HL,DE
                RET     NZ              ; A jump is playing, so ignore the keyboard
                LD      BC,0x00FE       ; Select every keyboard row at once (port 0xFE)
                IN      A,(C)           ; A bit is 0 when its key is down
                OR      0b11100000      ; Ignore the top three bits
                INC     A               ; 0xFF (no key down) becomes zero
                RET     Z               ; No key, so keep idling
                LD      HL,Jump_Animation ; A key was pressed, so play the jump once
;
Set_Animation:  LD      (Current_Animation),HL
                XOR     A               ; Start from the first frame
                LD      (Current_Frame),A
                LD      A,Frame_Delay
                LD      (Current_Delay),A
                JR      Draw_Frame      ; Draw the first frame straight away
;
Update_Animation:
                LD      A,(Current_Delay) ; Count down the frame delay
                DEC     A
                LD      (Current_Delay),A
                RET     NZ              ; Only redraw when the delay expires
;
                LD      A,Frame_Delay   ; Restart the frame delay
                LD      (Current_Delay),A
                LD      HL,(Current_Animation)
                LD      B,(HL)          ; The first byte is the number of frames
                LD      A,(Current_Frame)
                INC     A
                CP      B
                JR      C,Store_Frame   ; Still inside the sequence
                LD      HL,(Current_Animation)
                LD      DE,Jump_Animation
                OR      A               ; Clear the carry flag
                SBC     HL,DE
                LD      HL,Idle_Animation
                JR      Z,Set_Animation ; The jump has finished, so go back to idle
                XOR     A               ; The idle loops, so return to frame zero
;
Store_Frame:    LD      (Current_Frame),A
                ; Fall through to draw the new frame
;
; ***********************************************************************************
; *                         Draw the Current Frame (Hidden Page)                    *
; ***********************************************************************************
;
Draw_Frame:     DI                      ; Interrupts stay off while screen RAM is paged in
                LD      A,(Display_Page)
                XOR     0b00000100      ; Always draw on the page that is not displayed
                OR      0b00100000      ; Map RAM into the lower memory area
                OUT     (LMPR),A        ; Page the hidden screen RAM into the lower memory area
;
                CALL    Clear_Sprite    ; Remove the old frame left on this page
;
                LD      A,(Current_Frame)
                LD      E,A
                LD      D,0
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count byte
                ADD     HL,DE
                ADD     HL,DE           ; Each frame pointer occupies two bytes
                LD      E,(HL)
                INC     HL
                LD      D,(HL)          ; DE now points to the selected frame data
                LD      HL,0            ; Top-left screen byte, as in Tutorial 5
                CALL    Draw_Sprite     ; Draw the frame using the mask/pixel data
;
                LD      A,0x1F          ; Page ROM 0 back into the lower memory area
                OUT     (LMPR),A        ; The ROM's interrupt handler is needed by HALT
                LD      A,1
                LD      (Frame_Pending),A ; Tell the main loop a frame is ready to show
                EI                      ; Enable interrupts
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                         Clear the Sprite's Screen Rectangle                     *
; ***********************************************************************************
;
Clear_Sprite:   LD      HL,0            ; Top-left screen byte
                LD      C,32            ; Clear all 32 sprite rows
;
Clear_Row:      LD      B,16            ; 16 screen bytes per row
;
Clear_Byte:     LD      (HL),0          ; Colour zero is the blank background
                INC     HL              ; Advance to the next screen byte
                DJNZ    Clear_Byte      ; Continue across the 16-byte row
                LD      DE,112          ; Skip the rest of the 128-byte screen row
                ADD     HL,DE           ; Point to the next screen row
                DEC     C               ; Count down the rows
                JR      NZ,Clear_Row    ; Continue until all 32 rows are cleared
                RET                     ; Return after clearing the rectangle
;
; ***********************************************************************************
; *                               Draw Masked Sprite                                *
; ***********************************************************************************
;
Draw_Sprite:    LD      C,32             ; Process all 32 sprite rows
;
Sprite_Row:     PUSH    BC              ; Preserve row count while B counts bytes
                LD      B,16             ; Process the 16 sprite bytes in this row
;
Sprite_Byte:    LD      A,(DE)           ; Read the mask byte
                AND     (HL)            ; Keep screen bits selected by the mask
                LD      C,A             ; Save the masked background byte
                INC     DE              ; Point to the corresponding pixel byte
                LD      A,(DE)           ; Read the cleaned sprite pixels
                OR      C               ; Combine sprite pixels with the background
                LD      (HL),A          ; Write the combined byte to the screen
                INC     DE              ; Point to the next mask/pixel pair
                INC     HL              ; Advance to the next screen byte
                DJNZ    Sprite_Byte     ; Continue across the 16-byte sprite row
                LD      BC,112          ; Skip the rest of the 128-byte screen row
                ADD     HL,BC           ; Point to the next screen row
                POP     BC              ; Restore the sprite row counter
                DEC     C               ; Count down the sprite rows
                JR      NZ,Sprite_Row   ; Continue until all 32 rows are drawn
                RET                     ; Return after drawing the sprite
;
; ***********************************************************************************
; *                               Animation Data                                    *
; ***********************************************************************************
;
Current_Animation: DEFW 0               ; Address of the sequence being played
Current_Frame:  DEFB    0               ; Index into the current sequence
Current_Delay:  DEFB    0               ; Interrupts left before the next frame
Display_Page:   DEFB    0               ; Screen page currently being displayed
Frame_Pending:  DEFB    0               ; Set when the hidden page holds a finished frame
;
; Each sequence starts with its frame count, followed by the frame addresses.
;
Idle_Animation: DEFB    2
                DEFW    Dizzy_System_Interleaved_Image1,Dizzy_System_Interleaved_Image2
;
Jump_Animation: DEFB    8
                DEFW    Dizzy_System_Interleaved_Image1,Dizzy_System_Interleaved_Image3
                DEFW    Dizzy_System_Interleaved_Image4,Dizzy_System_Interleaved_Image5
                DEFW    Dizzy_System_Interleaved_Image6,Dizzy_System_Interleaved_Image7
                DEFW    Dizzy_System_Interleaved_Image8,Dizzy_System_Interleaved_Image9
;
; The nine interleaved frames come from the Sprite Editor output.
;
                INCLUDE "dizzy_system_interleaved.asm"
