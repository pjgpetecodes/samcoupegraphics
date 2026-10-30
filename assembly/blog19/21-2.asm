;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 21 - Part 2: Testing an Unsafe Drop      |
; | Filename:   blog19\21-2.asm                                                     |
; | Based on:   Tutorial 20 part 1 (blog18\20-1.asm)                                |
; -----------------------------------------------------------------------------------
;
; Isolate unsafe-drop rejection with an explicitly preloaded test inventory.
; Extra items are labelled teaching fixtures, not original placements.
; Z/X move left/right; Space and direction+Space retain the existing animations.
; The source palette is fixed for faithful scenery. Reset to stop.
;
; This file sets up the program and runs the main loop. Each feature has its
; own file, included below.
;
                ORG     0x8000          ; Resident code executes in the upper memory window
                DUMP    1,0             ; SAMDOS loads it into physical page 1
                AUTOEXEC                ; Call the program automatically after loading
                INCLUDE "constants_drop_test.asm" ; Ports, pages and tuning values; produces no bytes
;
Start:          DI                      ; Keep interrupts out while paging lower memory
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
                CALL    Read_Jump       ; A fresh grounded Space press changes velocity, not position
                CALL    Move_Sprite     ; Update position on every interrupt, not every frame
                CALL    Apply_Gravity   ; Fall even when no direction key is held
                CALL    Read_Collect    ; Enter picks up nearby items first, otherwise drops the stack top
                CALL    Show_Support    ; Black means supported; yellow means airborne
                CALL    Choose_Animation ; Choose which existing animation should play
                CALL    Update_Animation ; Advance its frame only when the delay expires
                JR      Animation_Loop  ; Wait for the next update
;
                INCLUDE "walking.asm"           ; Walking and ground following
                INCLUDE "items_inventory.asm"   ; Collecting, dropping and the inventory
                INCLUDE "rooms.asm"             ; Exits and room composition
                INCLUDE "collision.asm"         ; Solidity mask and box tests
                INCLUDE "jump_gravity.asm"      ; Jumping and gravity
                INCLUDE "screen_paging.asm"     ; Paging, screen copies and page flips
                INCLUDE "dizzy_sprite.asm"      ; Dizzy's animation and drawing
                INCLUDE "variables_drop_test.asm" ; Shared variables
                INCLUDE "sam_palette.asm"       ; Reuse the unchanged palette loader
;
Frame_Buffer:   DEFS    Frame_Size      ; Keep one complete frame in resident memory
Odd_Frame_Buffer: DEFS Odd_Frame_Size   ; Keep its one-pixel-shifted form resident too
Resident_End:                           ; Mark the end of code, state and frame buffer
                ASSERT  Resident_End < 0xC000 ; Keep all resident data below page 2 and the stack
                INCLUDE "paged_data.asm"        ; Sprites, scenery and data kept in other memory pages
