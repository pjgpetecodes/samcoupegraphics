;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Variables                             |
; | Filename:   variables.asm                                                       |
; -----------------------------------------------------------------------------------
;
; Variables shared between the feature files.
;
Saved_LMPR:     DEFB    0               ; Original mapping required by the ROM interrupt
Sprite_X:       DEFB    1               ; Current horizontal position measured in pixels
Move_Phase:     DEFB    0               ; Zero selects one pixel, one selects three pixels
Previous_X_10:  DEFB    1               ; Pixel position last drawn on physical screen 10
Previous_X_14:  DEFB    1               ; Pixel position last drawn on physical screen 14
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
