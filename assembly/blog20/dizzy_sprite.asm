;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Dizzy Sprite                          |
; | Filename:   dizzy_sprite.asm                                                    |
; -----------------------------------------------------------------------------------
;
; Dizzy's animations, odd-pixel shifting and masked drawing.
;
Build_Odd_Frame: LD     HL,Frame_Buffer ; Read the staged 13-byte-wide interleaved frame
                LD      DE,Odd_Frame_Buffer ; Write its one-pixel-shifted 14-byte rows
                LD      C,Sprite_Rows   ; Convert every row into its padded destination form
Build_Odd_Row:  PUSH    BC              ; Preserve the row count while C counts source pairs
                LD      A,(HL)          ; Read the first source mask byte
                LD      (Previous_Mask),A ; Retain it while composing the first output byte
                INC     HL              ; Advance to the matching source pixel byte
                LD      A,(HL)          ; Read the first source pixel byte
                LD      (Previous_Pixel),A ; Retain it for the first shifted pixel byte
                INC     HL              ; Advance to the second source mask byte
                LD      A,(Previous_Mask) ; Fetch the first mask pair
                RRCA                    ; Rotate its original high nibble into the low nibble
                RRCA                    ; Complete the four-bit alignment change
                RRCA                    ; Preserve both source nibbles for the next byte
                RRCA                    ; The original high nibble is now in the low nibble
                AND     0x0F            ; Keep only the source pixel's mask nibble
                OR      0xF0            ; Make the leading off-sprite nibble transparent
                LD      (DE),A          ; Store the leading shifted mask byte
                INC     DE              ; Advance to the paired shifted pixel byte
                LD      A,(Previous_Pixel) ; Fetch the first source pixel pair
                RRCA                    ; Move its original high nibble into the low nibble
                RRCA                    ; Rotate four places without losing either nibble
                RRCA                    ; Keep the first source pixel in the low nibble
                RRCA                    ; The leading destination nibble remains zero
                AND     0x0F            ; Discard the transparent source pixel nibble
                LD      (DE),A          ; Store the leading shifted pixel byte
                INC     DE              ; Advance to the next output mask
                LD      C,Sprite_Bytes-1 ; Twelve pairs remain between the leading and trailing bytes
Build_Odd_Pair: LD      A,(HL)          ; Read the next source mask byte
                LD      (Next_Mask),A   ; Save it while the shifted byte is composed
                RRCA                    ; Move the new source high nibble into the low nibble
                RRCA                    ; Complete half of the nibble rotation
                RRCA                    ; Keep the original high nibble available
                RRCA                    ; Put that nibble in the low half of A
                AND     0x0F            ; Isolate the next source mask nibble
                LD      B,A             ; Keep it while shifting the previous low nibble
                LD      A,(Previous_Mask) ; Read the previous source mask byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Keep the previous low nibble available
                RLCA                    ; Put that nibble in the high half of A
                AND     0xF0            ; Isolate the previous source mask nibble
                OR      B               ; Join adjacent source nibbles in destination order
                LD      (DE),A          ; Store one complete shifted mask byte
                INC     DE              ; Advance to the paired shifted pixel byte
                INC     HL              ; Advance to the matching source pixel byte
                LD      A,(HL)          ; Read the next source pixel byte
                LD      (Next_Pixel),A  ; Save it while composing the shifted pixel
                RRCA                    ; Move the next source high nibble into the low nibble
                RRCA                    ; Complete half of the nibble rotation
                RRCA                    ; Isolate the next source pixel
                RRCA                    ; Its high nibble now occupies the low nibble
                AND     0x0F            ; Keep only that next source pixel nibble
                LD      B,A             ; Preserve it while shifting the previous pixel
                LD      A,(Previous_Pixel) ; Read the previous source pixel byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Keep the previous source pixel available
                RLCA                    ; Its low nibble now occupies the high nibble
                AND     0xF0            ; Keep only that previous source pixel nibble
                OR      B               ; Join the two adjacent sprite pixels
                LD      (DE),A          ; Store one complete shifted pixel byte
                INC     DE              ; Advance to the next shifted mask byte
                INC     HL              ; Advance to the next source mask byte
                LD      A,(Next_Mask)   ; Retain the current mask for the following output
                LD      (Previous_Mask),A ; It becomes the preceding source mask byte
                LD      A,(Next_Pixel)  ; Retain the current pixel for the following output
                LD      (Previous_Pixel),A ; It becomes the preceding source pixel byte
                DEC     C               ; Count the twelve interior destination pairs
                JR      NZ,Build_Odd_Pair ; Continue until the last source pair is retained
                LD      A,(Previous_Mask) ; Read the final source mask byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Preserve the final source mask nibble
                RLCA                    ; The last source nibble now occupies the high half
                AND     0xF0            ; Keep the final source mask nibble
                OR      0x0F            ; Mark the trailing off-sprite nibble transparent
                LD      (DE),A          ; Store the trailing shifted mask byte
                INC     DE              ; Advance to the paired shifted pixel byte
                LD      A,(Previous_Pixel) ; Read the final source pixel byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Preserve the final source pixel nibble
                RLCA                    ; The last source pixel now occupies the high half
                AND     0xF0            ; Leave the trailing off-sprite nibble zero
                LD      (DE),A          ; Store the trailing shifted pixel byte
                INC     DE              ; Finish the 14-byte destination row
                POP     BC              ; Recover the remaining source-row count
                DEC     C               ; Count this completed row
                JR      NZ,Build_Odd_Row ; Convert the next 13-byte source row
                RET                     ; Odd_Frame_Buffer now contains all 22 shifted rows
;
Choose_Animation:                       ; Keep animation selection separate from movement
                LD      A,(Grounded)    ; Keep the active jump image while airborne
                OR      A               ; Animation timing must not decide when landing occurs
                RET     Z               ; Ground contact will switch back to walking or idle
Choose_Walk:    LD      BC,0xFEFE       ; Select the direction-key row
                IN      A,(C)           ; Read Z and X
                LD      HL,Walk_Left_Animation ; Prepare the left-walk sequence
                BIT     1,A             ; Test Z
                JR      Z,Change_Animation ; Start or continue walking left
                LD      HL,Walk_Right_Animation ; Otherwise prepare walking right
                BIT     2,A             ; Test X
                JR      Z,Change_Animation ; Start or continue walking right
                LD      HL,Idle_Animation ; Neither direction held selects idle
Change_Animation:                       ; Compare the proposed sequence with the active one
                LD      DE,(Current_Animation) ; Read the active sequence address
                OR      A               ; Clear carry for the address comparison
                PUSH    HL              ; Preserve the proposed sequence
                SBC     HL,DE           ; Set Z when the two sequence addresses match
                POP     HL              ; Restore the proposal without changing Z
                RET     Z               ; Do not restart the same animation repeatedly
Set_Animation:  LD      (Current_Animation),HL ; Store the newly selected sequence
                XOR     A               ; Prepare the first frame index
                LD      (Current_Frame),A ; Start at frame zero
                LD      A,Frame_Delay   ; Fetch the five-interrupt frame duration
                LD      (Current_Delay),A ; Begin that delay
                JR      Draw_Frame      ; Draw the first frame immediately
Update_Animation:                       ; Advance animation at its own five-interrupt cadence
                LD      A,(Current_Delay) ; Read the remaining frame duration
                DEC     A               ; Count this interrupt
                LD      (Current_Delay),A ; Preserve DEC's zero flag while storing
                RET     NZ              ; Do not advance animation before the delay ends
                LD      A,Frame_Delay   ; Prepare another five-interrupt interval
                LD      (Current_Delay),A ; Start the next interval
                LD      HL,(Current_Animation) ; Find the sequence's frame count
                LD      B,(HL)          ; Keep the number of frames in B
                LD      A,(Current_Frame) ; Read the current index
                INC     A               ; Propose the next frame
                CP      B               ; Check whether it is still within the table
                JR      C,Store_Frame   ; Carry means the index is below the frame count
                INC     HL              ; At the sequence end, reach the loop flag
                LD      A,(HL)          ; Read whether the sequence loops
                OR      A               ; Set Z for a sequence which plays once
                LD      HL,Idle_Animation ; Prepare idle without changing Z
                JR      Z,Set_Animation ; Finish a roll or jump by returning to idle
                XOR     A               ; Loop a repeating sequence back to frame zero
Store_Frame:    LD      (Current_Frame),A ; Store the index and fall through to redraw
;
Draw_Frame:     DI                      ; Keep interrupts disabled while lower RAM is mapped
                LD      A,(Current_Frame) ; Find the selected frame index
                LD      E,A             ; Put it in the low byte of DE
                LD      D,0             ; Extend it to sixteen bits
                LD      HL,(Current_Animation) ; Find the active resident frame table
                INC     HL              ; Skip the frame count
                INC     HL              ; Skip the loop flag
                ADD     HL,DE           ; Add the index once
                ADD     HL,DE           ; Double it for two-byte frame pointers
                LD      E,(HL)          ; Read the frame pointer's low byte
                INC     HL              ; Advance to its high byte
                LD      D,(HL)          ; Complete the lower-window frame address
                EX      DE,HL           ; Give LDIR its source pointer in HL
                LD      (Frame_Source),HL ; Retain the selected pointer while checking the cache
                LD      DE,(Cached_Frame) ; Read which animation frame is already staged
                OR      A               ; Clear carry before comparing the two addresses
                SBC     HL,DE           ; Set Z when this frame's source is already cached
                JR      Z,Frame_Ready   ; Reuse both resident buffers while the image is unchanged
                LD      HL,(Frame_Source) ; Restore the selected banked-frame address
                LD      A,Sprite_Page   ; Select physical sprite pages 4 and 5
                CALL    Map_Lower       ; Make the selected frame visible
                LD      DE,Frame_Buffer ; Stage the frame in resident memory
                LD      BC,Frame_Size   ; Copy its complete mask/pixel data
                LDIR                    ; Copy across a 16 KB boundary if necessary
                CALL    Build_Odd_Frame ; Prepare a one-pixel-shifted copy for odd X positions
                LD      HL,(Frame_Source) ; Recover the address of the frame just staged
                LD      (Cached_Frame),HL ; Avoid rebuilding this image during movement redraws
Frame_Ready:                            ; Both resident forms now match the selected animation frame
                LD      A,(Display_Page) ; Read the screen which must remain untouched
                XOR     4               ; Select the hidden screen
                LD      (Target_Page),A ; Retain the physical target during scenery bank copies
                CALL    Map_Lower       ; Replace the sprite mapping with screen RAM
                CALL    Clear_Sprite    ; Restore scenery under this page's old sprite position
                LD      A,(Sprite_X)    ; Read the current pixel position
                AND     1               ; Odd X needs the padded 14-byte shifted frame
                JR      Z,Select_Even_Frame ; Even X can use the original 13-byte frame
                LD      A,Odd_Bytes     ; Select the wider destination-row length
                LD      (Draw_Width),A  ; Keep the width for the row drawing loop
                JR      Draw_Position   ; Continue with the same pixel-to-byte conversion
Select_Even_Frame: LD  A,Sprite_Bytes  ; Even X keeps the original 13-byte row width
                LD      (Draw_Width),A  ; Keep the width for the row drawing loop
Draw_Position:  LD      A,(Sprite_Y)    ; Read the current ground-following origin
                CALL    Row_Address     ; Convert that row to its packed screen address
                LD      A,(Sprite_X)    ; Read the horizontal pixel position
                SRL     A               ; Each MODE 4 byte contains two horizontal pixels
                LD      E,A             ; Put that offset in DE
                LD      D,0             ; Clear its high byte
                ADD     HL,DE           ; Add X to get the screen destination address
                LD      A,(Sprite_X)    ; Select the source form from the same X parity
                AND     1               ; A nonzero remainder means the position is odd
                LD      DE,Frame_Buffer ; Read the staged frame from resident RAM
                JR      Z,Draw_Selected_Frame ; Use unshifted data for an even position
                LD      DE,Odd_Frame_Buffer ; Use the padded data for an odd position
Draw_Selected_Frame:                    ; HL is the destination and DE is the matching frame
                CALL    Draw_Sprite     ; Draw the sprite at its new position
                CALL    Restore_Lower   ; Restore ROM and its working memory
                LD      A,1             ; Prepare the completed-frame flag
                LD      (Frame_Pending),A ; Allow the next interrupt's loop to display it
                EI                      ; The ROM interrupt can safely run again
                RET                     ; Return to movement or animation code
;
Clear_Sprite:   LD      HL,Previous_X_10 ; Start with the old position for physical screen 10
                LD      A,(Display_Page) ; Infer which other page is currently hidden
                CP      Screen_Page     ; If 10 is displayed, we must erase screen 14
                JR      NZ,Old_Position ; Otherwise the first saved position is correct
                INC     HL              ; Select screen 14's saved horizontal position
Old_Position:   LD      B,(HL)          ; Keep the position last drawn on this hidden page
                LD      A,(Sprite_X)   ; Fetch the position we are about to draw
                LD      (HL),A          ; Remember it for this page's next erase
                LD      A,B             ; Read the old pixel position
                AND     1               ; Check its old packed-nibble alignment
                LD      A,Sprite_Bytes  ; Begin with the 13-byte even-position width
                JR      Z,Old_Width_Ready ; Even old X must not erase the next screen byte
                INC     A               ; Odd old X previously occupied 14 destination bytes
Old_Width_Ready: LD   (Old_Width),A    ; Save the width belonging to the old position
                LD      A,B             ; Read the old pixel position again
                SRL     A               ; Convert it to its starting screen byte
                LD      L,A             ; Build the old horizontal byte offset in HL
                LD      H,0             ; Clear its high byte
                PUSH    HL              ; Keep the old X byte offset while reading this page's old row
                LD      HL,Previous_Y_10 ; Select the saved row belonging to physical screen 10
                LD      A,(Display_Page) ; Determine which other page is currently hidden
                CP      Screen_Page     ; A displayed page 10 means we must erase page 14
                JR      NZ,Old_Row_Ready ; Otherwise erase page 10's saved row
                INC     HL              ; Select page 14's saved row
Old_Row_Ready:  LD      A,(HL)          ; Read where this hidden page last drew Dizzy vertically
                LD      B,A             ; Retain that old row during the state update
                LD      A,(Sprite_Y)    ; Read where the new drawing will go
                LD      (HL),A          ; Store the new row for this page's future restoration
                LD      A,B             ; Convert the old row, not the current ground-following row
                CALL    Row_Address     ; Return its screen-row address in HL
                POP     DE              ; Recover the old horizontal byte offset
                ADD     HL,DE           ; Restore the complete previous X/Y rectangle
                LD      (Restore_Pointer),HL ; Restore this physical page's previous rectangle
                LD      A,(Old_Width)   ; Use old parity even when the new X has different parity
                LD      (Restore_Width),A ; Copy all 13 or 14 old destination bytes
                LD      A,Sprite_Rows   ; Restore the complete cropped height
                LD      (Restore_Rows),A ; Keep the count outside banked screen RAM
                JP      Restore_Background ; Replace old pixels before drawing the new frame
;
Draw_Sprite:    LD      C,Sprite_Rows    ; Process all 22 frame rows
Draw_Row:       PUSH    BC              ; Save the row counter while C holds pixel scratch
                LD      A,(Draw_Width)  ; Read the current 13- or 14-byte destination width
                LD      B,A             ; Process the selected width on this frame row
Draw_Byte:      LD      A,(DE)          ; Read the next mask byte
                AND     (HL)            ; Retain the transparent background bits
                LD      C,A             ; Save those bits
                INC     DE              ; Advance to the paired pixel byte
                LD      A,(DE)          ; Read the cleaned sprite pixels
                OR      C               ; Combine the sprite with the retained background
                LD      (HL),A          ; Write the composed screen byte
                INC     DE              ; Advance to the next mask/pixel pair
                INC     HL              ; Advance to the next screen destination byte
                DJNZ    Draw_Byte       ; Finish this sprite row
                LD      A,(Draw_Width)  ; Read the current row width before advancing
                CP      Odd_Bytes       ; Odd positions occupy 14 destination bytes
                LD      BC,128-Sprite_Bytes ; Even positions leave 115 bytes to the next row
                JR      NZ,Draw_Row_Offset ; Keep the 13-byte destination stride
                LD      BC,128-Odd_Bytes ; Odd positions leave 114 bytes to the next row
Draw_Row_Offset:                        ; BC now advances from the current row's last byte
                ADD     HL,BC           ; Advance to the next destination row
                POP     BC              ; Recover the remaining row count
                DEC     C               ; Count the completed row
                JR      NZ,Draw_Row     ; Continue while rows remain
                RET                     ; Return after drawing the entire frame
;
Idle_Animation: DEFB    2,1             ; Two idle frames which repeat
                DEFW    TIDizzy_1_Interleaved,TIDizzy_2_Interleaved ; Idle frame pointers
Roll_Animation: DEFB    8,0             ; Eight roll frames played once
                DEFW    TIDizzy_1_Interleaved,TIDizzy_3_Interleaved ; Roll frames 1-2
                DEFW    TIDizzy_4_Interleaved,TIDizzy_5_Interleaved ; Roll frames 3-4
                DEFW    TIDizzy_6_Interleaved,TIDizzy_7_Interleaved ; Roll frames 5-6
                DEFW    TIDizzy_8_Interleaved,TIDizzy_9_Interleaved ; Roll frames 7-8
Walk_Left_Animation: DEFB 8,1           ; Eight repeating left-walk frames
                DEFW    TIDizzy_10_Interleaved,TIDizzy_11_Interleaved ; Left-walk frames 1-2
                DEFW    TIDizzy_12_Interleaved,TIDizzy_13_Interleaved ; Left-walk frames 3-4
                DEFW    TIDizzy_14_Interleaved,TIDizzy_15_Interleaved ; Left-walk frames 5-6
                DEFW    TIDizzy_16_Interleaved,TIDizzy_17_Interleaved ; Left-walk frames 7-8
Walk_Right_Animation: DEFB 7,1          ; Seven repeating right-walk frames
                DEFW    TIDizzy_18_Interleaved,TIDizzy_19_Interleaved ; Right-walk frames 1-2
                DEFW    TIDizzy_20_Interleaved,TIDizzy_21_Interleaved ; Right-walk frames 3-4
                DEFW    TIDizzy_22_Interleaved,TIDizzy_23_Interleaved ; Right-walk frames 5-6
                DEFW    TIDizzy_24_Interleaved ; Last right-walk frame
Jump_Left_Animation: DEFB 7,0           ; Seven left-jump animation frames played once
                DEFW    TIDizzy_26_Interleaved,TIDizzy_27_Interleaved ; Left-jump frames 1-2
                DEFW    TIDizzy_28_Interleaved,TIDizzy_29_Interleaved ; Left-jump frames 3-4
                DEFW    TIDizzy_30_Interleaved,TIDizzy_31_Interleaved ; Frames spanning asset pages
                DEFW    TIDizzy_32_Interleaved ; Last left-jump frame
Jump_Right_Animation: DEFB 7,0          ; Seven right-jump animation frames played once
                DEFW    TIDizzy_33_Interleaved,TIDizzy_34_Interleaved ; Right-jump frames 1-2
                DEFW    TIDizzy_35_Interleaved,TIDizzy_36_Interleaved ; Right-jump frames 3-4
                DEFW    TIDizzy_37_Interleaved,TIDizzy_38_Interleaved ; Right-jump frames 5-6
                DEFW    TIDizzy_39_Interleaved ; Last right-jump frame
