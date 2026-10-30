;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 10 - Part 1: Byte-Step Movement          |
; | Filename:   blog8\10-1.asm                                                      |
; | Based on:   Tutorial 9 part 1 (blog7\9-1.asm)                                   |
; -----------------------------------------------------------------------------------
;
; Horizontal movement, one screen byte at a time.
; This does not add scenery, collision or gravity.
; Z/X move left/right; Space and direction+Space retain the existing animations.
; Keys 1-5 change the background palette entry. Reset to stop.
;
                ORG     0x8000          ; Resident code executes in the upper memory window
                DUMP    1,0             ; SAMDOS loads it into physical page 1
                AUTOEXEC                ; Call the program automatically after loading
;
LMPR:           EQU     250             ; Lower Memory Page Register
VMPR:           EQU     252             ; Video Memory Page Register
Sprite_Page:    EQU     4               ; Cropped frames occupy physical pages 4 and 5
Screen_Page:    EQU     10              ; The screen pair starts at pages 10 and 14
Frame_Delay:    EQU     5               ; Animation frames last five interrupts
Sprite_Bytes:   EQU     13              ; Each cropped row covers 13 screen bytes
Sprite_Rows:    EQU     22              ; Each frame contains 22 rows
Frame_Size:     EQU     Sprite_Bytes*Sprite_Rows*2 ; 572 interleaved mask/pixel bytes
Sprite_Row:     EQU     5               ; Keep the vertical position fixed for this lesson
Maximum_X:      EQU     128-Sprite_Bytes ; The rightmost complete 13-byte rectangle is at 115
;
Start:          DI                      ; Keep interrupts out while paging lower memory
                IN      A,(LMPR)        ; Read SAMDOS's ROM and working-memory mapping
                LD      (Saved_LMPR),A ; Save that mapping for the ROM interrupt
                LD      SP,0xFF00       ; Keep the stack in resident physical page 2
                XOR     A               ; Start with black as hardware colour zero
                LD      (SAM_Palette),A ; Replace the palette table's background entry
                LD      A,Screen_Page   ; Select the first screen's starting page
                LD      (Display_Page),A ; Record the displayed page for later flips
                CALL    Map_Lower       ; Map the first screen into the lower window
                CALL    Clear_Page      ; Clear its full 24 KB of pixel memory
                LD      A,Screen_Page+4 ; Select the second screen's starting page
                CALL    Map_Lower       ; Map the second screen for clearing
                CALL    Clear_Page      ; Give it the same blank background
                CALL    Restore_Lower   ; Restore the ROM's expected lower mapping
                LD      A,Screen_Page+0x60 ; Combine page 10 with MODE 4's mode bits
                OUT     (VMPR),A        ; Display the first screen in MODE 4
                CALL    LoadPalette    ; Install the selected hardware colours
                LD      HL,Idle_Animation ; Start with the existing idle sequence
                CALL    Set_Animation   ; Draw its first frame on the hidden page
;
Animation_Loop: HALT                    ; Pace movement with the 50 Hz ROM interrupt
                DI                      ; Keep the sixteen palette writes together
                CALL    LoadPalette    ; Replace the ROM interrupt's palette settings
                EI                      ; The original lower mapping is restored
                CALL    Show_Pending_Frame ; Display the completed hidden-page drawing
                CALL    Choose_Background ; Retain the previous palette demonstration
                CALL    Move_Sprite     ; Update position on every interrupt, not every frame
                CALL    Choose_Animation ; Choose which existing animation should play
                CALL    Update_Animation ; Advance its frame only when the delay expires
                JR      Animation_Loop  ; Wait for the next update
;
Move_Sprite:    LD      BC,0xFEFE       ; Select the Shift/Z/X/C/V keyboard row
                IN      A,(C)           ; Read the active-low direction bits
                BIT     1,A             ; Z is bit 1 and takes priority over X
                JR      Z,Move_Left     ; A zero bit means Z is held
                BIT     2,A             ; X is bit 2 of the same row
                RET     NZ              ; With neither key held, keep the current position
                LD      A,(Sprite_X)   ; Read the horizontal position in screen bytes
                CP      Maximum_X       ; Check whether the sprite already meets the right edge
                RET     Z               ; Do not advance beyond the last complete rectangle
                INC     A               ; One screen byte moves two MODE 4 pixels
                JR      Store_X         ; Save the new position and redraw
Move_Left:      LD      A,(Sprite_X)   ; Read the position before moving left
                OR      A               ; Set Z if the leftmost byte is already zero
                RET     Z               ; Prevent unsigned underflow at the left edge
                DEC     A               ; Move left by one screen byte
Store_X:        LD      (Sprite_X),A   ; Store the new world-space horizontal position
                JP      Draw_Frame      ; Redraw even when the animation frame has not changed
;
Map_Lower:      LD      C,A             ; Save the requested physical page number
                LD      A,(Saved_LMPR) ; Retrieve the original register flags
                AND     0b11000000      ; Keep ROM1 and write-protection settings
                OR      0b00100000      ; Replace ROM0 with lower RAM
                OR      C               ; Insert the page number in bits 0-4
                OUT     (LMPR),A        ; Map the requested page and its successor
                RET                     ; Code and stack remain resident throughout
Restore_Lower:  LD      A,(Saved_LMPR) ; Retrieve the complete original lower mapping
                OUT     (LMPR),A        ; Make the ROM interrupt handler accessible again
                RET                     ; Return before the caller enables interrupts
Clear_Page:     LD      HL,0            ; Point at the start of the mapped screen
                LD      DE,1            ; Point the destination one byte later
                LD      BC,0x5FFF       ; Fill 24 KB after seeding the first byte
                LD      (HL),0          ; Seed the fill with background colour zero
                LDIR                    ; Repeat that byte across the screen
                RET                     ; Leave mapping restoration to the caller
;
Choose_Background:                      ; Retain the five background-palette keys
                LD      BC,0xF7FE       ; Select keys 1-5
                IN      A,(C)           ; Read their active-low keyboard bits
                LD      HL,Background_Colours ; Point at the five palette choices
                LD      B,5             ; Check five keys
Background_Key: RRA                     ; Shift the next key into carry
                JR      NC,Set_Background ; Carry clear means that key is held
                INC     HL              ; Advance to the next colour
                DJNZ    Background_Key  ; Continue until all five keys are tested
                RET                     ; Nothing pressed, so keep the current colour
Set_Background: LD      A,(HL)          ; Fetch the selected hardware colour
                LD      (SAM_Palette),A ; Update palette entry zero
                RET                     ; Apply it on the next palette reload
;
Show_Pending_Frame:                     ; Display only a fully completed hidden frame
                LD      A,(Frame_Pending) ; Check whether a complete drawing is waiting
                OR      A               ; Set Z when there is nothing to display
                RET     Z               ; Keep the current screen in that case
                XOR     A               ; Prepare a zero to acknowledge the frame
                LD      (Frame_Pending),A ; Consume the completed drawing
                LD      A,(Display_Page) ; Get the screen currently displayed
                XOR     4               ; Exchange physical starting pages 10 and 14
                LD      (Display_Page),A ; Record the newly displayed page
                OR      0x60            ; Keep the display in MODE 4
                OUT     (VMPR),A        ; Display the completed hidden screen
                RET                     ; The old displayed page is now available for drawing
;
Choose_Animation:                       ; Keep animation selection separate from movement
                LD      HL,(Current_Animation) ; Find the active sequence header
                INC     HL              ; Skip its frame count
                LD      A,(HL)          ; Read its loop flag
                OR      A               ; Zero identifies a roll or jump played once
                RET     Z               ; Do not interrupt that sequence
                LD      BC,0x7FFE       ; Select the Space keyboard row
                IN      A,(C)           ; Read the row's active-low bits
                BIT     0,A             ; Test Space
                JR      NZ,Choose_Walk  ; Without Space, choose walking or idle
                LD      BC,0xFEFE       ; Select Z and X
                IN      A,(C)           ; Read the held direction
                LD      HL,Jump_Left_Animation ; Prepare the left-jump sequence
                BIT     1,A             ; Test Z
                JR      Z,Change_Animation ; Prefer the left sequence while Z is held
                LD      HL,Jump_Right_Animation ; Otherwise prepare a right jump
                BIT     2,A             ; Test X
                JR      Z,Change_Animation ; Select it while X is held
                LD      HL,Roll_Animation ; Space alone selects the existing roll
                JR      Change_Animation ; Compare it with the current sequence
Choose_Walk:    LD      BC,0xFEFE       ; Select the direction-key row
                IN      A,(C)           ; Read Z and X
                LD      HL,Walk_Left_Animation ; Prepare the left-walk sequence
                BIT     1,A             ; Test Z
                JR      Z,Change_Animation ; Start or continue walking left
                LD      HL,Walk_Right_Animation ; Otherwise prepare walking right
                BIT     2,A             ; Test X
                JR      Z,Change_Animation ; Start or continue walking right
                LD      HL,Idle_Animation ; Neither direction held selects idle
Change_Animation:                       ; Compare the proposed sequence with the active one
                LD      DE,(Current_Animation) ; Read the active sequence address
                OR      A               ; Clear carry for the address comparison
                PUSH    HL              ; Preserve the proposed sequence
                SBC     HL,DE           ; Set Z when the two sequence addresses match
                POP     HL              ; Restore the proposal without changing Z
                RET     Z               ; Do not restart the same animation repeatedly
Set_Animation:  LD      (Current_Animation),HL ; Store the newly selected sequence
                XOR     A               ; Prepare the first frame index
                LD      (Current_Frame),A ; Start at frame zero
                LD      A,Frame_Delay   ; Fetch the five-interrupt frame duration
                LD      (Current_Delay),A ; Begin that delay
                JR      Draw_Frame      ; Draw the first frame immediately
Update_Animation:                       ; Advance animation at its own five-interrupt cadence
                LD      A,(Current_Delay) ; Read the remaining frame duration
                DEC     A               ; Count this interrupt
                LD      (Current_Delay),A ; Preserve DEC's zero flag while storing
                RET     NZ              ; Do not advance animation before the delay ends
                LD      A,Frame_Delay   ; Prepare another five-interrupt interval
                LD      (Current_Delay),A ; Start the next interval
                LD      HL,(Current_Animation) ; Find the sequence's frame count
                LD      B,(HL)          ; Keep the number of frames in B
                LD      A,(Current_Frame) ; Read the current index
                INC     A               ; Propose the next frame
                CP      B               ; Check whether it is still within the table
                JR      C,Store_Frame   ; Carry means the index is below the frame count
                INC     HL              ; At the sequence end, reach the loop flag
                LD      A,(HL)          ; Read whether the sequence loops
                OR      A               ; Set Z for a sequence which plays once
                LD      HL,Idle_Animation ; Prepare idle without changing Z
                JR      Z,Set_Animation ; Finish a roll or jump by returning to idle
                XOR     A               ; Loop a repeating sequence back to frame zero
Store_Frame:    LD      (Current_Frame),A ; Store the index and fall through to redraw
;
Draw_Frame:     DI                      ; Keep interrupts disabled while lower RAM is mapped
                LD      A,(Current_Frame) ; Find the selected frame index
                LD      E,A             ; Put it in the low byte of DE
                LD      D,0             ; Extend it to sixteen bits
                LD      HL,(Current_Animation) ; Find the active resident frame table
                INC     HL              ; Skip the frame count
                INC     HL              ; Skip the loop flag
                ADD     HL,DE           ; Add the index once
                ADD     HL,DE           ; Double it for two-byte frame pointers
                LD      E,(HL)          ; Read the frame pointer's low byte
                INC     HL              ; Advance to its high byte
                LD      D,(HL)          ; Complete the lower-window frame address
                EX      DE,HL           ; Give LDIR its source pointer in HL
                LD      A,Sprite_Page   ; Select physical sprite pages 4 and 5
                CALL    Map_Lower       ; Make the selected frame visible
                LD      DE,Frame_Buffer ; Stage the frame in resident memory
                LD      BC,Frame_Size   ; Copy its complete mask/pixel data
                LDIR                    ; Copy across a 16 KB boundary if necessary
                LD      A,(Display_Page) ; Read the screen which must remain untouched
                XOR     4               ; Select the hidden screen
                CALL    Map_Lower       ; Replace the sprite mapping with screen RAM
                CALL    Clear_Sprite    ; Erase the old position belonging to this page
                LD      HL,Sprite_Row*128 ; Begin at the fixed screen row
                LD      A,(Sprite_X)   ; Read the current horizontal byte offset
                LD      E,A             ; Put that offset in DE
                LD      D,0             ; Clear its high byte
                ADD     HL,DE           ; Add X to get the screen destination address
                LD      DE,Frame_Buffer ; Read the staged frame from resident RAM
                CALL    Draw_Sprite     ; Draw the sprite at its new position
                CALL    Restore_Lower   ; Restore ROM and its working memory
                LD      A,1             ; Prepare the completed-frame flag
                LD      (Frame_Pending),A ; Allow the next interrupt's loop to display it
                EI                      ; The ROM interrupt can safely run again
                RET                     ; Return to movement or animation code
;
Clear_Sprite:   LD      HL,Previous_X_10 ; Start with the old position for physical screen 10
                LD      A,(Display_Page) ; Infer which other page is currently hidden
                CP      Screen_Page     ; If 10 is displayed, we must erase screen 14
                JR      NZ,Old_Position ; Otherwise the first saved position is correct
                INC     HL              ; Select screen 14's saved horizontal position
Old_Position:   LD      B,(HL)          ; Keep the position last drawn on this hidden page
                LD      A,(Sprite_X)   ; Fetch the position we are about to draw
                LD      (HL),A          ; Remember it for this page's next erase
                LD      L,B             ; Build the old horizontal offset in HL
                LD      H,0             ; Clear its high byte
                LD      DE,Sprite_Row*128 ; Use the unchanged vertical position
                ADD     HL,DE           ; Point at this page's previous sprite rectangle
                LD      C,Sprite_Rows   ; Clear every cropped row
Clear_Row:      LD      B,Sprite_Bytes  ; Clear 13 bytes in the rectangle's current row
Clear_Byte:     LD      (HL),0          ; Restore the plain background's colour-zero pixels
                INC     HL              ; Advance across the row
                DJNZ    Clear_Byte      ; Finish all 13 bytes
                LD      DE,128-Sprite_Bytes ; Skip the rest of the screen stride
                ADD     HL,DE           ; Reach the old rectangle's next row
                DEC     C               ; Count the completed row
                JR      NZ,Clear_Row    ; Continue until all rows are clear
                RET                     ; The caller can draw at the new position
;
Draw_Sprite:    LD      C,Sprite_Rows    ; Process all 22 frame rows
Draw_Row:       PUSH    BC              ; Save the row counter while C holds pixel scratch
                LD      B,Sprite_Bytes   ; Process 13 screen bytes per row
Draw_Byte:      LD      A,(DE)          ; Read the next mask byte
                AND     (HL)            ; Retain the transparent background bits
                LD      C,A             ; Save those bits
                INC     DE              ; Advance to the paired pixel byte
                LD      A,(DE)          ; Read the cleaned sprite pixels
                OR      C               ; Combine the sprite with the retained background
                LD      (HL),A          ; Write the composed screen byte
                INC     DE              ; Advance to the next mask/pixel pair
                INC     HL              ; Advance to the next screen destination byte
                DJNZ    Draw_Byte       ; Finish this sprite row
                LD      BC,128-Sprite_Bytes ; Skip the untouched remainder of the screen row
                ADD     HL,BC           ; Advance to the next destination row
                POP     BC              ; Recover the remaining row count
                DEC     C               ; Count the completed row
                JR      NZ,Draw_Row     ; Continue while rows remain
                RET                     ; Return after drawing the entire frame
;
Saved_LMPR:     DEFB    0               ; Original mapping required by the ROM interrupt
Sprite_X:       DEFB    1               ; Current horizontal position measured in screen bytes
Previous_X_10:  DEFB    1               ; Position last drawn on physical screen 10
Previous_X_14:  DEFB    1               ; Position last drawn on physical screen 14
Current_Animation: DEFW 0               ; Resident sequence header address
Current_Frame:  DEFB    0               ; Zero-based index in the sequence's pointer table
Current_Delay:  DEFB    0               ; Interrupts remaining before the next animation frame
Display_Page:   DEFB    0               ; Physical screen starting page currently displayed
Frame_Pending:  DEFB    0               ; Completed hidden frame waiting for a flip
Background_Colours: DEFB &00,&11,&22,&44,&7F ; Hardware colours selected by keys 1-5
Idle_Animation: DEFB    2,1             ; Two idle frames which repeat
                DEFW    TIDizzy_1_Interleaved,TIDizzy_2_Interleaved ; Idle frame pointers
Roll_Animation: DEFB    8,0             ; Eight roll frames played once
                DEFW    TIDizzy_1_Interleaved,TIDizzy_3_Interleaved ; Roll frames 1-2
                DEFW    TIDizzy_4_Interleaved,TIDizzy_5_Interleaved ; Roll frames 3-4
                DEFW    TIDizzy_6_Interleaved,TIDizzy_7_Interleaved ; Roll frames 5-6
                DEFW    TIDizzy_8_Interleaved,TIDizzy_9_Interleaved ; Roll frames 7-8
Walk_Left_Animation: DEFB 8,1           ; Eight repeating left-walk frames
                DEFW    TIDizzy_10_Interleaved,TIDizzy_11_Interleaved ; Left-walk frames 1-2
                DEFW    TIDizzy_12_Interleaved,TIDizzy_13_Interleaved ; Left-walk frames 3-4
                DEFW    TIDizzy_14_Interleaved,TIDizzy_15_Interleaved ; Left-walk frames 5-6
                DEFW    TIDizzy_16_Interleaved,TIDizzy_17_Interleaved ; Left-walk frames 7-8
Walk_Right_Animation: DEFB 7,1          ; Seven repeating right-walk frames
                DEFW    TIDizzy_18_Interleaved,TIDizzy_19_Interleaved ; Right-walk frames 1-2
                DEFW    TIDizzy_20_Interleaved,TIDizzy_21_Interleaved ; Right-walk frames 3-4
                DEFW    TIDizzy_22_Interleaved,TIDizzy_23_Interleaved ; Right-walk frames 5-6
                DEFW    TIDizzy_24_Interleaved ; Last right-walk frame
Jump_Left_Animation: DEFB 7,0           ; Seven left-jump animation frames played once
                DEFW    TIDizzy_26_Interleaved,TIDizzy_27_Interleaved ; Left-jump frames 1-2
                DEFW    TIDizzy_28_Interleaved,TIDizzy_29_Interleaved ; Left-jump frames 3-4
                DEFW    TIDizzy_30_Interleaved,TIDizzy_31_Interleaved ; Frames spanning asset pages
                DEFW    TIDizzy_32_Interleaved ; Last left-jump frame
Jump_Right_Animation: DEFB 7,0          ; Seven right-jump animation frames played once
                DEFW    TIDizzy_33_Interleaved,TIDizzy_34_Interleaved ; Right-jump frames 1-2
                DEFW    TIDizzy_35_Interleaved,TIDizzy_36_Interleaved ; Right-jump frames 3-4
                DEFW    TIDizzy_37_Interleaved,TIDizzy_38_Interleaved ; Right-jump frames 5-6
                DEFW    TIDizzy_39_Interleaved ; Last right-jump frame
                INCLUDE "..\blog6\sam_palette.asm" ; Reuse the unchanged palette loader
Frame_Buffer:   DEFS    Frame_Size      ; Keep one complete frame in resident memory
Resident_End:                           ; Mark the end of code, state and frame buffer
                ASSERT  Resident_End < 0xC000 ; Keep all resident data below page 2 and the stack
                ORG     0               ; Assemble frame pointers for the lower memory window
                DUMP    Sprite_Page,0   ; Store frame bytes in physical pages 4 and 5
                INCLUDE "..\blog6\tidizzy_cropped.asm" ; Reuse the previous 38 cropped frames
Sprites_End:                            ; Mark the end of the banked frame data
                ASSERT  Sprites_End == Frame_Size*38 ; Validate the expected frame footprint
                ASSERT  Sprites_End < 0x8000 ; Both sprite pages must fit in the lower window
