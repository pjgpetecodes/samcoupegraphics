;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 12 - Part 1: A Static Palm Tree          |
; | Filename:   blog10\12-1.asm                                                     |
; -----------------------------------------------------------------------------------
;
; A single source-game palm on a static cyan screen.
;
Copy_Width:     EQU     41              ; Image 6 stores 82 MODE 4 pixels per row
Copy_Rows:      EQU     77              ; Copy all 77 rows of the source palm
Source_Start:   EQU     2               ; Skip the image's width and height header
Destination:    EQU     70*128+40       ; Place the palm at byte X=40, row Y=70
                INCLUDE "static-background.asm" ; Run the shared static bitmap copier
                ORG     0               ; Address the graphic in the lower window
                DUMP    4,0             ; Load the source graphic into physical page 4
Asset_Start:                            ; Mark the beginning of the graphic file
                MDAT    "assets\graphics\image-6.bin" ; Include only the permitted graphics
Asset_End:                              ; Mark the source graphic's final byte
                ASSERT  Asset_End == 2+Copy_Width*Copy_Rows ; Check its packed dimensions
                ASSERT  Asset_End < 0x8000 ; Keep the source within its bank pair
