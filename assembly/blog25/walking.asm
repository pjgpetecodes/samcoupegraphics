;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Walking                               |
; | Filename:   walking.asm                                                         |
; -----------------------------------------------------------------------------------
;
; Reading Z and X, stepping Dizzy left and right and following the ground.
;
Move_Sprite:    LD      BC,0xFEFE       ; Select the Shift/Z/X/C/V keyboard row
                IN      A,(C)           ; Read the active-low direction bits
                BIT     1,A             ; Z is bit 1 and takes priority over X
                JR      Z,Move_Left     ; A zero bit means Z is held
                BIT     2,A             ; X is bit 2 of the same row
                RET     NZ              ; With neither key held, keep the current position
                XOR     A               ; Remember right-facing intent even if a wall blocks movement
                LD      (Facing_Left),A ; A later neutral jump must not choose an arbitrary direction
                LD      A,(Sprite_X)    ; Read the horizontal position in MODE 4 pixels
                CP      Maximum_X       ; Check whether the sprite already meets the right edge
                JP      Z,Exit_Right    ; A linked grounded exit can replace the room at this edge
                LD      A,(Grounded)    ; Give an airborne jump enough horizontal reach to clear the cliff
                OR      A               ; Ground walking keeps its established two-pixel average
                JR      Z,Move_Right_Three ; The long-step path selects four pixels in the air
                LD      A,(Move_Phase)  ; Alternate one- and three-pixel steps for Blog 8's average
                OR      A               ; Set Z for a one-pixel step
                JR      NZ,Move_Right_Three ; Use the three-pixel step on the alternate update
                LD      A,(Sprite_X)    ; Read the current pixel position
                INC     A               ; Move one pixel and switch packed-nibble alignment
                JR      Store_X         ; Save the new position and redraw
Move_Right_Three: LD   A,(Grounded)    ; Keep ground cadence separate from horizontal jump reach
                OR      A               ; Grounded long steps remain three pixels
                LD      B,3             ; Prepare the established long walking step
                JR      NZ,Right_Step_Ready ; Do not increase ground-walking speed
                INC     B               ; Four airborne pixels clear the lower rock before landing
Right_Step_Ready: LD   A,(Sprite_X)    ; Read the current pixel position
                ADD     A,B             ; Resolve every requested pixel through the existing collider
                CP      Maximum_X+1     ; Check whether the sprite would pass the right boundary
                JR      C,Store_X       ; Keep the proposed position when it still fits
                LD      A,Maximum_X     ; Clamp the final step to the last complete position
                JR      Store_X         ; Save the bounded position and redraw
Move_Left:      LD      A,1             ; Remember the player's last left-facing intent
                LD      (Facing_Left),A ; Releasing Z does not turn a neutral jump to the right
                LD      A,(Sprite_X)   ; Read the position before moving left
                OR      A               ; Set Z if the leftmost byte is already zero
                JP      Z,Exit_Left     ; A linked grounded exit can replace the room at this edge
                LD      A,(Grounded)    ; A leftward jump must cross the wall rather than fall beside it
                OR      A               ; Do not increase the established ground-walking speed
                JR      Z,Move_Left_Three ; The long-step path keeps airborne reach symmetric
                LD      A,(Move_Phase)  ; Use the same one-/three-pixel cadence moving left
                OR      A               ; Set Z for a one-pixel step
                JR      NZ,Move_Left_Three ; Use the three-pixel step on the alternate update
                LD      A,(Sprite_X)    ; Read the current pixel position
                DEC     A               ; Move one pixel and switch packed-nibble alignment
                JR      Store_X         ; Save the new position and redraw
Move_Left_Three: LD    A,(Grounded)    ; Ground walking retains the established long-step size
                OR      A               ; Use the same airborne reach in either direction
                LD      B,3             ; Prepare three pixels for the alternating walking cadence
                JR      NZ,Left_Step_Ready ; Do not increase ground-walking speed
                INC     B               ; Four airborne pixels cross the wall before the arc descends
Left_Step_Ready: LD    A,(Sprite_X)    ; Read the current pixel position
                CP      B               ; Check whether this step would cross zero
                JR      C,Clamp_Left    ; Clamp small positions rather than wrapping unsigned X
                SUB     B               ; The collider still resolves the chosen step one pixel at a time
                JR      Store_X         ; Save the new position and redraw
Clamp_Left:     XOR     A               ; Clamp a one- or two-pixel position to the left edge
Store_X:        CALL    Constrain_X      ; Test each requested pixel before changing world position
                LD      (Sprite_X),A   ; Store only the movement allowed by separate solidity data
                LD      A,(Move_Phase)  ; Read the step size just used
                XOR     1               ; Alternate between one- and three-pixel steps
                LD      (Move_Phase),A ; Keep a two-pixel average over each pair of updates
                RET                     ; Gravity draws the final accepted X/Y once movement is complete
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
                JR      Ground_Candidate ; Resolve support and body clearance for this candidate
Probe_Right:    INC     A               ; Test one pixel right
Ground_Candidate: LD    (Candidate_X),A ; Keep the one-pixel candidate origin
                LD      A,(Grounded)    ; Airborne movement must not snap onto nearby platforms
                OR      A               ; Test the support state from the previous accepted position
                JR      Z,Ground_Unsupported ; Keep airborne horizontal movement at its current height
                LD      A,(Sprite_Y)    ; Search a bounded neighbourhood of the current feet
                ADD     A,Step_Height   ; Include a small downward step
                CP      192-Sprite_Rows+1 ; Never let the complete drawing leave the bitmap
                JR      C,Ground_Lower_Ready ; Retain a legal lower search limit
                LD      A,192-Sprite_Rows ; Clamp the candidate origin to the last complete row
Ground_Lower_Ready: LD  (Ground_Last_Y),A ; Keep the inclusive lower search limit
                LD      A,(Sprite_Y)    ; Read the current origin again for the upper limit
                SUB     Step_Height     ; Include only a small upward step
                CP      48              ; Keep the player below the reserved HUD region
                JR      NC,Ground_Upper_Ready ; Retain a legal upper search limit
                LD      A,48            ; Clamp the origin at the playfield's first row
Ground_Upper_Ready: LD  (Candidate_Y),A ; Start with the highest nearby candidate
Ground_Search:  CALL    Has_Support      ; Test the row immediately beneath the footprint first
                JR      Z,Ground_Next    ; Empty space below is not a grounded position
                CALL    Box_Clear        ; Support is useful only when the entire body fits above it
                JR      Z,Ground_Accept  ; Accept the highest supported, unobstructed candidate
Ground_Next:    LD      A,(Ground_Last_Y) ; Read the inclusive last candidate row
                LD      B,A             ; Keep it while comparing the current candidate
                LD      A,(Candidate_Y) ; Read the row just tested
                CP      B               ; Check whether all nearby surfaces were considered
                JR      Z,Ground_Unsupported ; Do not search farther down or up this frame
                INC     A               ; Inspect the next row within the limited step range
                LD      (Candidate_Y),A ; Retain the new candidate origin
                JR      Ground_Search   ; Retry support before the more expensive whole-body test
Ground_Unsupported: LD A,(Sprite_Y)     ; A ledge must not teleport the player to remote ground
                LD      (Candidate_Y),A ; Test horizontal clearance at the unchanged height
                CALL    Box_Clear        ; A tall wall still blocks movement without nearby support
                JR      NZ,Collision_Done ; Keep the last safe X and Y when the body cannot fit
                XOR     A               ; Mark the absence of reachable ground
                LD      (Grounded),A    ; Gravity will advance the unsupported position this update
                JR      Ground_Accept_X ; Keep horizontal resolution independent of downward speed
Ground_Accept:  LD      A,(Candidate_Y) ; Use the supported origin, not animation-frame bounds
                LD      (Sprite_Y),A    ; Follow the surface by the accepted small vertical change
                LD      A,1             ; The row beneath the footprint contains solid ground
                LD      (Grounded),A    ; Keep support state separate from animation
Ground_Accept_X:                        ; Both supported and unsupported candidates have a clear body
                LD      A,(Candidate_X) ; The complete candidate body was empty
                LD      (Accepted_X),A ; Accept this one-pixel movement
                JP      Collision_Step  ; Test another pixel and its ground if the request was larger
Collision_Done: CALL    Restore_Lower    ; Restore ROM before interrupts or another HALT
                EI                      ; The original lower mapping is accessible again
                LD      A,(Accepted_X) ; Return the last safe origin, even for a blocked request
                RET                     ; Drawing and animation proceed independently of collision
;
Show_Support:   LD      A,(Action_Flash) ; A rejected inventory action has temporary visible priority
                OR      A               ; Zero means the normal support marker should be displayed
                JR      Z,Show_Ground   ; Keep airborne feedback when no action failure is active
                DEC     A               ; Count completed updates rather than physical interrupts
                LD      (Action_Flash),A ; Preserve the remaining failure-pulse duration
                LD      A,3             ; Use a distinct palette border entry for rejected actions
                JR      Support_Border ; Do not change the scenery or inventory on failure
Show_Ground:    LD      A,(Grounded)    ; Support is a world-state property, not an animation frame
                OR      A               ; Set Z when the feet have no nearby supporting surface
                LD      A,7             ; A supported player keeps the established black border
                JR      NZ,Support_Border ; Do not change the scenery palette for debugging
                LD      A,2             ; A coloured border marks an unsupported player
Support_Border: OUT     (254),A         ; Reapply the status after the ROM interrupt
                RET                     ; Hazard contact is now shown by the death flash instead
