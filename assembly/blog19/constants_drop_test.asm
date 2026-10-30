;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Constants (Drop Test)                 |
; | Filename:   constants_drop_test.asm                                             |
; | Based on:   constants.asm                                                       |
; -----------------------------------------------------------------------------------
;
; Hardware ports, memory pages and tuning values in one place.
; It contains only EQUs, so it produces no bytes and is included first.
; Step 21-2 only: its copy of constants.asm sets up a carried item at the cliff to test an unsafe drop.
;
LMPR:           EQU     250             ; Lower Memory Page Register
VMPR:           EQU     252             ; Video Memory Page Register
Sprite_Page:    EQU     4               ; Cropped frames occupy physical pages 4 and 5
Screen_Page:    EQU     10              ; The screen pair starts at pages 10 and 14
Frame_Delay:    EQU     5               ; Animation frames last five interrupts
Sprite_Bytes:   EQU     13              ; Each cropped row contains 13 raw source bytes
Sprite_Rows:    EQU     22              ; Each frame contains 22 rows
Frame_Size:     EQU     Sprite_Bytes*Sprite_Rows*2 ; 572 interleaved mask/pixel bytes
Odd_Bytes:      EQU     Sprite_Bytes+1  ; An odd pixel offset needs one extra destination byte
Odd_Frame_Size: EQU     Odd_Bytes*Sprite_Rows*2 ; Padded odd-shift buffer: 616 interleaved bytes
Background_Page: EQU    6               ; Keep the authoritative scenery in physical pages 6-7
Graphics_Page:  EQU     8               ; Keep reusable source graphics in physical pages 8-9
Collision_Page: EQU     12              ; Static solidity occupies physical pages 12-13
Initial_Row:    EQU     87              ; Supported cliff-side origin for the unsafe-drop fixture
Maximum_Fall:   EQU     4               ; Cap downward speed in pixels per completed update
Jump_Impulse:   EQU     246             ; Signed minus ten: upward velocity before gravity is applied
Box_Left:       EQU     8               ; Keep the stable footprint around Dizzy's body and feet
Box_Right:      EQU     17              ; Inclusive right edge of the ten-pixel footprint
Box_Top:        EQU     4               ; Top collision inset from the 22-row drawing
Box_Bottom:     EQU     20              ; Bottom collision edge, inclusive
Step_Height:    EQU     3               ; Follow only nearby ground, never snap to a distant platform
Maximum_X:      EQU     230             ; The last pixel position fitting a 26-pixel-wide sprite
