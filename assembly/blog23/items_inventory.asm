;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Items and Inventory                   |
; | Filename:   items_inventory.asm                                                 |
; -----------------------------------------------------------------------------------
;
; Collecting and dropping items, and the inventory at the top of the screen.
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
                XOR     A               ; Scan stable item identifiers before considering a drop
                LD      (Action_Item),A ; Item zero is the source-positioned chest
Find_Nearby:    LD      A,(Action_Item) ; Locate this item's persistent world record
                CALL    Item_Pointer    ; Return its resident record in IX
                LD      A,(Current_Room) ; A carried item uses room 255 rather than a world room
                CP      (IX+7)          ; Compare the item location with the visible room
                JR      NZ,Next_Nearby  ; Do not collect an item from another room or from the stack
                LD      A,(IX+3)        ; Read the item's byte-aligned world X
                ADD     A,A             ; Convert it to a pixel coordinate
                LD      D,A             ; Retain the item's left edge
                LD      A,(Sprite_X)    ; Locate the player's inclusive right edge
                ADD     A,Box_Right     ; Use the same stable body box as movement
                CP      D               ; Compare with the item's left edge
                JR      C,Next_Nearby   ; The player's body lies entirely to the left
                LD      A,(IX+3)        ; Read the item's byte-aligned left edge again
                ADD     A,(IX+5)        ; Add its packed width for the exclusive right edge
                ADD     A,A             ; Convert the right edge to pixels
                LD      D,A             ; Retain it while reading the player position
                LD      A,(Sprite_X)    ; Locate the player's left body edge
                ADD     A,Box_Left      ; Exclude the drawing's transparent margin
                CP      D               ; Require actual horizontal overlap
                JR      NC,Next_Nearby  ; The player's body lies entirely to the right
                LD      A,(Sprite_Y)    ; Locate the player's inclusive bottom body row
                ADD     A,Box_Bottom    ; Keep interaction and movement boxes consistent
                CP      (IX+4)          ; Compare with the item's first row
                JR      C,Next_Nearby   ; The player's body is entirely above the item
                LD      A,(IX+4)        ; Read the item's first row
                ADD     A,(IX+6)        ; Calculate its exclusive bottom row
                LD      D,A             ; Retain the item's lower edge
                LD      A,(Sprite_Y)    ; Read the player's top body row
                ADD     A,Box_Top       ; Ignore the cropped drawing's top padding
                CP      D               ; Require actual vertical overlap
                JR      NC,Next_Nearby  ; The player's body is entirely below the item
                LD      A,(Inventory_Count) ; A nearby item always takes precedence over dropping
                CP      3               ; The requested inventory has exactly three slots
                JP      Z,Action_Rejected ; Full means reject; never silently discard the oldest item
                LD      E,A             ; Use the old count as the next free slot index
                LD      D,0             ; Extend it for resident address arithmetic
                LD      HL,Inventory_Slots ; Store identifiers, not copies of graphic pixels
                ADD     HL,DE           ; Locate the next free slot
                LD      A,(Action_Item) ; Push this item's stable identifier
                LD      (HL),A          ; Append after all previously carried items
                INC     E               ; Count the newly occupied slot
                LD      A,E             ; Publish the new stack depth
                LD      (Inventory_Count),A ; The last occupied slot is the stack top
                LD      (IX+7),255      ; Remove the item from the world before rebuilding scenery
                JP      Refresh_Items   ; Update all three visible slots and both display pages
Next_Nearby:    LD      A,(Action_Item) ; Advance to the next persistent record
                INC     A               ; Item identifiers run from zero through three
                LD      (Action_Item),A ; Preserve the index across the next overlap calculation
                CP      4               ; Four fixtures let the three-slot capacity be demonstrated
                JR      NZ,Find_Nearby  ; Complete the pickup search before considering a drop
                LD      A,(Inventory_Count) ; No nearby world item was found
                OR      A               ; An empty stack cannot be popped
                JP      Z,Action_Rejected ; Give visible feedback rather than a success-shaped no-op
                DEC     A               ; Select the last occupied slot, never the first
                LD      E,A             ; Retain the future count without committing it yet
                LD      D,0             ; Extend the index for resident address arithmetic
                LD      HL,Inventory_Slots ; Read the newest carried identifier
                ADD     HL,DE           ; Locate the current stack top
                LD      A,(HL)          ; The world record remains resident while carried
                CALL    Item_Pointer    ; IX identifies the item being considered for a safe drop
                LD      A,128           ; Keep the complete item inside the packed screen width
                SUB     (IX+5)          ; Find its last legal byte-aligned left edge
                LD      B,A             ; Retain that item-specific right boundary
                LD      A,(Sprite_X)    ; Drop at the stopped player's footprint, never behind it
                ADD     A,Box_Left      ; The body inset keeps a wall-side drop clear of the cliff
                SRL     A               ; Align dropped item graphics to a complete screen byte
                CP      B               ; A wide item may need the final byte clipped back at the right edge
                JR      C,Drop_X_Ready  ; Otherwise retain the actual local drop position
                LD      A,B             ; Clamp only to the bitmap boundary, not a puzzle destination
Drop_X_Ready:   LD      (Drop_X),A      ; Retain the proposed world byte X
                LD      A,(Sprite_Y)    ; Align the item's bottom near the player's feet
                ADD     A,Box_Bottom+1  ; Read the first row beneath the body
                SUB     (IX+6)          ; Convert the bottom row to this item's top origin
                SUB     Step_Height     ; Search a bounded neighbourhood above that origin
                CP      48              ; Never put an item in the reserved HUD region
                JR      NC,Drop_Top_Ready ; Keep a legal playfield origin
                LD      A,48            ; Clamp only the upper bound of the local placement search
Drop_Top_Ready: LD      (Drop_Y),A      ; Begin the safe placement search
                LD      A,Step_Height*2+1 ; Use the same small local adjustment as surface following
                LD      (Drop_Tries),A ; Do not search remotely or invent a distant landing location
                DI                      ; Validate against the separate collision plane
                LD      A,Collision_Page ; Keep source pixels and displayed colours out of the decision
                CALL    Map_Lower       ; Record state and the stack stay resident
Drop_Search:    CALL    Drop_Fits        ; Require an empty complete rectangle with support underneath
                JR      C,Drop_Next     ; Ordinary unsafe placements must leave inventory unchanged
                CALL    Check_Chest_Placement ; Test the accepted physical position against the trigger
                JR      NC,Drop_Accept  ; Only commit the pop after both placement checks succeed
Drop_Next:                              ; Continue the same bounded search after a rejected candidate
                LD      A,(Drop_Y)      ; Try one row lower within the bounded search
                INC     A               ; Preserve byte-aligned horizontal placement
                LD      (Drop_Y),A      ; Retain the next proposed top row
                LD      A,(Drop_Tries) ; Count remaining nearby candidates
                DEC     A               ; Consume the rejected candidate
                LD      (Drop_Tries),A ; Preserve the result across the next rectangle probe
                JR      NZ,Drop_Search ; No candidate is allowed to bypass collision checks
                CALL    Restore_Lower    ; Restore ROM before returning visible failure feedback
                EI                      ; The original interrupt mapping is accessible again
                JP      Action_Rejected ; Leave count, slots and item room unchanged on failure
Drop_Accept:    LD      A,(Drop_X)      ; Commit the accepted world position first
                LD      (IX+3),A        ; Store the item's byte-aligned left edge
                LD      A,(Drop_Y)      ; Read the supported top row
                LD      (IX+4),A        ; Store the item's new world Y
                LD      A,(Current_Room) ; A dropped item belongs to the current world room
                LD      (IX+7),A        ; It is no longer marked as carried
                LD      A,(Placement_Trigger) ; Only a physically accepted chest overlap can solve the puzzle
                OR      A               ; Carrying the item never sets this candidate flag
                JR      Z,Drop_Not_Platform ; Ordinary item drops remain ordinary world objects
                LD      A,(Sprite_X)    ; This grounded drop stance is a clear cliff-room return corridor
                LD      (Return_X),A    ; Do not replace it with an airborne X above the cliff
                LD      A,1             ; Persist the source-derived platform activation across room visits
                LD      (Chest_Placed),A ; A solved puzzle no longer depends on the carried slots
                LD      (IX+7),254      ; Consume the loose chest, matching the original trigger's removal
Drop_Not_Platform:                      ; The stack pop is identical for ordinary drops and the solved chest
                LD      A,(Inventory_Count) ; Pop exactly the last occupied slot
                DEC     A               ; Leave older identifiers in their original order
                LD      (Inventory_Count),A ; Publish the new stack depth
                LD      E,A             ; Locate the vacated slot
                LD      D,0             ; Extend the index to sixteen bits
                LD      HL,Inventory_Slots ; Keep empty slots explicit in memory as well as on screen
                ADD     HL,DE           ; Point at the old top
                LD      (HL),255        ; Mark it empty after the placement has succeeded
                CALL    Restore_Lower    ; Restore ROM before refreshing visible scenery
                EI                      ; The normal room refresh will disable interrupts again
Refresh_Items:  LD      A,(Sprite_Y)    ; Keep the supported player at the current world position
                JP      Enter_Room      ; Rebuild world images and HUD on both physical display pages
Action_Rejected: LD    A,20            ; Make full/empty/unsafe actions visibly distinct from success
                LD      (Action_Flash),A ; A short border pulse leaves inventory and world unchanged
                RET                     ; Do not convert a failed pickup into an unintended drop
;
Item_Pointer:   LD      L,A             ; Records are eight bytes each
                LD      H,0             ; Extend the stable identifier
                ADD     HL,HL           ; Multiply the record index by two
                ADD     HL,HL           ; Multiply by four
                ADD     HL,HL           ; Multiply by eight
                LD      DE,World_Items ; All mutable world records stay resident
                ADD     HL,DE           ; Locate the requested record
                PUSH    HL              ; Transfer its address without a window-relative pointer
                POP     IX              ; Use indexed fields throughout item interaction and rendering
                RET                     ; Leave the caller responsible for preserving scratch registers
;
Drop_Fits:      LD      A,(Drop_Y)      ; Check the complete item remains in the playfield
                ADD     A,(IX+6)        ; Include its full height and the required support row
                CP      192             ; A support probe cannot read outside the bitmap
                JR      NC,Drop_Blocked ; Reject instead of clamping a supposedly successful placement
                LD      A,(Drop_Y)      ; Form the first proposed item-row address
                CALL    Row_Address     ; Return its screen offset in HL
                LD      A,(Drop_X)      ; Read the proposed byte-aligned X
                LD      E,A             ; Extend it for addition to the row address
                LD      D,0             ; Keep the horizontal offset positive
                ADD     HL,DE           ; Point at the complete item rectangle
                LD      D,(IX+6)        ; Count all rows in the extracted drawing
Drop_Rect_Row:  LD      B,(IX+5)        ; Check every byte within this item's own width
Drop_Rect_Byte: LD      A,(HL)          ; Only separate solidity data decides whether a drop fits
                OR      A               ; Either occupied nibble makes this conservative rectangle unsafe
                JR      NZ,Drop_Blocked ; Do not embed even a transparent drawing margin in terrain
                INC     HL              ; Advance through the proposed row
                DJNZ    Drop_Rect_Byte  ; Finish the full item width
                LD      A,128           ; Compute the gap to the same X on the next row
                SUB     (IX+5)          ; Remove the width already traversed
                LD      C,A             ; Supply the packed row increment
                LD      B,0             ; The increment fits in the low byte
                ADD     HL,BC           ; Advance one screen row
                DEC     D               ; Count the complete item row just checked
                JR      NZ,Drop_Rect_Row ; Require the whole rectangle to be empty
                LD      B,(IX+5)        ; HL now points at the support row immediately below the item
Drop_Support:   LD      A,(HL)          ; A supported drop needs at least one solid pixel underneath
                OR      A               ; Both packed nibbles belong to the byte-aligned item footprint
                JR      NZ,Drop_Supported ; Keep the item from floating over a distant lower surface
                INC     HL              ; Inspect the rest of the support span
                DJNZ    Drop_Support    ; No selected support byte may be skipped
Drop_Blocked:   SCF                     ; Carry means the proposed placement is unsafe
                RET                     ; The caller keeps the stack unchanged
Drop_Supported: OR      A               ; Clear carry to report a complete supported placement
                RET                     ; The caller may now commit the world state and pop
;
Check_Chest_Placement: XOR A            ; Start every candidate as an ordinary non-triggering drop
                LD      (Placement_Trigger),A ; Never reuse a flag from an earlier rejected position
                LD      A,(IX+0)        ; Tutorial item zero is the recovered empty chest
                OR      A               ; Other items cannot create the supporting platform
                RET     NZ              ; OR cleared carry, reporting an ordinary safe placement
                LD      A,(Current_Room) ; The recovered trigger belongs only to the cliff room
                CP      2               ; Dropping the chest elsewhere remains a normal world drop
                JR      NZ,Placement_Ordinary ; Do not solve the puzzle remotely
                LD      A,(Chest_Placed) ; The source trigger is one-shot
                OR      A               ; A solved puzzle must not consume another world item
                RET     NZ              ; Return clear carry without triggering again
                LD      A,(Drop_X)      ; Match the original byte-coordinate overlap comparisons
                CP      31              ; Source requires the item's left edge to be below this limit
                JR      NC,Placement_Ordinary ; A chest entirely to the right misses the trigger
                ADD     A,(IX+5)        ; Test the loose chest's exclusive far byte edge
                CP      21              ; The source accepts equality at its near trigger boundary
                JR      C,Placement_Ordinary ; A chest entirely to the left misses the trigger
                LD      A,(Drop_Y)      ; The source trigger uses the loose item's top row
                CP      112             ; Its top must be below the trigger's exclusive bottom
                JR      NC,Placement_Ordinary ; A chest too low is only an ordinary drop
                ADD     A,(IX+6)        ; Locate the item's far vertical edge
                CP      100             ; Equality at the trigger's near row counts as overlap
                JR      C,Placement_Ordinary ; A chest entirely above the trigger does not activate it
Placement_Activate: LD  A,1             ; A real accepted chest overlap can now activate the support
                LD      (Placement_Trigger),A ; Commit only after the drop routine accepts this candidate
Placement_Ordinary: OR  A              ; Return clear carry for an ordinary or safe triggering placement
                RET                     ; Keep the source trigger separate from general inventory rules
;
Build_Items:    LD      IX,World_Items  ; Iterate persistent records in stable identifier order
                LD      B,4             ; Three extra item placements are explicit teaching fixtures
Build_Item:     PUSH    BC              ; Keep the outer record count across the compositor
                LD      A,(Current_Room) ; Only world records in the visible room are drawn
                CP      (IX+7)          ; Carried records have room 255
                JR      NZ,Build_Item_Next ; Do not duplicate carried items in the scenery
                LD      A,(IX+4)        ; Convert the world row to a destination screen address
                CALL    Row_Address     ; Use the existing packed-row helper
                LD      E,(IX+3)        ; Read this item's byte-aligned world X
                LD      D,0             ; Extend it for screen-offset arithmetic
                ADD     HL,DE           ; Locate the item's first destination byte
                LD      (Block_Destination),HL ; Stage the destination before mapping graphics
                CALL    Item_Block      ; Fill the remaining compositor fields from the indexed record
                CALL    Compose_Block   ; Overlay the transparent graphic on authoritative scenery
Build_Item_Next: LD     DE,8            ; Advance by one complete persistent item record
                ADD     IX,DE           ; The compositor does not change IX
                POP     BC              ; Recover the remaining world-item count
                DJNZ    Build_Item      ; Complete every visible world item before the HUD
                CALL    Build_Platform  ; A solved chest is drawn as a stationary supporting actor
                XOR     A               ; Draw slots from oldest to newest, left to right
                LD      (HUD_Slot),A    ; There are always three visible frames, including empty slots
HUD_Next:       LD      A,Background_Page ; The HUD belongs to authoritative scenery, not collision
                CALL    Map_Lower       ; Previous item drawing may have selected a different bank
                LD      A,(HUD_Slot)    ; Convert the slot index to a fixed packed X
                LD      B,A             ; Repeated addition is sufficient for three slot positions
                LD      A,16            ; Slot zero begins at pixel 32
                INC     B               ; Convert zero-based index to a small loop count
HUD_X:          ADD     A,36            ; Space frames seventy-two pixels apart
                DJNZ    HUD_X           ; Add once too many so the common subtraction handles all slots
                SUB     36              ; Slot byte X values are 16, 52 and 88
                LD      (HUD_X_Byte),A ; Retain the frame origin across row and icon drawing
                LD      E,A             ; Extend the packed X for adding to the first HUD row
                LD      D,0             ; All slots fit within the 128-byte screen width
                LD      HL,8*128        ; Begin the top border on row eight
                ADD     HL,DE           ; Locate this slot's first frame byte
                LD      B,24            ; A frame is forty-eight pixels wide
HUD_Top:        LD      (HL),0x77       ; Black pixels give empty slots an explicit visible outline
                INC     HL              ; Advance across the complete top border
                DJNZ    HUD_Top         ; Finish the frame's top edge
                LD      DE,128-24       ; Reach the left edge on the next screen row
                ADD     HL,DE           ; Begin drawing the two vertical borders
                LD      B,30            ; Keep inventory pixels inside the reserved rows 0-47
HUD_Sides:      LD      (HL),0x70       ; The frame's first pixel is black and its interior remains cyan
                LD      DE,23           ; Locate the final byte of the same frame row
                ADD     HL,DE           ; Keep the right border independent of any item width
                LD      (HL),0x07       ; The frame's last pixel is black
                LD      DE,128-23       ; Advance to the next row's left edge
                ADD     HL,DE           ; Preserve the same frame width
                DJNZ    HUD_Sides       ; Finish all interior frame rows
                LD      B,24            ; Close the bottom border
HUD_Bottom:     LD      (HL),0x77       ; Empty and occupied slots have identical frame geometry
                INC     HL              ; Advance across the bottom row
                DJNZ    HUD_Bottom      ; Finish the visible empty-slot outline
                LD      A,(HUD_Slot)    ; Read this slot's stable position within the stack
                LD      E,A             ; Extend the index for resident slot lookup
                LD      D,0             ; Counts range from zero through three
                LD      HL,Inventory_Slots ; Empty identifiers are explicitly 255
                ADD     HL,DE           ; Locate the current slot
                LD      A,(HL)          ; Read its item identifier
                CP      255             ; An empty frame does not contain an icon
                JR      Z,HUD_Advance   ; Keep the empty slot visibly blank
                CALL    Item_Pointer    ; Find the corresponding extracted source graphic
                LD      A,(HUD_X_Byte) ; Position every icon within the same reserved frame
                ADD     A,6             ; Leave a cyan margin around the widest item
                LD      E,A             ; Extend the interior byte X
                LD      D,0             ; Keep the HUD offset positive
                LD      HL,15*128       ; All current item icons fit inside the thirty-row interior
                ADD     HL,DE           ; Locate the icon's first packed destination pixel pair
                LD      (Block_Destination),HL ; Use the same compositor as visible world items
                CALL    Item_Block      ; Copy dimensions and source from the persistent record
                CALL    Compose_Block   ; An icon is a view of carried state, not another world item
HUD_Advance:    LD      A,(HUD_Slot)    ; Continue even when the previous slot was empty
                INC     A               ; Advance left-to-right through the fixed capacity
                LD      (HUD_Slot),A    ; Preserve it across the next compositor call
                CP      3               ; Exactly three slot frames are always shown
                JP      NZ,HUD_Next     ; Rebuild all occupied and empty slots
                RET                     ; Both display pages later receive the identical complete HUD
Item_Block:     LD      L,(IX+1)        ; Read the source pointer's low byte
                LD      H,(IX+2)        ; Complete its graphics-window address
                LD      (Block_Source),HL ; Pointers already skip the two-byte dimensions header
                LD      A,(IX+5)        ; Read this item's own packed width
                LD      (Block_Width),A ; Items need not share the player's dimensions
                LD      (Block_Stride),A ; Each item is drawn without source clipping
                LD      A,(IX+6)        ; Read this item's own height
                LD      (Block_Rows),A ; Keep the complete source drawing
                RET                     ; The caller supplies the world or HUD destination
Build_Platform: LD      A,(Current_Room) ; Draw the support only in the cliff room
                CP      2               ; The loose chest and this solved actor are distinct states
                RET     NZ              ; Other room compositions do not contain the support
                LD      A,(Chest_Placed) ; A carried item alone never changes scenery
                OR      A               ; Check persistent one-shot puzzle state
                RET     Z               ; The cliff room stays unchanged while unsolved
                LD      HL,Chest_Image+2 ; Reuse the permitted chest image for the stationary support
                LD      (Block_Source),HL ; Source points past the extracted dimensions header
                LD      A,(World_Items+4) ; Preserve the chest's accepted drop row after activation
                CALL    Row_Address     ; Convert that row to the packed screen offset
                LD      A,(World_Items+3) ; Preserve its accepted byte X instead of snapping to a fixture
                LD      E,A             ; Extend the actual horizontal offset
                LD      D,0             ; Keep the offset positive
                ADD     HL,DE           ; Render exactly where the successful drop was committed
                LD      (Block_Destination),HL ; Keep visible and solid support positions consistent
                LD      A,10            ; The chest contains ten packed bytes per row
                LD      (Block_Width),A ; Reuse the same generic transparent compositor
                LD      (Block_Stride),A ; Source and destination widths are unchanged
                LD      A,16            ; Match the source-derived supporting actor height
                LD      (Block_Rows),A ; Keep the actor drawing independent of inventory slot images
                JP      Compose_Block   ; Overlay the activated support before drawing the HUD
