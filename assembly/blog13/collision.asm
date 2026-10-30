;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Collision                             |
; | Filename:   collision.asm                                                       |
; -----------------------------------------------------------------------------------
;
; Stopping a horizontal step at the first solid pixel in the solidity mask.
;
Constrain_X:    LD      (Desired_X),A    ; Retain the requested bounded destination
                LD      A,(Sprite_X)    ; Begin with the current accepted position
                LD      (Accepted_X),A ; Advance from here one pixel at a time
                DI                      ; Collision RAM will temporarily replace the ROM mapping
                LD      A,Collision_Page ; Select the immutable solidity-mask bank pair
                CALL    Map_Lower       ; Keep code and state resident above this mapping
Collision_Step: LD      A,(Desired_X)   ; Read the requested destination
                LD      B,A             ; Retain it while comparing the accepted position
                LD      A,(Accepted_X) ; Read the last collision-free origin
                CP      B               ; Test whether the request has been fully satisfied
                JR      Z,Collision_Done ; No more candidate pixels remain
                JR      C,Probe_Right   ; An increasing destination moves right
                DEC     A               ; Test one pixel left, never the entire step at once
                LD      (Candidate_X),A ; Keep the candidate origin separate from its edge
                ADD     A,Box_Left      ; Probe the candidate's left leading column
                JR      Probe_Column    ; Both directions share the same vertical collision test
Probe_Right:    INC     A               ; Test one pixel right
                LD      (Candidate_X),A ; Retain the candidate origin while testing its edge
                ADD     A,Box_Right     ; Probe the candidate's right leading column
Probe_Column:   LD      C,0xF0          ; An even pixel uses the screen byte's high nibble
                BIT     0,A             ; Check the leading pixel's packed alignment
                JR      Z,Column_Mask_Ready ; Keep the high-nibble mask for an even edge
                LD      C,0x0F          ; An odd leading pixel uses the low nibble
Column_Mask_Ready: SRL A                ; Convert the collision pixel X to a packed byte offset
                LD      L,A             ; Begin forming the collision-map address
                LD      H,0             ; Clear the high byte of the horizontal offset
                LD      DE,(Sprite_Row+Box_Top)*128 ; Begin at the collision box's top row
                ADD     HL,DE           ; Locate the leading column in the separate map
                LD      B,Box_Bottom-Box_Top+1 ; Probe the whole collision box's vertical span
Column_Row:     LD      A,(HL)          ; Read solidity, not a rendered palette colour
                AND     C               ; Test only the leading pixel's selected nibble
                JR      NZ,Collision_Done ; Stop before entering the first occupied pixel
                LD      DE,128          ; Advance by one collision-map screen row
                ADD     HL,DE           ; Retain the same leading X
                DJNZ    Column_Row      ; Check every row, including both box corners
                LD      A,(Candidate_X) ; The complete leading column was empty
                LD      (Accepted_X),A ; Accept this one-pixel movement
                JR      Collision_Step  ; Test another pixel if the request was larger
Collision_Done: CALL    Restore_Lower    ; Restore ROM before interrupts or another HALT
                EI                      ; The original lower mapping is accessible again
                LD      A,(Accepted_X) ; Return the last safe origin, even for a blocked request
                RET                     ; Drawing and animation proceed independently of collision
