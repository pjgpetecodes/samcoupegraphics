;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Paged Data                            |
; | Filename:   paged_data.asm                                                      |
; -----------------------------------------------------------------------------------
;
; Data assembled into other memory pages rather than the resident program.
; Each section uses ORG 0 because it is read through the lower memory window.
;
                ORG     0               ; Assemble frame pointers for the lower memory window
                DUMP    Sprite_Page,0   ; Store frame bytes in physical pages 4 and 5
                INCLUDE "assets\tidizzy_cropped.asm" ; Reuse the previous 38 cropped frames
Sprites_End:                            ; Mark the end of the banked frame data
                ASSERT  Sprites_End == Frame_Size*38 ; Validate the expected frame footprint
                ASSERT  Sprites_End < 0x8000 ; Both sprite pages must fit in the lower window
                ORG     0               ; Address the authoritative screen in the lower window
                DUMP    Background_Page,0 ; Keep scenery separate from sprites and both displays
Background_Start:                       ; Mark the immutable screen-sized background
                MDAT    "assets\screen-1.bin" ; Reuse the verified starting beach
Background_End:                         ; Mark the final byte of source scenery
                ASSERT  Background_End == 0x6000 ; Require one complete packed MODE 4 screen
                ASSERT  Sprite_Row+Sprite_Rows <= 192 ; Keep the moving rectangle within the bitmap
