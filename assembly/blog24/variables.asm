;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Variables                             |
; | Filename:   variables.asm                                                       |
; -----------------------------------------------------------------------------------
;
; Variables shared between the feature files.
; Game_State..Game_State_End is the snapshot that a restart copies back.
;
Saved_LMPR:     DEFB    0               ; Original mapping required by the ROM interrupt
;
Game_State:                             ; Everything a restart must return to its loaded value
Current_Room:   DEFB    1               ; Begin on screen 1; only its left neighbour is connected
Chest_Placed:   DEFB    0               ; Persistent solved state; never set by merely carrying the chest
Placement_Trigger: DEFB 0              ; Candidate activation flag, committed only with a safe drop
Return_X:       DEFB    60              ; Safe cliff corridor retained when the player escapes upward
Inventory_Count: DEFB   0               ; Number of occupied slots, limited to three
Inventory_Slots: DEFB   255,255,255     ; Stable item identifiers; the last occupied slot is the top
Action_Item:    DEFB    0               ; Stable record index currently checked for nearby pickup
Action_Flash:   DEFB    0               ; Remaining visible rejection-feedback updates
Drop_X:         DEFB    0               ; Proposed item byte X, committed only after safe placement
Drop_Y:         DEFB    0               ; Proposed item top row
Drop_Tries:     DEFB    0               ; Bounded nearby placement candidates remaining
HUD_Slot:       DEFB    0               ; Slot frame currently composed in the reserved HUD area
HUD_X_Byte:     DEFB    0               ; Current frame's packed X for its icon destination
World_Items:                            ; ID, source word, byte X, Y, packed width, height, room
                DEFB    0               ; Tutorial identifier zero is the real chest
                DEFW    Chest_Image+2   ; Extracted source graphic 215, after its header
                DEFB    24,111,10,16,1 ; Keep the chest's recovered screen-1 position
                DEFB    1               ; Tutorial identifier one is the starting beach's real coin
                DEFW    Coin_Image+2    ; Extracted source graphic 216, after its header
                DEFB    108,148,11,17,1 ; Recovered coin placement, not an inventory-demo fixture
                DEFB    2               ; The fourth room's real coin record
                DEFW    Coin_Image+2    ; Both coins use the permitted source graphic 216
                DEFB    49,134,11,17,4 ; Screen 4 is now linked, so this coin is reachable
                DEFB    3               ; Keep the record capacity without an extra invented world item
                DEFW    Coin_Image+2    ; Inactive records are never drawn or collected
                DEFB    0,48,11,17,254 ; Reserved inactive state, not carried and not a puzzle prerequisite
Game_State_End:                         ; The snapshot stops before display and water state
Initial_State:  DEFS    Game_State_End-Game_State ; Boot-time copy of Game_State, filled by Start
;
Enter_Previous: DEFB    1               ; Released Enter bit used to detect a fresh collection press
Sprite_X:       DEFB    Start_X         ; Begin clear of the cliff with room to approach it
Facing_Left:    DEFB    0               ; Retain the last direction for neutral jump animation
Sprite_Y:       DEFB    Initial_Row     ; Keep world Y independent of the current animation frame
Grounded:       DEFB    1               ; The initial footprint rests on the verified beach surface
Space_Previous: DEFB    1               ; Released Space bit used for fresh-press jump detection
Fall_Speed:     DEFB    0               ; Downward pixels per completed update, initially at rest
Fall_Remaining: DEFB    0               ; One-pixel downward candidates still to resolve this update
Move_Phase:     DEFB    0               ; Zero selects one pixel, one selects three pixels
Previous_X_10:  DEFB    120             ; Pixel position last drawn on physical screen 10
Previous_X_14:  DEFB    120             ; Pixel position last drawn on physical screen 14
Previous_Y_10:  DEFB    Initial_Row     ; Vertical position last drawn on physical screen 10
Previous_Y_14:  DEFB    Initial_Row     ; Vertical position last drawn on physical screen 14
Desired_X:      DEFB    0               ; Bounded movement destination before collision resolution
Accepted_X:     DEFB    0               ; Last origin whose leading collision column was empty
Candidate_X:    DEFB    0               ; One-pixel candidate currently being tested
Candidate_Y:    DEFB    Initial_Row     ; Origin currently being checked for support and body clearance
Ground_Last_Y:  DEFB    Initial_Row     ; Inclusive lower bound of the nearby support search
Draw_Width:     DEFB    0               ; Current 13- or 14-byte destination width
Old_Width:      DEFB    0               ; Previous page position's 13- or 14-byte width
Previous_Mask:  DEFB    0               ; Prior source mask used to join adjacent nibbles
Previous_Pixel: DEFB    0               ; Prior source pixel byte used to join adjacent nibbles
Next_Mask:      DEFB    0               ; Current source mask retained during nibble shifting
Next_Pixel:     DEFB    0               ; Current source pixel retained during nibble shifting
Frame_Source:   DEFW    0               ; Selected banked frame address while staging
Cached_Frame:   DEFW    0xFFFF          ; Invalid initial address forces the first frame copy
Current_Animation: DEFW 0               ; Resident sequence header address
Current_Frame:  DEFB    0               ; Zero-based index in the sequence's pointer table
Current_Delay:  DEFB    0               ; Interrupts remaining before the next animation frame
Display_Page:   DEFB    0               ; Physical screen starting page currently displayed
Frame_Pending:  DEFB    0               ; Completed hidden frame waiting for a flip
Target_Page:    DEFB    0               ; Physical screen selected for background restoration
Restore_Pointer: DEFW   0               ; Shared source/destination offset for a rectangle row
Restore_Width:  DEFB    0               ; Packed bytes to restore on each row
Restore_Rows:   DEFB    0               ; Number of rows left in the current rectangle
Background_Row: DEFS    128             ; Stage a full row without mapping source and target together
Room_Next:      DEFW    0               ; Resident pointer to the next seven-byte draw record
Blocks_Left:    DEFB    0               ; Remaining visible graphic blocks in the chosen room
Block_Source:   DEFW    0               ; Current source-row address within graphics pages 8-9
Block_Destination: DEFW 0               ; Current destination-row offset in background pages 6-7
Block_Width:    DEFB    0               ; Number of visible packed bytes in each block row
Block_Rows:     DEFB    0               ; Number of visible rows left in this graphic block
Block_Stride:   DEFB    0               ; Unclipped width used to advance source rows
