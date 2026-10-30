;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Screen Paging                         |
; | Filename:   screen_paging.asm                                                   |
; -----------------------------------------------------------------------------------
;
; Paging memory into the lower window, copying scenery to the
; screens and flipping the display. The other files draw through these helpers.
;
Map_Lower:      LD      C,A             ; Save the requested physical page number
                LD      A,(Saved_LMPR) ; Retrieve the original register flags
                AND     0b11000000      ; Keep ROM1 and write-protection settings
                OR      0b00100000      ; Replace ROM0 with lower RAM
                OR      C               ; Insert the page number in bits 0-4
                OUT     (LMPR),A        ; Map the requested page and its successor
                RET                     ; Code and stack remain resident throughout
Restore_Lower:  LD      A,(Saved_LMPR) ; Retrieve the complete original lower mapping
                OUT     (LMPR),A        ; Make the ROM interrupt handler accessible again
                RET                     ; Return before the caller enables interrupts
;
Initialize_Screen:                      ; A selects the display pair that will receive scenery
                LD      (Target_Page),A ; Retain the destination while mapping background RAM
                LD      HL,0            ; Begin at the first background byte
                LD      (Restore_Pointer),HL ; Source and destination use identical screen offsets
                LD      A,128           ; A full MODE 4 row occupies 128 packed bytes
                LD      (Restore_Width),A ; Initialize the complete screen, not just a sprite
                LD      A,192           ; Copy all rows, including the reserved HUD region
                LD      (Restore_Rows),A ; Record the one-off initialization height
                JP      Restore_Background ; Use the same banked copier as rectangle restoration
Restore_Background:                     ; Copy a rectangle from authoritative scenery to one screen
                LD      A,Background_Page ; Select scenery, never a previously drawn display page
                CALL    Map_Lower       ; Make the immutable source pixels visible
                LD      HL,(Restore_Pointer) ; Locate the next rectangle row in that source
                LD      DE,Background_Row ; Stage bytes outside the banked window
                LD      A,(Restore_Width) ; Read this rectangle's packed-byte width
                LD      C,A             ; Use BC as the byte count for LDIR
                LD      B,0             ; Width never exceeds 128 bytes
                LDIR                    ; Preserve the row before paging the source away
                LD      A,(Target_Page) ; Recover the chosen physical drawing screen
                CALL    Map_Lower       ; Map that screen without changing the displayed page
                LD      HL,Background_Row ; Read the resident scenery row
                LD      DE,(Restore_Pointer) ; Destination offsets match the source bitmap
                LD      A,(Restore_Width) ; Read the same width for the destination copy
                LD      C,A             ; Set the low byte of the copy length
                LD      B,0             ; Keep the count in the range 1-128
                LDIR                    ; Replace old sprite bytes with original scenery
                LD      HL,(Restore_Pointer) ; Recover the row's start rather than its end
                LD      DE,128          ; Advance by the screen stride, not rectangle width
                ADD     HL,DE           ; Reach the following rectangle row
                LD      (Restore_Pointer),HL ; Retain its address across bank changes
                LD      A,(Restore_Rows) ; Recover the number of rows remaining
                DEC     A               ; Count the completed row
                LD      (Restore_Rows),A ; LD preserves the DEC zero flag
                JR      NZ,Restore_Background ; Restore every row in the old rectangle
                RET                     ; Leave the target screen mapped for the following draw
;
Show_Pending_Frame:                     ; Display only a fully completed hidden frame
                LD      A,(Frame_Pending) ; Check whether a complete drawing is waiting
                OR      A               ; Set Z when there is nothing to display
                RET     Z               ; Keep the current screen in that case
                XOR     A               ; Prepare a zero to acknowledge the frame
                LD      (Frame_Pending),A ; Consume the completed drawing
                LD      A,(Display_Page) ; Get the screen currently displayed
                XOR     4               ; Exchange physical starting pages 10 and 14
                LD      (Display_Page),A ; Record the newly displayed page
                OR      0x60            ; Keep the display in MODE 4
                OUT     (VMPR),A        ; Display the completed hidden screen
                RET                     ; The old displayed page is now available for drawing
