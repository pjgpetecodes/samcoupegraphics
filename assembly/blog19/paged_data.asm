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
                DEFS    0x6000          ; Build this bitmap at startup rather than loading scenery
Background_End:                         ; Mark the final byte of source scenery
                ASSERT  Background_End == 0x6000 ; Require one complete packed MODE 4 screen
                ASSERT  Initial_Row+Sprite_Rows <= 192 ; Keep the initial rectangle within the bitmap
                ORG     0               ; Address reusable graphics through the lower CPU window
                DUMP    Graphics_Page,0 ; Keep source graphics separate from the composition target
                INCLUDE "assets\room-graphics.asm" ; Load only the selected graphic resources
Chest_Image:                            ; Source graphic 215 includes its two-byte dimensions header
                MDAT    "assets\image-215.bin" ; Keep the original chest asset and provenance
Coin_Image:                             ; Additional permitted graphic for the labelled fixture
                MDAT    "assets\image-216.bin" ; Coin pixels only; see this post's asset provenance
Axe_Image:                              ; Additional permitted graphic for the labelled fixture
                MDAT    "assets\image-211.bin" ; Axe pixels only; not original engine code
Scroll_Image:                           ; Additional permitted graphic for the labelled fixture
                MDAT    "assets\image-231.bin" ; Scroll pixels only; not an original item placement
Graphics_End:                           ; Mark the final reusable source-graphics byte
                ASSERT  Graphics_End < 0x8000 ; All selected resources must fit in pages 8-9
                ORG     0               ; Address collision pixels through the lower CPU window
                DUMP    Collision_Page,0 ; Keep solidity separate from scenery and both displays
Collision_Start:                        ; Mark the beginning of the starting beach's static mask
                DEFS    0x6000          ; Decode the selected room's compact mask at startup and on entry
Collision_End:                          ; Mark the final byte of the loaded mask
                ASSERT  Collision_End == 0x6000 ; Solidity has the same packed stride as the screen
