;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Gravity and Landing                   |
; | Filename:   jump_gravity.asm                                                    |
; -----------------------------------------------------------------------------------
;
; Gravity and landing.
;
Apply_Gravity:  DI                      ; Keep interrupts out while reading banked collision RAM
                LD      A,Collision_Page ; Reuse the same static map as horizontal movement
                CALL    Map_Lower       ; Keep executable code, stack and state resident
                LD      A,(Sprite_X)    ; Probe support below the current accepted horizontal origin
                LD      (Candidate_X),A ; Give the established probes their candidate X
                LD      A,(Sprite_Y)    ; Begin with the current accepted vertical origin
                LD      (Candidate_Y),A ; Give the support probe its current Y
                CALL    Has_Support      ; A stationary player still needs a support check
                JR      NZ,Gravity_Land ; Stop falling immediately above the first supporting pixel
                XOR     A               ; There is no ground directly beneath the current footprint
                LD      (Grounded),A    ; Separate airborne state from the current animation
                LD      A,(Fall_Speed)  ; Read downward velocity in pixels per completed update
                CP      Maximum_Fall    ; Do not exceed the chosen terminal fall speed
                JR      NC,Gravity_Speed_Ready ; Keep the bounded speed once the cap is reached
                INC     A               ; Apply one pixel/update of downward acceleration
Gravity_Speed_Ready: LD (Fall_Speed),A ; Retain velocity for the next update
                LD      (Fall_Remaining),A ; Resolve this velocity as individual one-pixel candidates
Gravity_Pixel:  LD      A,(Candidate_Y) ; Read the last collision-free origin
                CP      192-Sprite_Rows ; Keep the complete drawing inside the bitmap
                JR      Z,Gravity_Boundary ; A screen boundary is not a solid landing surface
                INC     A               ; Test just one row lower to prevent tunnelling
                LD      (Candidate_Y),A ; Keep the proposed downward origin separate from world Y
                CALL    Box_Clear        ; Never enter solid terrain even at maximum fall speed
                JR      NZ,Gravity_Land ; Retain the previous safe world Y if the body would collide
                LD      A,(Candidate_Y) ; The complete body fits at the proposed row
                LD      (Sprite_Y),A    ; Accept this one-pixel downward movement
                CALL    Has_Support      ; Test contact after every accepted pixel, not only the endpoint
                JR      NZ,Gravity_Land ; Clamp on the first supporting row beneath the feet
                LD      A,(Fall_Remaining) ; Count how many one-pixel candidates remain this update
                DEC     A               ; Account for the row just accepted
                LD      (Fall_Remaining),A ; Preserve the count across collision probes
                JR      NZ,Gravity_Pixel ; Continue until velocity is consumed or contact occurs
                JR      Gravity_Done    ; Stay airborne and retain velocity for the next update
Gravity_Land:   LD      A,1             ; The last safe world origin is supported by solid terrain
                LD      (Grounded),A    ; Permit surface-following again on the next horizontal update
                XOR     A               ; Landing consumes all downward velocity
                LD      (Fall_Speed),A  ; Do not carry old fall speed onto the next ledge
                JR      Gravity_Done    ; Restore the ROM before drawing or waiting
Gravity_Boundary: XOR   A              ; Reaching the bitmap edge must not accumulate hidden velocity
                LD      (Fall_Speed),A  ; Remain unsupported; later room/death lessons handle this boundary
Gravity_Done:   CALL    Restore_Lower    ; Restore ROM and its working memory before interrupts
                EI                      ; The ROM interrupt handler is accessible again
                JP      Draw_Frame      ; Restore the hidden page's old X/Y and draw the accepted position
