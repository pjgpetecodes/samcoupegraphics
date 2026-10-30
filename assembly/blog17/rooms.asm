;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Rooms                                 |
; | Filename:   rooms.asm                                                           |
; -----------------------------------------------------------------------------------
;
; Room exits, entering a room and composing its scenery from draw records.
;
Exit_Left:      LD      A,(Current_Room) ; Only screen 1 has a left link in this first connection lesson
                CP      1               ; The cliff on screen 2 remains a real obstacle
                RET     NZ              ; Do not invent an escape through its left boundary
                LD      A,(Grounded)    ; These first transitions are explicitly walking-only
                OR      A               ; Airborne edge contact keeps the current room
                RET     Z               ; Do not snap an airborne jump onto an entry surface
                LD      A,2             ; Follow the verified left neighbour of the starting beach
                LD      (Current_Room),A ; Select its graphics and collision together
                LD      A,Maximum_X     ; Enter at screen 2's right-hand boundary
                LD      (Sprite_X),A    ; Keep the complete drawing within the new bitmap
                LD      A,97            ; Verified clear, supported origin at that entry
                JR      Enter_Room      ; Rebuild all rendering and movement state consistently
Exit_Right:     LD      A,(Current_Room) ; Only screen 2 links right in this two-room slice
                CP      2               ; Screen 1's water-side boundary is not another room
                RET     NZ              ; Preserve the slice boundary until later lessons
                LD      A,(Grounded)    ; Match the walking-only policy in both directions
                OR      A               ; Airborne players must land before changing rooms
                RET     Z               ; Keep the jump arc in the current room
                LD      A,1             ; Return to the verified starting beach
                LD      (Current_Room),A ; Select both its scenery and collision description
                XOR     A               ; Enter at screen 1's left-hand boundary
                LD      (Sprite_X),A    ; Preserve a legal complete sprite rectangle
                LD      A,98            ; Verified clear, supported origin at that entry
Enter_Room:     LD      (Sprite_Y),A    ; Set the entry position before initializing old rectangles
                DI                      ; Keep interrupts out during all lower-window bank work
                XOR     A               ; Discard any old-room pending frame or vertical speed
                LD      (Frame_Pending),A ; Never flip to a half-replaced old-room drawing
                LD      (Fall_Speed),A  ; A grounded entry has no inherited fall velocity
                LD      A,1             ; Both explicit entry positions are supported
                LD      (Grounded),A    ; Keep ground-following available after the transition
                CALL    Build_Room      ; Compose the new authoritative scenery without touching the display
                CALL    Load_Collision  ; Replace the collision bank for exactly the selected room
                LD      A,(Display_Page) ; Keep the old room displayed until the new hidden bitmap is ready
                XOR     4               ; Select the hidden physical screen pair
                LD      (Target_Page),A ; Record its page for the established row copier
                CALL    Initialize_Screen ; Copy the complete new scenery before revealing it
                LD      A,(Target_Page) ; Recover the newly completed physical screen
                LD      (Display_Page),A ; Make it the displayed page for subsequent hidden drawing
                OR      0x60            ; Preserve MODE 4's display bits
                OUT     (VMPR),A        ; Reveal only the fully composed new-room bitmap
                LD      A,(Display_Page) ; The other pair can now be safely replaced too
                XOR     4               ; Select the old room's no-longer-visible physical screen
                CALL    Initialize_Screen ; Give both display pages the same new-room scenery
                LD      A,(Sprite_X)    ; No old-room sprite remains on either freshly initialized page
                LD      (Previous_X_10),A ; Reset screen 10's restoration origin
                LD      (Previous_X_14),A ; Reset screen 14's restoration origin
                LD      A,(Sprite_Y)    ; Reset vertical restoration state to the supported entry
                LD      (Previous_Y_10),A ; Do not restore an unrelated old-room rectangle
                LD      (Previous_Y_14),A ; Both pages begin with equivalent new-room state
                CALL    Restore_Lower    ; Make the ROM interrupt handler accessible again
                EI                      ; Input and animation can resume on the new room
                RET                     ; The main loop's physics path draws the player at the entry
;
Build_Room:     LD      A,Background_Page ; Select the authoritative composition buffer
                CALL    Map_Lower       ; Keep rendering away from both display screens
                LD      HL,0            ; Seed the first byte of background RAM
                LD      DE,1            ; Begin the repeated fill one byte later
                LD      BC,0x5FFF       ; Fill the remaining bytes of the 24 KB bitmap
                LD      (HL),0          ; Start from the original palette's cyan sky
                LDIR                    ; Clear the complete composition target once
                LD      HL,Room_1       ; Prepare the starting beach's compact draw records
                LD      A,(Current_Room) ; Use the same identifier as the collision loader
                CP      1               ; Only the first two rooms are connected in this lesson
                JR      Z,Room_List_Ready ; Keep screen 1's prepared description
                LD      HL,Room_2       ; Compose the cliff-side beach for screen 2
Room_List_Ready:                        ; HL now selects the new authoritative scenery
                LD      A,(HL)          ; Read its visible-block count
                LD      (Blocks_Left),A ; Retain the count across source and target mappings
                INC     HL              ; Advance from the header to the first seven-byte record
                LD      (Room_Next),HL ; Keep the record pointer in resident memory
Next_Block:     LD      A,(Blocks_Left) ; Check whether all blocks have been composed
                OR      A               ; Set Z for an empty or completed room
                RET     Z               ; The authoritative bitmap is now complete
                LD      HL,(Room_Next) ; Read the following resident draw record
                LD      E,(HL)          ; Read the source pointer's low byte
                INC     HL              ; Advance to its high byte
                LD      D,(HL)          ; Complete the graphics-window source address
                LD      (Block_Source),DE ; Retain it outside the banked window
                INC     HL              ; Advance to the destination offset's low byte
                LD      E,(HL)          ; Read the packed destination offset
                INC     HL              ; Advance to the destination's high byte
                LD      D,(HL)          ; Complete the background-window destination address
                LD      (Block_Destination),DE ; Retain it during graphics paging
                INC     HL              ; Advance to the visible byte width
                LD      A,(HL)          ; Read the offline-clipped source-row width
                LD      (Block_Width),A ; Preserve that width while composing rows
                INC     HL              ; Advance to the visible height
                LD      A,(HL)          ; Read the number of visible source rows
                LD      (Block_Rows),A ; Retain this block's remaining row count
                INC     HL              ; Advance to the original packed source stride
                LD      A,(HL)          ; Clipping does not change the source row length
                LD      (Block_Stride),A ; Retain that independent source increment
                INC     HL              ; Advance to the next seven-byte draw record
                LD      (Room_Next),HL ; Keep it before rendering changes the registers
                CALL    Compose_Block   ; Overlay this graphic in original draw-list order
                LD      A,(Blocks_Left) ; Recover the remaining block count
                DEC     A               ; Count the block just composed
                LD      (Blocks_Left),A ; Store the new count for the loop guard
                JR      Next_Block      ; Continue until all visible blocks are present
Compose_Block:  LD      A,Graphics_Page  ; Select reusable source graphics, not a whole room bitmap
                CALL    Map_Lower       ; Make the clipped source row accessible
                LD      HL,(Block_Source) ; Point at this graphic's next visible row
                LD      DE,Background_Row ; Use the existing resident row staging buffer
                LD      A,(Block_Width) ; Read the clipped width
                LD      C,A             ; Prepare its byte count
                LD      B,0             ; Width is always at most 128 bytes
                LDIR                    ; Stage only the visible packed pixels
                LD      HL,(Block_Source) ; Recover the original row's starting address
                LD      A,(Block_Stride) ; Advance by the unclipped graphics-row width
                LD      E,A             ; Build that positive source increment in DE
                LD      D,0             ; The stride fits in one byte
                ADD     HL,DE           ; Skip cropped pixels before the next visible source row
                LD      (Block_Source),HL ; Retain the next source position
                LD      A,Background_Page ; Select the room composition target
                CALL    Map_Lower       ; Replace the graphics mapping with authoritative scenery
                LD      HL,(Block_Destination) ; Locate this block's next destination row
                LD      DE,Background_Row ; Read its staged packed source pixels
                LD      A,(Block_Width) ; Read how many destination bytes are visible
                LD      B,A             ; Count this row's composed screen bytes
Compose_Byte:   LD      A,(DE)          ; Read two source pixels as packed nibbles
                LD      C,A             ; Retain both source nibbles while testing transparency
                AND     0xF0            ; Check whether the left source pixel is colour zero
                JR      NZ,Left_Opaque  ; A nonzero source nibble replaces the background
                LD      A,(HL)          ; Read the background that must survive on the left
                AND     0xF0            ; Retain only its high nibble
                OR      C               ; Combine it with the original right source nibble
                LD      C,A             ; Save the partially composed packed byte
Left_Opaque:    LD      A,C             ; Check the right source nibble independently
                AND     0x0F            ; Colour zero is transparent on the right too
                JR      NZ,Right_Opaque ; Keep a nonzero right source pixel
                LD      A,(HL)          ; Read the background beneath the right pixel
                AND     0x0F            ; Retain only that original right nibble
                OR      C               ; Combine it with the left composed pixel
                LD      C,A             ; Keep both final destination nibbles
Right_Opaque:   LD      (HL),C          ; Store the composed byte without changing draw order
                INC     DE              ; Advance to the next staged source pair
                INC     HL              ; Advance across the destination screen row
                DJNZ    Compose_Byte    ; Finish this visible row
                LD      HL,(Block_Destination) ; Recover its starting background offset
                LD      DE,128          ; The target always uses the MODE 4 screen stride
                ADD     HL,DE           ; Reach the following destination row
                LD      (Block_Destination),HL ; Retain it across the next graphics mapping
                LD      A,(Block_Rows) ; Recover the number of visible rows left
                DEC     A               ; Count the row just composed
                LD      (Block_Rows),A ; Preserve the zero flag while saving the new count
                JR      NZ,Compose_Block ; Render every visible row in this block
                RET                     ; Continue with the next room draw record
;
                INCLUDE "assets\room-data.asm" ; Resident draw records, not original code
