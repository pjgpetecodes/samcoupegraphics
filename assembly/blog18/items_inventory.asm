;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Collecting Items                      |
; | Filename:   items_inventory.asm                                                 |
; -----------------------------------------------------------------------------------
;
; Collecting and dropping items.
;
Read_Collect:   LD      BC,0xBFFE       ; Select the Enter/L/K/J/H keyboard row
                IN      A,(C)           ; Read Enter's active-low bit
                AND     1               ; Ignore the other keys in this row
                LD      B,A             ; Retain the current Enter bit
                LD      A,(Enter_Previous) ; Read the preceding update's bit
                LD      C,A             ; Keep it while storing the latest key state
                LD      A,B             ; Recover the current bit
                LD      (Enter_Previous),A ; Update even when collection is not permitted
                OR      A               ; A nonzero bit means Enter is released
                RET     NZ              ; A release rearms the next press
                LD      A,C             ; Check whether Enter was already held
                OR      A               ; Only a fresh released-to-pressed edge may collect
                RET     Z               ; Never collect repeatedly from a held key
                LD      A,(Grounded)    ; Item interaction requires feet on solid ground
                OR      A               ; Consume but do not queue an airborne press
                RET     Z               ; Collection does not alter a jump or fall
                LD      BC,0xFEFE       ; Require the player to release both horizontal directions
                IN      A,(C)           ; Read the active-low direction bits
                AND     6               ; Keep Z and X
                CP      6               ; Both bits are high only when neither key is held
                RET     NZ              ; A moving player must stop before interacting
                LD      A,(Current_Room) ; The chest begins on screen 1
                CP      1               ; This lesson has only that one world item
                RET     NZ              ; Enter in another room does not grant the chest
                LD      A,(Chest_Collected) ; Keep collection state outside the room bitmap
                OR      A               ; A nonzero byte means the chest is already carried in memory
                RET     NZ              ; Prevent duplicate collection after revisiting screen 1
                LD      A,(Sprite_X)    ; Test rectangle overlap with chest pixels 48-67
                ADD     A,Box_Right     ; Locate the player's inclusive right collision edge
                CP      48              ; The player's box must reach the chest's left edge
                RET     C               ; Do not collect an item from a distance
                LD      A,(Sprite_X)    ; Locate the player's left collision edge
                ADD     A,Box_Left      ; Use the same stable body box as movement
                CP      68              ; The player's left edge must remain left of the chest's far edge
                RET     NC              ; The chest is entirely behind the player
                LD      A,(Sprite_Y)    ; Test the same overlap vertically
                ADD     A,Box_Bottom    ; Locate the inclusive lower edge of the body
                CP      111             ; The chest starts on source row 111
                RET     C               ; A body entirely above the item cannot collect it
                LD      A,(Sprite_Y)    ; Locate the body's top row
                ADD     A,Box_Top       ; Exclude the drawing's transparent top margin
                CP      127             ; The chest's last row is 126
                RET     NC              ; A body entirely below the item cannot collect it
                LD      A,1             ; Store a persistent collected-state byte
                LD      (Chest_Collected),A ; Rebuilding scenery must not recreate a collected item
                LD      A,(Sprite_Y)    ; Refresh at the existing supported position
                JP      Enter_Room      ; Rebuild both screens without moving the player to an exit
;
Build_Chest:    LD      A,(Current_Room) ; Only the starting beach contains this world item
                CP      1               ; Keep the cliff room's scenery unchanged
                RET     NZ              ; Do not draw a duplicate chest on screen 2
                LD      A,(Chest_Collected) ; Persistent state decides whether the world image exists
                OR      A               ; A collected chest must remain absent on return
                RET     NZ              ; Leave the already composed room untouched
                LD      HL,Chest_Image+2 ; Skip the extracted width/height header
                LD      (Block_Source),HL ; Reuse the established transparent graphic compositor
                LD      HL,111*128+24   ; Source-derived byte X=24 and row Y=111
                LD      (Block_Destination),HL ; Draw into authoritative scenery, not just one display
                LD      A,10            ; The chest drawing contains twenty horizontal pixels
                LD      (Block_Width),A ; Copy all ten packed source bytes
                LD      (Block_Stride),A ; Its source width and visible width are identical
                LD      A,16            ; The source chest drawing is sixteen rows high
                LD      (Block_Rows),A ; Keep its height separate from the player's height
                JP      Compose_Block   ; The world item is visible but is not yet a solid platform
;
Chest_Collected: DEFB   0               ; Persistent one-item state, not an inventory or escape unlock
