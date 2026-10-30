;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 9 - Part 1: Banked Sprite Data           |
; | Filename:   blog7\9-1.asm                                                       |
; | Based on:   Tutorial 8 part 3 (blog6\8-3.asm)                                   |
; -----------------------------------------------------------------------------------
;
; Read the existing animation frames from banked sprite pages.
; Adds no movement or scenery.
; Z/X animate walking, Space rolls, Z/X+Space animate sideways jumps.
; Keys 1-5 change palette entry 0. Reset to stop.
;
                ORG     0x8000          ; Assemble resident code for CPU address 32768
                DUMP    1,0             ; Store it at offset zero in physical page 1
                AUTOEXEC                ; Ask SAMDOS to call this address after loading
;
LMPR:           EQU     250             ; Port selecting the lower pair of RAM pages
VMPR:           EQU     252             ; Port selecting the displayed screen and mode
Sprite_Page:    EQU     4               ; First of the two physical sprite-data pages
Screen_Page:    EQU     10              ; First screen starts at physical page 10
Frame_Delay:    EQU     5               ; Hold an animation frame for five interrupts
Sprite_Bytes:   EQU     13              ; Number of screen bytes across each cropped row
Sprite_Rows:    EQU     22              ; Number of rows in each cropped frame
Frame_Size:     EQU     Sprite_Bytes*Sprite_Rows*2 ; Mask and pixel bytes: 572 in total
Sprite_Start:   EQU     5*128+1         ; Draw at row 5, byte 1 of a 128-byte screen row
;
; Pages 1-2 stay mapped at 0x8000-0xFFFF: code, tables, buffer and stack.
; Pages 4-5 contain the sprites; pages 10-11 and 14-15 hold the screens.
;
Start:          DI                      ; Keep interrupts off while changing memory mappings
                IN      A,(LMPR)        ; Read the ROM and RAM mapping supplied by SAMDOS
                LD      (Saved_LMPR),A ; Keep the complete register value for restoration
                LD      SP,0xFF00       ; Place our stack in the resident upper memory
                XOR     A               ; Set A to zero for the initial background colour
                LD      (SAM_Palette),A ; Start with a black background
                LD      A,Screen_Page   ; Choose physical page 10 for the first screen
                LD      (Display_Page),A ; Remember which screen will be displayed
                CALL    Map_Lower       ; Make the first screen accessible at address zero
                CALL    Clear_Page      ; Fill its 24 KB of pixel memory with colour zero
                LD      A,Screen_Page+4 ; Choose page 14 for the other screen
                CALL    Map_Lower       ; Replace the lower window with that screen
                CALL    Clear_Page      ; Blank this screen before it can be displayed
                CALL    Restore_Lower   ; Restore ROM and working RAM before interrupts
                LD      A,Screen_Page+0x60 ; Combine the first screen page with MODE 4
                OUT     (VMPR),A        ; MODE 4, with our first screen displayed
                CALL    LoadPalette    ; Install our sixteen colours before the first frame
                LD      HL,Idle_Animation ; Select the two-frame idle sequence
                CALL    Set_Animation   ; Initialise it and draw its first hidden frame
;
Animation_Loop: HALT                    ; Wait for the ROM's next 50 Hz frame interrupt
                DI                      ; Keep the palette writes together
                CALL    LoadPalette    ; The ROM interrupt restores its palette
                EI                      ; ROM is mapped, so interrupts are safe again
                CALL    Show_Pending_Frame ; Display a completed frame if one is waiting
                CALL    Choose_Background ; Read the palette demonstration keys
                CALL    Choose_Animation ; Choose idle, walking, rolling or a jump
                CALL    Update_Animation ; Count down the current animation frame
                JR      Animation_Loop  ; Wait for the next interrupt and repeat
;
; A selects a physical page. Keep ROM1/write-protection flags unchanged;
; replace only the lower page number and the ROM0 mapping bit.
; The caller holds interrupts disabled until Restore_Lower has returned.
;
Map_Lower:      LD      C,A             ; Save the requested physical page number
                LD      A,(Saved_LMPR) ; Start with the original mapping flags
                AND     0b11000000      ; Keep ROM1 and write-protection flags only
                OR      0b00100000      ; Replace ROM0 with RAM in section A
                OR      C               ; Insert the requested lower page number
                OUT     (LMPR),A        ; Map this page and its successor into A and B
                RET                     ; Return through the unchanged resident stack
;
Restore_Lower:  LD      A,(Saved_LMPR) ; Recover the complete original register value
                OUT     (LMPR),A        ; Restore ROM0 and the ROM's working-memory mapping
                RET                     ; Return with the interrupt handler accessible
;
Clear_Page:     LD      HL,0            ; Point at the first pixel byte in the lower window
                LD      DE,1            ; Begin the repeated copy at the second byte
                LD      BC,0x5FFF       ; Copy the remaining 24 KB minus the first byte
                LD      (HL),0          ; Seed the fill with colour-zero pixels
                LDIR                    ; Propagate that zero across the whole screen
                RET                     ; Leave paging restoration to the caller
;
Choose_Background:                      ; Handle the five background-palette keys
                LD      BC,0xF7FE       ; Select the keyboard row containing keys 1 to 5
                IN      A,(C)           ; Read active-low key bits from port 0xFE
                LD      HL,Background_Colours ; Point to the five candidate CLUT values
                LD      B,5             ; Check five keys in numeric order
Background_Key: RRA                     ; Move the next key bit into carry
                JR      NC,Set_Background ; A pressed key has a zero bit, clearing carry
                INC     HL              ; Advance to the next key's colour
                DJNZ    Background_Key  ; Test the remaining keys without changing carry
                RET                     ; No background key was pressed
Set_Background: LD      A,(HL)          ; Fetch the selected hardware colour
                LD      (SAM_Palette),A ; Replace entry zero in our resident palette table
                RET                     ; The next palette load applies this change
;
Show_Pending_Frame:                     ; Flip only after hidden-page drawing has finished
                LD      A,(Frame_Pending) ; Check whether hidden-page drawing has finished
                OR      A               ; Set Z if there is no completed frame
                RET     Z               ; Keep displaying the current screen in that case
                XOR     A               ; Clear A to acknowledge the pending frame
                LD      (Frame_Pending),A ; Consume this completed frame only once
                LD      A,(Display_Page) ; Read the page currently on display
                XOR     4               ; Exchange screen starting pages 10 and 14
                LD      (Display_Page),A ; Remember the newly displayed page
                OR      0x60            ; Select MODE 4 along with its page number
                OUT     (VMPR),A        ; Show the completed screen without copying pixels
                RET                     ; Leave the other screen available for drawing
;
Choose_Animation:                       ; Read controls only when the sequence can be changed
                LD      HL,(Current_Animation) ; Find the active sequence header
                INC     HL              ; Skip its frame count to reach the loop flag
                LD      A,(HL)          ; Read one for looping, zero for playing once
                OR      A               ; Set Z for a sequence that must play to the end
                RET     Z               ; Finish each roll/jump before choosing again
                LD      BC,0x7FFE       ; Select the row containing Space
                IN      A,(C)           ; Read Space as active-low bit zero
                BIT     0,A             ; Set Z while Space is pressed
                JR      NZ,Choose_Walk  ; Without Space, choose walking or idle
                LD      BC,0xFEFE       ; Select the row containing Z and X
                IN      A,(C)           ; Read the direction-key bits
                LD      HL,Jump_Left_Animation ; Prepare a left jump if Z is down
                BIT     1,A             ; Test the active-low Z key
                JR      Z,Change_Animation ; Give Z priority when both directions are held
                LD      HL,Jump_Right_Animation ; Otherwise prepare a right jump
                BIT     2,A             ; Test the active-low X key
                JR      Z,Change_Animation ; Start the right jump while X is down
                LD      HL,Roll_Animation ; Space alone selects the roll
                JR      Change_Animation ; Compare it with the current sequence
;
Choose_Walk:    LD      BC,0xFEFE       ; Select the Z/X keyboard row without Space
                IN      A,(C)           ; Read the direction keys
                LD      HL,Walk_Left_Animation ; Prepare walking left
                BIT     1,A             ; Test whether Z is pressed
                JR      Z,Change_Animation ; Select the left-walk sequence if so
                LD      HL,Walk_Right_Animation ; Otherwise prepare walking right
                BIT     2,A             ; Test whether X is pressed
                JR      Z,Change_Animation ; Select the right-walk sequence if so
                LD      HL,Idle_Animation ; With neither key pressed, return to idle
;
Change_Animation:                       ; Avoid restarting the active sequence
                LD      DE,(Current_Animation) ; Get the existing sequence address
                OR      A               ; Clear carry before the 16-bit subtraction
                PUSH    HL              ; Preserve the proposed sequence address
                SBC     HL,DE           ; Set Z if the proposed and current addresses match
                POP     HL              ; Restore the proposal without changing the flags
                RET     Z               ; Do not restart an already playing sequence
;
Set_Animation:  LD      (Current_Animation),HL ; Store the new resident sequence address
                XOR     A               ; Select frame index zero
                LD      (Current_Frame),A ; Restart at the beginning of the sequence
                LD      A,Frame_Delay   ; Fetch the five-interrupt frame duration
                LD      (Current_Delay),A ; Start a full delay for this first frame
                JR      Draw_Frame      ; Draw the first frame immediately
;
Update_Animation:                       ; Advance a sequence after its frame delay expires
                LD      A,(Current_Delay) ; Read the remaining interrupt count
                DEC     A               ; Count this interrupt
                LD      (Current_Delay),A ; Store the new count without changing Z
                RET     NZ              ; Keep the current frame until the count is zero
                LD      A,Frame_Delay   ; Restart the five-interrupt delay
                LD      (Current_Delay),A ; Store the duration of the next frame
                LD      HL,(Current_Animation) ; Find the active sequence header
                LD      B,(HL)          ; Read the number of frames in this sequence
                LD      A,(Current_Frame) ; Read the current zero-based frame index
                INC     A               ; Advance to the proposed next frame
                CP      B               ; Compare that index with the frame count
                JR      C,Store_Frame   ; Carry means the proposed index is still valid
                INC     HL              ; At the sequence end, reach the loop flag
                LD      A,(HL)          ; Read whether this sequence loops
                OR      A               ; Set Z if it should finish after one pass
                LD      HL,Idle_Animation ; Prepare the next sequence without changing Z
                JR      Z,Set_Animation ; A completed roll or jump returns to idle
                XOR     A               ; A looping sequence returns to frame zero
Store_Frame:    LD      (Current_Frame),A ; Store the index and fall through to drawing
;
; Select the frame while the sequence tables are visible. Its address is
; relative to the 32 KB window where pages 4-5 will be mapped.
;
Draw_Frame:     DI                      ; Keep ROM interrupts out of the lower RAM window
                LD      A,(Current_Frame) ; Read the desired frame index
                LD      E,A             ; Put the index in the low byte of DE
                LD      D,0             ; Extend the index to a 16-bit value
                LD      HL,(Current_Animation) ; Find the resident animation table
                INC     HL              ; Skip the frame-count byte
                INC     HL              ; Skip the loop-flag byte
                ADD     HL,DE           ; Add the index once
                ADD     HL,DE           ; Add it again because each pointer is two bytes
                LD      E,(HL)          ; Read the selected frame pointer's low byte
                INC     HL              ; Advance to its high byte
                LD      D,(HL)          ; Complete the frame address in the lower window
                EX      DE,HL           ; Give LDIR its source address in HL
                LD      A,Sprite_Page   ; Choose physical pages 4 and 5
                CALL    Map_Lower       ; Make the frame data visible at its assembled address
                LD      DE,Frame_Buffer ; Keep the destination in resident upper RAM
                LD      BC,Frame_Size   ; Copy one complete 572-byte mask/pixel frame
                LDIR                    ; This also works across 0x3FFF/0x4000
;
; Banked sprites and screen RAM share the same lower window. Finish the copy
; before replacing that mapping with the hidden screen.
;
                LD      A,(Display_Page) ; Find which screen is currently being displayed
                XOR     4               ; Choose the other screen for drawing
                CALL    Map_Lower       ; Replace sprite pages with hidden screen RAM
                CALL    Clear_Sprite    ; Erase the previous frame at this fixed position
                LD      DE,Frame_Buffer ; Read the staged frame, not the now-hidden bank
                LD      HL,Sprite_Start ; Point at the cropped sprite's screen position
                CALL    Draw_Sprite     ; Combine the mask/pixel pairs with the screen
                CALL    Restore_Lower   ; Restore the ROM handler before enabling interrupts
                LD      A,1             ; Prepare the completed-frame flag
                LD      (Frame_Pending),A ; Allow the next main-loop pass to flip pages
                EI                      ; The ROM and its working memory are accessible again
                RET                     ; Return to the resident animation caller
;
Clear_Sprite:   LD      HL,Sprite_Start ; Point at the fixed screen rectangle to erase
                LD      C,Sprite_Rows   ; Count all 22 cropped rows
Clear_Row:      LD      B,Sprite_Bytes  ; Count 13 screen bytes in this row
Clear_Byte:     LD      (HL),0          ; Replace two pixels with background colour zero
                INC     HL              ; Move to the next screen byte
                DJNZ    Clear_Byte      ; Continue until this row's rectangle is clear
                LD      DE,128-Sprite_Bytes ; Skip the rest of the 128-byte screen stride
                ADD     HL,DE           ; Reach the rectangle's next row
                DEC     C               ; Count this completed row
                JR      NZ,Clear_Row    ; Continue until all cropped rows are clear
                RET                     ; Return with the hidden screen still mapped
;
Draw_Sprite:    LD      C,Sprite_Rows    ; Draw 22 rows from the resident frame buffer
Sprite_Row:     PUSH    BC              ; Preserve the row counter while C is scratch space
                LD      B,Sprite_Bytes   ; Draw 13 screen bytes in this row
Sprite_Byte:    LD      A,(DE)           ; Fetch the next transparency mask
                AND     (HL)            ; Keep background bits selected by the mask
                LD      C,A             ; Save those retained bits
                INC     DE              ; Advance from the mask to its pixel byte
                LD      A,(DE)          ; Fetch the cleaned sprite pixels
                OR      C               ; Combine sprite pixels with the retained background
                LD      (HL),A          ; Write two composed pixels to the hidden screen
                INC     DE              ; Advance to the next mask/pixel pair
                INC     HL              ; Advance to the next screen byte
                DJNZ    Sprite_Byte     ; Finish all 13 bytes in this row
                LD      BC,128-Sprite_Bytes ; Skip the untouched remainder of the screen row
                ADD     HL,BC           ; Reach the start of the next sprite row
                POP     BC              ; Recover the remaining row count in C
                DEC     C               ; Count this completed row
                JR      NZ,Sprite_Row   ; Continue while rows remain
                RET                     ; Return after drawing the complete frame
;
Saved_LMPR:     DEFB    0               ; Complete lower mapping to restore before HALT
Current_Animation: DEFW 0               ; Resident address of the active sequence header
Current_Frame:  DEFB    0               ; Zero-based index into that sequence's frame table
Current_Delay:  DEFB    0               ; Interrupts remaining before the next frame
Display_Page:   DEFB    0               ; Physical screen starting page: 10 or 14
Frame_Pending:  DEFB    0               ; One when hidden-page drawing is complete
Background_Colours: DEFB &00,&11,&22,&44,&7F ; Keys 1-5 select these hardware colours
;
Idle_Animation: DEFB    2,1             ; Two frames, with looping enabled
                DEFW    TIDizzy_1_Interleaved,TIDizzy_2_Interleaved ; Idle frame addresses
Roll_Animation: DEFB    8,0             ; Eight frames, played once
                DEFW    TIDizzy_1_Interleaved,TIDizzy_3_Interleaved ; Roll frames 1-2
                DEFW    TIDizzy_4_Interleaved,TIDizzy_5_Interleaved ; Roll frames 3-4
                DEFW    TIDizzy_6_Interleaved,TIDizzy_7_Interleaved ; Roll frames 5-6
                DEFW    TIDizzy_8_Interleaved,TIDizzy_9_Interleaved ; Roll frames 7-8
Walk_Left_Animation: DEFB 8,1           ; Eight left-walk frames, looping
                DEFW    TIDizzy_10_Interleaved,TIDizzy_11_Interleaved ; Left-walk frames 1-2
                DEFW    TIDizzy_12_Interleaved,TIDizzy_13_Interleaved ; Left-walk frames 3-4
                DEFW    TIDizzy_14_Interleaved,TIDizzy_15_Interleaved ; Left-walk frames 5-6
                DEFW    TIDizzy_16_Interleaved,TIDizzy_17_Interleaved ; Left-walk frames 7-8
Walk_Right_Animation: DEFB 7,1          ; Seven right-walk frames, looping
                DEFW    TIDizzy_18_Interleaved,TIDizzy_19_Interleaved ; Right-walk frames 1-2
                DEFW    TIDizzy_20_Interleaved,TIDizzy_21_Interleaved ; Right-walk frames 3-4
                DEFW    TIDizzy_22_Interleaved,TIDizzy_23_Interleaved ; Right-walk frames 5-6
                DEFW    TIDizzy_24_Interleaved ; Final right-walk frame
Jump_Left_Animation: DEFB 7,0           ; Seven left-jump frames, played once
                DEFW    TIDizzy_26_Interleaved,TIDizzy_27_Interleaved ; Left-jump frames 1-2
                DEFW    TIDizzy_28_Interleaved,TIDizzy_29_Interleaved ; Left-jump frames 3-4
                DEFW    TIDizzy_30_Interleaved,TIDizzy_31_Interleaved ; Cross the asset-page boundary
                DEFW    TIDizzy_32_Interleaved ; Final left-jump frame
Jump_Right_Animation: DEFB 7,0          ; Seven right-jump frames, played once
                DEFW    TIDizzy_33_Interleaved,TIDizzy_34_Interleaved ; Right-jump frames 1-2
                DEFW    TIDizzy_35_Interleaved,TIDizzy_36_Interleaved ; Right-jump frames 3-4
                DEFW    TIDizzy_37_Interleaved,TIDizzy_38_Interleaved ; Right-jump frames 5-6
                DEFW    TIDizzy_39_Interleaved ; Final right-jump frame
;
                INCLUDE "..\blog6\sam_palette.asm" ; Keep the existing loader and colour table
Frame_Buffer:   DEFS    Frame_Size      ; Reserve one complete frame in resident memory
Resident_End:                           ; Mark the first byte beyond resident code and data
                ASSERT  Resident_End < 0xC000 ; Require the resident area to fit in page 1
;
; ORG describes CPU addresses; DUMP selects physical destination pages.
; SAMDOS loads the complete page span, including the gap at physical page 3.
;
                ORG     0               ; Sprite labels describe addresses in the lower window
                DUMP    Sprite_Page,0   ; Store their bytes in physical pages 4 and 5
                INCLUDE "..\blog6\tidizzy_cropped.asm" ; Reuse all 38 unchanged cropped frames
Sprites_End:                            ; Mark the first byte beyond the banked sprites
                ASSERT  Sprites_End == Frame_Size*38 ; Check the expected 38-frame footprint
                ASSERT  Sprites_End < 0x8000 ; Require the sprites to fit in the two-page window
