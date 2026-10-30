;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Test Ceiling                          |
; | Filename:   test_ceiling.asm                                                    |
; -----------------------------------------------------------------------------------
;
; An artificial black bar used only to test upward collision.
; It is a labelled teaching fixture, not part of the original scenery.
;
Add_Test_Ceiling: LD    A,Background_Page ; Add the visible bar to the authoritative bitmap first
                CALL    Map_Lower       ; Startup already has interrupts disabled
                LD      A,0x77          ; Palette index seven is black in both packed pixels
                CALL    Ceiling_Bytes   ; Both display pages will receive this through normal initialization
                LD      A,Collision_Page ; Put exactly the same bar in the separate solidity plane
                CALL    Map_Lower       ; Keep the fixture independent of palette colour
                LD      A,0xFF          ; Both nibbles of each fixture byte are solid
                JP      Ceiling_Bytes   ; Leave restoration to the normal startup mapping path
Ceiling_Bytes:  LD      HL,85*128+55    ; Start a 64-pixel-wide bar at pixel X=110, row 85
                LD      D,3             ; Make the fixture three rows high
Ceiling_Row:    LD      B,32            ; Write 32 packed bytes per fixture row
Ceiling_Byte:   LD      (HL),A          ; Store either visual black or solidity, depending on the bank
                INC     HL              ; Advance by one packed pair of pixels
                DJNZ    Ceiling_Byte    ; Finish the selected row width
                LD      BC,128-32       ; Skip the unused bytes to the next screen row
                ADD     HL,BC           ; Keep the bar's left edge fixed
                DEC     D               ; Count the completed fixture row
                JR      NZ,Ceiling_Row  ; Repeat for all three rows
                RET                     ; Startup will copy the finished background to both screens
