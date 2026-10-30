;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Death and Restart                     |
; | Filename:   death_restart.asm                                                   |
; -----------------------------------------------------------------------------------
;
; One life, a flashing death pause and a restart from the snapshot.
;
Start_Death:    LD      A,Death_Delay   ; Begin the two-second death pause
                LD      (Death_Timer),A ; The main loop now skips every gameplay routine
                LD      HL,Idle_Animation ; Stop walking or jumping where Dizzy touched the hazard
                CALL    Set_Animation   ; Redraw him in the idle pose at the contact position
                JR      Animation_Loop  ; Wait for the next interrupt
;
Dying:          LD      A,(Death_Timer) ; Read the remaining pause
                DEC     A               ; Count this interrupt
                LD      (Death_Timer),A ; LD keeps DEC's zero flag
                JR      Z,Restart_Game  ; The pause is over; start again
                AND     8               ; Bit 3 changes every eight interrupts
                LD      A,4             ; Palette index four is red
                JR      NZ,Death_Border ; Show red for eight interrupts
                LD      A,7             ; Then black for eight, a slow flash
Death_Border:   OUT     (254),A         ; Flash the border while Dizzy is frozen
                CALL    Draw_Frame      ; Redraw him unchanged so the waves keep rolling over him
                JR      Animation_Loop  ; Wait for the next interrupt
;
Restart_Game:   LD      HL,Initial_State ; Read the boot-time snapshot
                LD      DE,Game_State   ; Overwrite the live room, puzzle, inventory and item state
                LD      BC,Game_State_End-Game_State ; The same length that Start saved
                LDIR                    ; Chest, coins and inventory return to their start
                XOR     A               ; Zero clears the transient state outside the snapshot
                LD      (Facing_Left),A ; Face right as at the very first start
                LD      (Move_Phase),A  ; Restart the one/three-pixel walking rhythm
                LD      (Hazard_Contact),A ; The start position is clear of every hazard
                LD      A,7             ; Palette index seven is black
                OUT     (254),A         ; Leave the flash on a black border
                LD      A,Start_X       ; Restore the starting X position
                LD      (Sprite_X),A    ; Enter_Room reads X from Sprite_X
                LD      A,Initial_Row   ; Restore the starting supported row
                CALL    Enter_Room      ; Rebuild room 1, its items, the empty HUD and both screens
                LD      HL,Idle_Animation ; Begin standing still, as at boot
                CALL    Set_Animation   ; Draw him at the start on the hidden page
                JP      Animation_Loop  ; Gameplay resumes on the next interrupt
;
Death_Timer:    DEFB    0               ; Interrupts left in the death pause; zero while alive
