;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 12 - Part 2: The Starting Beach          |
; | Filename:   blog10\12-2.asm                                                     |
; | Based on:   Tutorial 12 part 1 (blog10\12-1.asm)                                |
; -----------------------------------------------------------------------------------
;
; The reconstructed starting-room scenery, still static.
;
Copy_Width:     EQU     128             ; Each full MODE 4 row occupies 128 bytes
Copy_Rows:      EQU     192             ; Copy the complete 192-row screen
Source_Start:   EQU     0               ; The packed screen has no dimensions header
Destination:    EQU     0               ; Begin at the top-left display byte
                INCLUDE "static-background.asm" ; Reuse the same static bitmap copier
                ORG     0               ; Address the bitmap in the lower window
                DUMP    4,0             ; Load the bitmap into physical pages 4 and 5
Asset_Start:                            ; Mark the beginning of the packed screen
                MDAT    "assets\screen-1.bin" ; Include scenery, not original game code
Asset_End:                              ; Mark the bitmap's final byte
                ASSERT  Asset_End == 0x6000 ; MODE 4 requires exactly 24 KB
                ASSERT  Asset_End < 0x8000 ; Keep the bitmap within its bank pair
