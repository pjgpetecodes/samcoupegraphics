;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Jumping and Gravity                   |
; | Filename:   jump_gravity.asm                                                    |
; -----------------------------------------------------------------------------------
;
; Jumping, gravity and landing.
;
Read_Jump:      LD      BC,0x7FFE       ; Select the active-low Space keyboard row
                IN      A,(C)           ; Read the key independently of animation selection
                AND     1               ; Retain only Space's released/pressed bit
                LD      B,A             ; Keep the current bit for edge detection
                LD      A,(Space_Previous) ; Read the preceding update's bit
                LD      C,A             ; Keep it while storing the new state
                LD      A,B             ; Read the current bit again
                LD      (Space_Previous),A ; Update even in mid-air or on landing
                OR      A               ; A nonzero bit means Space is released
                RET     NZ              ; Releasing Space rearms the next press
                LD      A,C             ; A zero previous bit means the key was already held
                OR      A               ; Only a released-to-pressed edge may request a jump
                RET     Z               ; Holding Space cannot auto-jump on landing
                LD      A,(Grounded)    ; Jumping requires support at the start of this update
                OR      A               ; Airborne presses are consumed, not queued
                RET     Z               ; Do not grant a second mid-air impulse
                XOR     A               ; Leave the surface before horizontal resolution
                LD      (Grounded),A    ; Disable surface snapping while the player rises
                LD      A,Jump_Impulse  ; Store the signed upward impulse
                LD      (Fall_Speed),A  ; The shared vertical resolver will apply gravity
                LD      BC,0xFEFE       ; Select the direction row for an appropriate jump image
                IN      A,(C)           ; Read left and right with the established priority
                LD      HL,Jump_Left_Animation ; Use left-facing frames when Z is held
                BIT     1,A             ; Z is active low
                JP      Z,Set_Animation ; Begin the jump image sequence without changing the physical arc
                LD      HL,Jump_Right_Animation ; Neutral and rightward jumps use the right-facing sequence
                JP      Set_Animation   ; Position and velocity remain independent of frame duration
;
Apply_Gravity:  DI                      ; Keep interrupts out while reading banked collision RAM
                LD      A,Collision_Page ; Reuse the same static map as horizontal movement
                CALL    Map_Lower       ; Keep executable code, stack and state resident
                LD      A,(Sprite_X)    ; Probe support below the current accepted horizontal origin
                LD      (Candidate_X),A ; Give the established probes their candidate X
                LD      A,(Sprite_Y)    ; Begin with the current accepted vertical origin
                LD      (Candidate_Y),A ; Give the support probe its current Y
                LD      A,(Fall_Speed)  ; Check direction before support so a launch can leave the floor
                BIT     7,A             ; Negative signed velocity means upward travel
                JR      NZ,Gravity_Up   ; A supported footprint must not cancel an upward impulse
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
                JR      Gravity_Done    ; Do not fall through into the upward resolver
Gravity_Up:     INC     A               ; Apply the same downward acceleration to negative velocity
                LD      (Fall_Speed),A  ; Retain the less-negative velocity for the following update
                OR      A               ; Zero velocity marks the apex, not a landing
                JR      Z,Gravity_Done  ; Begin downward acceleration on the next update
                NEG                     ; Convert signed upward speed to a positive pixel count
                LD      (Fall_Remaining),A ; Reuse the per-update one-pixel counter
Gravity_Up_Pixel: LD    A,(Candidate_Y) ; Start with the last collision-free origin
                CP      48              ; Keep the complete drawing below the HUD area
                JR      Z,Gravity_Ceiling ; Treat the upper bitmap limit as a stopped rise, not a floor
                DEC     A               ; Propose one row upward
                LD      (Candidate_Y),A ; Keep the proposal separate from accepted world Y
                CALL    Box_Clear        ; Check all body pixels against platforms and ceilings
                JR      NZ,Gravity_Ceiling ; Stop before the first occupied upward candidate
                LD      A,(Candidate_Y) ; The proposed body is entirely clear
                LD      (Sprite_Y),A    ; Accept just this row
                LD      A,(Fall_Remaining) ; Count accepted upward candidates
                DEC     A               ; Consume one pixel of this update's upward velocity
                LD      (Fall_Remaining),A ; Preserve the count across the next probe
                JR      NZ,Gravity_Up_Pixel ; Do not skip intermediate rows near a thin ceiling
                JR      Gravity_Done    ; Remain airborne while keeping the signed velocity
Gravity_Ceiling: XOR    A              ; A ceiling consumes upward speed but does not ground the player
                LD      (Fall_Speed),A  ; Downward acceleration begins on the next update
Gravity_Done:   CALL    Restore_Lower    ; Restore ROM and its working memory before interrupts
                EI                      ; The ROM interrupt handler is accessible again
                JP      Draw_Frame      ; Restore the hidden page's old X/Y and draw the accepted position
