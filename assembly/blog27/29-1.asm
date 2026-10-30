;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 29 - Part 1: The Complete Route          |
; | Filename:   blog27\29-1.asm                                                     |
; | Based on:   Tutorial 28 part 1 (blog26\28-1.asm)                                |
; -----------------------------------------------------------------------------------
;
; The complete four-screen route, from the beach to the coin on the rocks.
; No code changes; every feature file is copied unchanged.
; Z/X move, a fresh grounded Space press jumps, and Enter collects or drops items.
; The source palette is fixed for faithful scenery. Reset to stop.
;
; This file sets up the program and runs the main loop. Each feature has its
; own file, included below.
;
                ORG     0x8000          ; Resident code executes in the upper memory window
                DUMP    1,0             ; SAMDOS loads it into physical page 1
                AUTOEXEC                ; Call the program automatically after loading
                INCLUDE "constants.asm"         ; Ports, pages and tuning values; produces no bytes
;
Start:          DI                      ; Keep interrupts out while paging lower memory
                LD      HL,Game_State   ; Copy the world exactly as it was loaded from disk
                LD      DE,Initial_State ; Into a private snapshot that gameplay never changes
                LD      BC,Game_State_End-Game_State ; Room, puzzle, inventory and item records
                LDIR                    ; A restart copies this snapshot back
                IN      A,(LMPR)        ; Read SAMDOS's ROM and working-memory mapping
                LD      (Saved_LMPR),A ; Save that mapping for the ROM interrupt
                LD      SP,0xFF00       ; Keep the stack in resident physical page 2
                CALL    Build_Room      ; Compose the authoritative background from room records
                CALL    Load_Collision  ; Decode the matching static collision into its reusable bank
                LD      A,Screen_Page   ; Select the first screen's starting page
                LD      (Display_Page),A ; Record the displayed page for later flips
                CALL    Initialize_Screen ; Copy the complete scenery to the first display pair
                LD      A,Screen_Page+4 ; Select the second screen's starting page
                CALL    Initialize_Screen ; Give the second display pair the identical scenery
                CALL    Restore_Lower   ; Restore the ROM's expected lower mapping
                LD      A,Screen_Page+0x60 ; Combine page 10 with MODE 4's mode bits
                OUT     (VMPR),A        ; Display the first screen in MODE 4
                CALL    LoadPalette    ; Install the selected hardware colours
                LD      A,7             ; The original palette's index seven is black
                OUT     (254),A         ; Keep the border black rather than cyan
                LD      HL,Idle_Animation ; Start with the existing idle sequence
                CALL    Set_Animation   ; Draw its first frame on the hidden page
;
Animation_Loop: HALT                    ; Pace movement with the 50 Hz ROM interrupt
                DI                      ; Keep the sixteen palette writes together
                CALL    LoadPalette    ; Replace the ROM interrupt's palette settings
                EI                      ; The original lower mapping is restored
                CALL    Show_Pending_Frame ; Display the completed hidden-page drawing
                CALL    Advance_Water   ; Count interrupts and select the next wave frame on time
                CALL    Advance_Bee     ; Actors keep moving even while Dizzy is dying
                LD      A,(Death_Timer) ; Nonzero while the death pause is running
                OR      A               ; Set Z when Dizzy is alive
                JR      NZ,Dying        ; A dead Dizzy ignores input, physics and collection
                CALL    Read_Jump       ; A fresh grounded Space press changes velocity, not position
                CALL    Move_Sprite     ; Update position on every interrupt, not every frame
                CALL    Apply_Gravity   ; Fall even when no direction key is held
                CALL    Check_Hazards   ; Compare the settled body box with this room's hazard areas
                LD      A,(Hazard_Contact) ; Detection is unchanged; this is its new consequence
                OR      A               ; Set Z when the body is clear of every hazard
                JR      NZ,Start_Death  ; Touching a hazard ends this life immediately
                CALL    Read_Collect    ; Enter picks up nearby items first, otherwise drops the stack top
                CALL    Show_Support    ; Black means supported; yellow means airborne
                CALL    Choose_Animation ; Choose which existing animation should play
                CALL    Update_Animation ; Advance its frame only when the delay expires
                JR      Animation_Loop  ; Wait for the next update
;
                INCLUDE "death_restart.asm"     ; Death pause and restart
                INCLUDE "walking.asm"           ; Walking and ground following
                INCLUDE "items_inventory.asm"   ; Collecting, dropping and the inventory
                INCLUDE "rooms.asm"             ; Exits and room composition
                INCLUDE "collision.asm"         ; Solidity mask and box tests
                INCLUDE "jump_gravity.asm"      ; Jumping and gravity
                INCLUDE "hazards.asm"           ; Deadly rectangles, now including the bee
                INCLUDE "screen_paging.asm"     ; Paging, screen copies and page flips
                INCLUDE "water_animation.asm"   ; Animated sea
                INCLUDE "bee_actor.asm"         ; Patrolling bee that moves its hazard record
                INCLUDE "dizzy_sprite.asm"      ; Dizzy's animation and drawing
                INCLUDE "variables.asm"         ; Shared variables and the restart snapshot
                INCLUDE "sam_palette.asm"       ; Reuse the unchanged palette loader
;
Frame_Buffer:   DEFS    Frame_Size      ; Keep one complete frame in resident memory
Odd_Frame_Buffer: DEFS Odd_Frame_Size   ; Keep its one-pixel-shifted form resident too
Resident_End:                           ; Mark the end of code, state and frame buffer
                ASSERT  Resident_End < 0xC000 ; Keep all resident data below page 2 and the stack
                INCLUDE "paged_data.asm"        ; Sprites, scenery and data kept in other memory pages
