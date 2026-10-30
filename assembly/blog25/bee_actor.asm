;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Bee Actor                             |
; | Filename:   bee_actor.asm                                                       |
; -----------------------------------------------------------------------------------
;
; The bee that patrols the fourth screen.
;
Advance_Bee:    LD      A,(Current_Room) ; Only the displayed room's actor moves
                CP      Bee_Room        ; Is the bee's room on screen?
                RET     NZ              ; Leave the bee where it is in other rooms
                LD      A,(Bee_Timer)   ; Count interrupts until the next game frame
                DEC     A               ; Count this update
                LD      (Bee_Timer),A   ; LD preserves the DEC zero flag
                RET     NZ              ; Not yet time to move
                LD      A,Actor_Delay   ; Restart the three-interrupt interval
                LD      (Bee_Timer),A   ; Store it for the following updates
                LD      A,(Bee_Flap)    ; Read which wing position is showing
                XOR     1               ; Swap wings up and wings down every move
                LD      (Bee_Flap),A    ; Keep the new wing position
                LD      A,(Bee_Velocity) ; Read the signed step: +1 right or -1 left
                LD      B,A             ; Keep it while updating X
                LD      A,(Bee_X)       ; Read the bee's byte X
                ADD     A,B             ; Move one byte, two pixels, along the patrol
                LD      (Bee_X),A       ; Store the new position
                CP      Bee_Min         ; Carry means X has passed the left bound
                JR      C,Bee_Reverse   ; Turn round at the left end
                CP      Bee_Max+1       ; Carry means X is still within the right bound
                JR      C,Bee_Pick_Frame ; Keep flying in the same direction
Bee_Reverse:    LD      A,B             ; Recover the step that crossed the bound
                NEG                     ; Reverse it: +1 becomes -1 and -1 becomes +1
                LD      (Bee_Velocity),A ; The next move heads back into the patrol range
Bee_Pick_Frame: LD      A,(Bee_Velocity) ; Frames 0-1 face right, frames 2-3 face left
                AND     2               ; +1 has bit 1 clear, -1 (255) has bit 1 set
                LD      B,A             ; B is 0 when flying right or 2 when flying left
                LD      A,(Bee_Flap)    ; Add the wing position, 0 or 1
                OR      B               ; Combine direction and wings into a frame index
                LD      (Bee_Frame),A   ; Drawing reads this index on the hidden page
                RET                     ; Drawing happens with the sprite, on the hidden page only
;
Bee_Old_Pointer: LD     HL,Bee_Old_10   ; Assume screen 10 is hidden
                LD      A,(Display_Page) ; Check which screen is being displayed
                CP      Screen_Page     ; If screen 10 is displayed, screen 14 is hidden
                RET     NZ              ; Screen 14 is displayed, so use screen 10's record
                INC     HL              ; Select screen 14's record instead
                RET                     ; HL addresses the hidden page's old bee X
;
Restore_Bee:    CALL    Bee_Old_Pointer ; Find where the bee was last drawn on this page
                LD      A,(HL)          ; Read that byte X
                CP      255             ; 255 means no bee is drawn on this page
                RET     Z               ; Nothing to erase
                LD      (HL),255        ; After restoring, this page holds no bee
                LD      E,A             ; Keep the old byte X in DE
                LD      D,0             ; Extend it to sixteen bits
                LD      A,Bee_Y         ; The bee always occupies the same rows
                CALL    Row_Address     ; HL = start of its top row
                ADD     HL,DE           ; Add the old byte X
                LD      (Restore_Pointer),HL ; Restore from the same offset in the scenery
                LD      A,Bee_Bytes     ; The bee is byte aligned, so 11 bytes cover it
                LD      (Restore_Width),A ; No extra byte is needed for odd pixels
                LD      A,Bee_Rows      ; Restore all 22 rows
                LD      (Restore_Rows),A ; Keep the count outside banked screen RAM
                JP      Restore_Background ; Copy the scenery back; the target stays mapped
;
Draw_Bee:       LD      A,(Current_Room) ; The bee is only drawn in its own room
                CP      Bee_Room        ; Is that room displayed?
                RET     NZ              ; Draw nothing anywhere else
                CALL    Bee_Old_Pointer ; Find this page's record
                LD      A,(Bee_X)       ; Read the position about to be drawn
                LD      (HL),A          ; Remember it so this page can erase it next time
                LD      HL,Bee_Frames+2 ; Point past frame zero's size header
                LD      DE,Bee_Frame_Size ; Each later frame follows the previous one
                LD      A,(Bee_Frame)   ; Read the frame index, zero to three
                OR      A               ; Frame zero needs no adjustment
                JR      Z,Bee_Source_Ready ; Use frame zero's pixels directly
                LD      B,A             ; Count one frame size per frame index
Bee_Frame_Step: ADD     HL,DE           ; Skip one complete 244-byte frame
                DJNZ    Bee_Frame_Step  ; Reach the selected frame's pixels
Bee_Source_Ready: PUSH  HL              ; Keep the source while finding the destination
                LD      A,Bee_Y         ; Read the bee's fixed top row
                CALL    Row_Address     ; HL = start of that screen row
                LD      A,(Bee_X)       ; Read the bee's byte X
                LD      E,A             ; Put it in DE
                LD      D,0             ; Extend it to sixteen bits
                ADD     HL,DE           ; HL = top-left destination byte
                EX      DE,HL           ; Keep the destination in DE
                POP     HL              ; Recover the source in HL
                LD      C,Bee_Rows      ; Draw all 22 rows
Bee_Row:        PUSH    BC              ; Preserve the row count
                PUSH    DE              ; Keep this destination row's start
                LD      B,Bee_Bytes     ; Draw 11 bytes on this row
Bee_Byte:       LD      A,(HL)          ; Read two bee pixels as packed nibbles
                LD      C,A             ; Keep both nibbles while testing transparency
                AND     0xF0            ; Colour zero on the left is transparent
                JR      NZ,Bee_Left_Opaque ; A visible left pixel replaces the screen pixel
                LD      A,(DE)          ; Read the scenery already on the hidden page
                AND     0xF0            ; Keep its left nibble
                OR      C               ; Combine it with the bee's right nibble
                LD      C,A             ; Save the partially composed byte
Bee_Left_Opaque: LD     A,C             ; Test the right nibble independently
                AND     0x0F            ; Colour zero on the right is transparent too
                JR      NZ,Bee_Right_Opaque ; A visible right pixel replaces the screen pixel
                LD      A,(DE)          ; Read the scenery already on the hidden page
                AND     0x0F            ; Keep its right nibble
                OR      C               ; Combine it with the composed left nibble
                LD      C,A             ; Keep both final nibbles
Bee_Right_Opaque: LD    A,C             ; Recover the composed byte
                LD      (DE),A          ; Store it on the hidden page
                INC     HL              ; Advance to the next source pair
                INC     DE              ; Advance across the screen row
                DJNZ    Bee_Byte        ; Finish this row
                POP     DE              ; Recover the destination row start
                EX      DE,HL           ; Put it in HL, keeping the source in DE
                LD      BC,128          ; MODE 4 rows are 128 bytes apart
                ADD     HL,BC           ; Reach the next destination row
                EX      DE,HL           ; Destination back in DE, source back in HL
                POP     BC              ; Recover the row count
                DEC     C               ; Count the completed row
                JR      NZ,Bee_Row      ; The source rows are contiguous, so HL is already correct
                RET                     ; The bee is on the hidden page
;
Bee_X:          DEFB    77              ; The source bee starts at byte X 77, pixel 154
Bee_Velocity:   DEFB    1               ; It starts flying right, one byte per game frame
Bee_Timer:      DEFB    Actor_Delay     ; Interrupts left before the next move
Bee_Flap:       DEFB    0               ; Wing position, 0 or 1
Bee_Frame:      DEFB    0               ; Selected frame: direction*2 + wing position
Bee_Old_10:     DEFB    255             ; Bee byte X last drawn on screen 10, 255 for none
Bee_Old_14:     DEFB    255             ; Bee byte X last drawn on screen 14, 255 for none
;
Bee_Frames:                             ; Source graphics 327-330, resident so they stay readable while a screen is mapped low
                MDAT    "assets\image-327.bin" ; Facing right, wings up
                MDAT    "assets\image-328.bin" ; Facing right, wings down
                MDAT    "assets\image-329.bin" ; Facing left, wings up
                MDAT    "assets\image-330.bin" ; Facing left, wings down
