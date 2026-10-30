;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Water Animation                       |
; | Filename:   water_animation.asm                                                 |
; -----------------------------------------------------------------------------------
;
; The animated sea, registered from room records and redrawn every frame.
;
Register_Water: DEC     HL              ; Step back from the source high byte to the record start
                EX      DE,HL           ; Keep the seven-byte record address in DE
                LD      A,(Water_Count) ; Read how many strips are already registered
                ADD     A,A             ; Each registration is a two-byte record address
                LD      C,A             ; Form the table offset in BC
                LD      B,0             ; The four-entry table needs only one offset byte
                LD      HL,Water_Records ; Locate the resident registration table
                ADD     HL,BC           ; Reach the next free entry
                LD      (HL),E          ; Store the record address's low byte
                INC     HL              ; Advance to its high byte
                LD      (HL),D          ; Complete the registration
                LD      A,(Water_Count) ; Recover the registration count
                INC     A               ; Count this strip
                LD      (Water_Count),A ; Room 1's two strips fit the four-entry table
                LD      HL,(Room_Next)  ; Skip this record in the authoritative background
                LD      DE,7            ; Every room draw record is seven bytes long
                ADD     HL,DE           ; Advance past the registered water record
                LD      (Room_Next),HL  ; Continue composing the remaining records
                LD      A,(Blocks_Left) ; Recover the remaining block count
                DEC     A               ; Count the registered strip as handled
                LD      (Blocks_Left),A ; Store the new count for the loop guard
                JP      Next_Block      ; Compose the next static record
;
Advance_Water:  LD      A,(Water_Timer) ; Count interrupts until the next wave frame is due
                DEC     A               ; Count this update
                LD      (Water_Timer),A ; LD preserves the DEC zero flag
                RET     NZ              ; Keep the same wave frame until the delay ends
                LD      A,Water_Delay   ; Restart the three-interrupt interval
                LD      (Water_Timer),A ; Store it for the following updates
                LD      A,(Water_Frame) ; Read the current wave frame, zero to three
                INC     A               ; Select the next frame
                AND     3               ; Wrap from frame three back to frame zero
                LD      (Water_Frame),A ; The next hidden-page drawing uses this frame
                RET                     ; Drawing happens with the sprite, on the hidden page only
;
Restore_Water:  LD      A,(Water_Count) ; Check whether this room registered any strips
                OR      A               ; Set Z when the room has no animated water
                RET     Z               ; Leave rooms without water untouched
                PUSH    IX              ; Callers may be iterating item records with IX
                LD      (Water_Left),A  ; Count the strips still to restore
                LD      HL,Water_Records ; Start at the first registration
                LD      (Water_Next),HL ; Keep the cursor resident across bank changes
Restore_Strip:  CALL    Next_Water      ; IX now addresses this strip's room draw record
                LD      L,(IX+2)        ; Read the strip's destination offset low byte
                LD      H,(IX+3)        ; Complete its screen offset
                LD      (Restore_Pointer),HL ; The scenery copier uses identical offsets
                LD      A,(IX+4)        ; Read the strip's visible byte width
                LD      (Restore_Width),A ; Restore exactly the bytes the strip covers
                LD      A,(IX+5)        ; Read the strip's visible height
                LD      (Restore_Rows),A ; Four rows for every source wave frame
                CALL    Restore_Background ; Copy water-free scenery; the target stays mapped
                LD      A,(Water_Left)  ; Recover the remaining strip count
                DEC     A               ; Count the strip just restored
                LD      (Water_Left),A  ; LD preserves the DEC zero flag
                JR      NZ,Restore_Strip ; Restore every registered strip
                POP     IX              ; Return the caller's record pointer
                RET                     ; The hidden page is ready for the sprite
;
Draw_Water:     LD      A,(Water_Count) ; Check whether this room registered any strips
                OR      A               ; Set Z when the room has no animated water
                RET     Z               ; Leave rooms without water untouched
                PUSH    IX              ; Preserve any caller's record pointer
                LD      (Water_Left),A  ; Count the strips still to draw
                LD      HL,Water_Records ; Start at the first registration
                LD      (Water_Next),HL ; Keep the cursor resident
Draw_Strip:     CALL    Next_Water      ; IX now addresses this strip's room draw record
                LD      HL,Water_Frames+2 ; Point past frame zero's dimensions header
                LD      DE,Water_Frame_Size ; Each later frame follows the previous one
                LD      A,(Water_Frame) ; Read which of the four frames is current
                OR      A               ; Frame zero needs no adjustment
                JR      Z,Water_Source_Ready ; Use frame zero's pixels directly
                LD      B,A             ; Count one frame size per frame index
Water_Frame_Step: ADD   HL,DE           ; Skip one complete 82-byte frame
                DJNZ    Water_Frame_Step ; Reach the selected frame's pixels
Water_Source_Ready: LD  E,(IX+2)        ; Read the strip's destination offset low byte
                LD      D,(IX+3)        ; Complete the hidden-page destination
                LD      C,(IX+5)        ; Count the strip's visible rows
Water_Row:      PUSH    BC              ; Preserve the row count
                PUSH    HL              ; Keep this source row's start
                PUSH    DE              ; Keep this destination row's start
                LD      B,(IX+4)        ; Count the strip's visible bytes on this row
Water_Byte:     LD      A,(HL)          ; Read two wave pixels as packed nibbles
                LD      C,A             ; Keep both nibbles while testing transparency
                AND     0xF0            ; Colour zero on the left is transparent
                JR      NZ,Water_Left_Opaque ; A visible left pixel replaces the screen pixel
                LD      A,(DE)          ; Read the pixel already on the hidden page
                AND     0xF0            ; Keep its left nibble, which may be Dizzy
                OR      C               ; Combine it with the wave's right nibble
                LD      C,A             ; Save the partially composed byte
Water_Left_Opaque: LD   A,C             ; Test the right nibble independently
                AND     0x0F            ; Colour zero on the right is transparent too
                JR      NZ,Water_Right_Opaque ; A visible right pixel replaces the screen pixel
                LD      A,(DE)          ; Read the pixel already on the hidden page
                AND     0x0F            ; Keep its right nibble
                OR      C               ; Combine it with the composed left nibble
                LD      C,A             ; Keep both final nibbles
Water_Right_Opaque: LD  A,C             ; Recover the composed byte
                LD      (DE),A          ; Store it on the hidden page
                INC     HL              ; Advance to the next source pair
                INC     DE              ; Advance across the screen row
                DJNZ    Water_Byte      ; Finish this visible row
                POP     HL              ; Recover the destination row start in HL
                LD      BC,128          ; MODE 4 rows are 128 bytes apart
                ADD     HL,BC           ; Reach the next destination row
                EX      DE,HL           ; Keep the destination in DE
                POP     HL              ; Recover the source row start
                LD      C,(IX+6)        ; Read the unclipped source stride
                LD      B,0             ; The stride fits in one byte
                ADD     HL,BC           ; Reach the next source row, even for the clipped strip
                POP     BC              ; Recover the row count
                DEC     C               ; Count the completed row
                JR      NZ,Water_Row    ; Draw every row in the strip
                LD      A,(Water_Left)  ; Recover the remaining strip count
                DEC     A               ; Count the strip just drawn
                LD      (Water_Left),A  ; LD preserves the DEC zero flag
                JR      NZ,Draw_Strip   ; Draw every registered strip
                POP     IX              ; Return the caller's record pointer
                RET                     ; The hidden frame is complete
;
Next_Water:     LD      HL,(Water_Next) ; Read the registration cursor
                LD      E,(HL)          ; Read the room record address low byte
                INC     HL              ; Advance to its high byte
                LD      D,(HL)          ; Complete the record address
                INC     HL              ; Advance to the following registration
                LD      (Water_Next),HL ; Keep the cursor for the next strip
                PUSH    DE              ; Move the record address
                POP     IX              ; Index its destination, width, height and stride fields
                RET                     ; IX now points at a seven-byte room draw record
;
Water_Count:    DEFB    0               ; Number of animated strips registered by Build_Room
Water_Records:  DEFS    8               ; Up to four room-record addresses; room 1 uses two
Water_Next:     DEFW    0               ; Registration cursor shared by restore and draw
Water_Left:     DEFB    0               ; Strips remaining in the current pass
Water_Frame:    DEFB    0               ; Current wave frame, zero to three
Water_Timer:    DEFB    Water_Delay     ; Interrupts left before the next wave frame
;
Water_Frames:                           ; Source graphics 55-58, each with its dimensions header
                MDAT    "assets\image-55.bin" ; Wave frame 0, also the static room record's graphic
                MDAT    "assets\image-56.bin" ; Wave frame 1
                MDAT    "assets\image-57.bin" ; Wave frame 2
                MDAT    "assets\image-58.bin" ; Wave frame 3
