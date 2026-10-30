;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Walking                               |
; | Filename:   walking.asm                                                         |
; -----------------------------------------------------------------------------------
;
; Reading Z and X and stepping Dizzy left and right.
;
Move_Sprite:    LD      BC,0xFEFE       ; Select the Shift/Z/X/C/V keyboard row
                IN      A,(C)           ; Read the active-low direction bits
                BIT     1,A             ; Z is bit 1 and takes priority over X
                JR      Z,Move_Left     ; A zero bit means Z is held
                BIT     2,A             ; X is bit 2 of the same row
                RET     NZ              ; With neither key held, keep the current position
                LD      A,(Sprite_X)    ; Read the horizontal position in MODE 4 pixels
                CP      Maximum_X       ; Check whether the sprite already meets the right edge
                RET     Z               ; Do not advance beyond the last complete rectangle
                LD      A,(Move_Phase)  ; Alternate one- and three-pixel steps for Blog 8's average
                OR      A               ; Set Z for a one-pixel step
                JR      NZ,Move_Right_Three ; Use the three-pixel step on the alternate update
                LD      A,(Sprite_X)    ; Read the current pixel position
                INC     A               ; Move one pixel and switch packed-nibble alignment
                JR      Store_X         ; Save the new position and redraw
Move_Right_Three: LD    A,(Sprite_X)    ; Read the current pixel position
                ADD     A,3             ; Move three pixels and switch packed-nibble alignment
                CP      Maximum_X+1     ; Check whether the sprite would pass the right boundary
                JR      C,Store_X       ; Keep the proposed position when it still fits
                LD      A,Maximum_X     ; Clamp the final step to the last complete position
                JR      Store_X         ; Save the bounded position and redraw
Move_Left:      LD      A,(Sprite_X)   ; Read the position before moving left
                OR      A               ; Set Z if the leftmost byte is already zero
                RET     Z               ; Prevent unsigned underflow at the left edge
                LD      A,(Move_Phase)  ; Use the same one-/three-pixel cadence moving left
                OR      A               ; Set Z for a one-pixel step
                JR      NZ,Move_Left_Three ; Use the three-pixel step on the alternate update
                LD      A,(Sprite_X)    ; Read the current pixel position
                DEC     A               ; Move one pixel and switch packed-nibble alignment
                JR      Store_X         ; Save the new position and redraw
Move_Left_Three: LD     A,(Sprite_X)    ; Read the current pixel position
                CP      3               ; Check whether subtracting three would cross zero
                JR      C,Clamp_Left    ; Clamp small positions rather than wrapping unsigned X
                SUB     3               ; Move three pixels and switch packed-nibble alignment
                JR      Store_X         ; Save the new position and redraw
Clamp_Left:     XOR     A               ; Clamp a one- or two-pixel position to the left edge
Store_X:        LD      (Sprite_X),A   ; Store the new pixel position
                LD      A,(Move_Phase)  ; Read the step size just used
                XOR     1               ; Alternate between one- and three-pixel steps
                LD      (Move_Phase),A ; Keep a two-pixel average over each pair of updates
                JP      Draw_Frame      ; Redraw even when the animation frame has not changed
