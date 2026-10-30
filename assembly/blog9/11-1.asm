;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 11 - Part 1: Pixel Positioning           |
; | Filename:   blog9\11-1.asm                                                      |
; | Based on:   Tutorial 10 part 1 (blog8\10-1.asm)                                 |
; -----------------------------------------------------------------------------------
;
; Horizontal movement, one MODE 4 pixel at a time.
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
Sprite_Bytes:   EQU     13              ; Each cropped row contains 13 raw source bytes
Sprite_Rows:    EQU     22              ; Each frame contains 22 rows
Frame_Size:     EQU     Sprite_Bytes*Sprite_Rows*2 ; 572 interleaved mask/pixel bytes
Odd_Bytes:      EQU     Sprite_Bytes+1  ; An odd pixel offset needs one extra destination byte
Odd_Frame_Size: EQU     Odd_Bytes*Sprite_Rows*2 ; Padded odd-shift buffer: 616 interleaved bytes
Sprite_Row:     EQU     5               ; Keep the vertical position fixed for this lesson
Maximum_X:      EQU     230             ; The last pixel position fitting a 26-pixel-wide sprite
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
;
Build_Odd_Frame: LD     HL,Frame_Buffer ; Read the staged 13-byte-wide interleaved frame
                LD      DE,Odd_Frame_Buffer ; Write its one-pixel-shifted 14-byte rows
                LD      C,Sprite_Rows   ; Convert every row into its padded destination form
Build_Odd_Row:  PUSH    BC              ; Preserve the row count while C counts source pairs
                LD      A,(HL)          ; Read the first source mask byte
                LD      (Previous_Mask),A ; Retain it while composing the first output byte
                INC     HL              ; Advance to the matching source pixel byte
                LD      A,(HL)          ; Read the first source pixel byte
                LD      (Previous_Pixel),A ; Retain it for the first shifted pixel byte
                INC     HL              ; Advance to the second source mask byte
                LD      A,(Previous_Mask) ; Fetch the first mask pair
                RRCA                    ; Rotate its original high nibble into the low nibble
                RRCA                    ; Complete the four-bit alignment change
                RRCA                    ; Preserve both source nibbles for the next byte
                RRCA                    ; The original high nibble is now in the low nibble
                AND     0x0F            ; Keep only the source pixel's mask nibble
                OR      0xF0            ; Make the leading off-sprite nibble transparent
                LD      (DE),A          ; Store the leading shifted mask byte
                INC     DE              ; Advance to the paired shifted pixel byte
                LD      A,(Previous_Pixel) ; Fetch the first source pixel pair
                RRCA                    ; Move its original high nibble into the low nibble
                RRCA                    ; Rotate four places without losing either nibble
                RRCA                    ; Keep the first source pixel in the low nibble
                RRCA                    ; The leading destination nibble remains zero
                AND     0x0F            ; Discard the transparent source pixel nibble
                LD      (DE),A          ; Store the leading shifted pixel byte
                INC     DE              ; Advance to the next output mask
                LD      C,Sprite_Bytes-1 ; Twelve pairs remain between the leading and trailing bytes
Build_Odd_Pair: LD      A,(HL)          ; Read the next source mask byte
                LD      (Next_Mask),A   ; Save it while the shifted byte is composed
                RRCA                    ; Move the new source high nibble into the low nibble
                RRCA                    ; Complete half of the nibble rotation
                RRCA                    ; Keep the original high nibble available
                RRCA                    ; Put that nibble in the low half of A
                AND     0x0F            ; Isolate the next source mask nibble
                LD      B,A             ; Keep it while shifting the previous low nibble
                LD      A,(Previous_Mask) ; Read the previous source mask byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Keep the previous low nibble available
                RLCA                    ; Put that nibble in the high half of A
                AND     0xF0            ; Isolate the previous source mask nibble
                OR      B               ; Join adjacent source nibbles in destination order
                LD      (DE),A          ; Store one complete shifted mask byte
                INC     DE              ; Advance to the paired shifted pixel byte
                INC     HL              ; Advance to the matching source pixel byte
                LD      A,(HL)          ; Read the next source pixel byte
                LD      (Next_Pixel),A  ; Save it while composing the shifted pixel
                RRCA                    ; Move the next source high nibble into the low nibble
                RRCA                    ; Complete half of the nibble rotation
                RRCA                    ; Isolate the next source pixel
                RRCA                    ; Its high nibble now occupies the low nibble
                AND     0x0F            ; Keep only that next source pixel nibble
                LD      B,A             ; Preserve it while shifting the previous pixel
                LD      A,(Previous_Pixel) ; Read the previous source pixel byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Keep the previous source pixel available
                RLCA                    ; Its low nibble now occupies the high nibble
                AND     0xF0            ; Keep only that previous source pixel nibble
                OR      B               ; Join the two adjacent sprite pixels
                LD      (DE),A          ; Store one complete shifted pixel byte
                INC     DE              ; Advance to the next shifted mask byte
                INC     HL              ; Advance to the next source mask byte
                LD      A,(Next_Mask)   ; Retain the current mask for the following output
                LD      (Previous_Mask),A ; It becomes the preceding source mask byte
                LD      A,(Next_Pixel)  ; Retain the current pixel for the following output
                LD      (Previous_Pixel),A ; It becomes the preceding source pixel byte
                DEC     C               ; Count the twelve interior destination pairs
                JR      NZ,Build_Odd_Pair ; Continue until the last source pair is retained
                LD      A,(Previous_Mask) ; Read the final source mask byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Preserve the final source mask nibble
                RLCA                    ; The last source nibble now occupies the high half
                AND     0xF0            ; Keep the final source mask nibble
                OR      0x0F            ; Mark the trailing off-sprite nibble transparent
                LD      (DE),A          ; Store the trailing shifted mask byte
                INC     DE              ; Advance to the paired shifted pixel byte
                LD      A,(Previous_Pixel) ; Read the final source pixel byte
                RLCA                    ; Move its low nibble into the high nibble
                RLCA                    ; Complete half of the nibble rotation
                RLCA                    ; Preserve the final source pixel nibble
                RLCA                    ; The last source pixel now occupies the high half
                AND     0xF0            ; Leave the trailing off-sprite nibble zero
                LD      (DE),A          ; Store the trailing shifted pixel byte
                INC     DE              ; Finish the 14-byte destination row
                POP     BC              ; Recover the remaining source-row count
                DEC     C               ; Count this completed row
                JR      NZ,Build_Odd_Row ; Convert the next 13-byte source row
                RET                     ; Odd_Frame_Buffer now contains all 22 shifted rows
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
                LD      (Frame_Source),HL ; Retain the selected pointer while checking the cache
                LD      DE,(Cached_Frame) ; Read which animation frame is already staged
                OR      A               ; Clear carry before comparing the two addresses
                SBC     HL,DE           ; Set Z when this frame's source is already cached
                JR      Z,Frame_Ready   ; Reuse both resident buffers while the image is unchanged
                LD      HL,(Frame_Source) ; Restore the selected banked-frame address
                LD      A,Sprite_Page   ; Select physical sprite pages 4 and 5
                CALL    Map_Lower       ; Make the selected frame visible
                LD      DE,Frame_Buffer ; Stage the frame in resident memory
                LD      BC,Frame_Size   ; Copy its complete mask/pixel data
                LDIR                    ; Copy across a 16 KB boundary if necessary
                CALL    Build_Odd_Frame ; Prepare a one-pixel-shifted copy for odd X positions
                LD      HL,(Frame_Source) ; Recover the address of the frame just staged
                LD      (Cached_Frame),HL ; Avoid rebuilding this image during movement redraws
Frame_Ready:                            ; Both resident forms now match the selected animation frame
                LD      A,(Display_Page) ; Read the screen which must remain untouched
                XOR     4               ; Select the hidden screen
                CALL    Map_Lower       ; Replace the sprite mapping with screen RAM
                CALL    Clear_Sprite    ; Erase the old position belonging to this page
                LD      A,(Sprite_X)    ; Read the current pixel position
                AND     1               ; Odd X needs the padded 14-byte shifted frame
                JR      Z,Select_Even_Frame ; Even X can use the original 13-byte frame
                LD      A,Odd_Bytes     ; Select the wider destination-row length
                LD      (Draw_Width),A  ; Keep the width for the row drawing loop
                JR      Draw_Position   ; Continue with the same pixel-to-byte conversion
Select_Even_Frame: LD  A,Sprite_Bytes  ; Even X keeps the original 13-byte row width
                LD      (Draw_Width),A  ; Keep the width for the row drawing loop
Draw_Position:  LD      HL,Sprite_Row*128 ; Begin at the fixed screen row
                LD      A,(Sprite_X)    ; Read the horizontal pixel position
                SRL     A               ; Each MODE 4 byte contains two horizontal pixels
                LD      E,A             ; Put that offset in DE
                LD      D,0             ; Clear its high byte
                ADD     HL,DE           ; Add X to get the screen destination address
                LD      A,(Sprite_X)    ; Select the source form from the same X parity
                AND     1               ; A nonzero remainder means the position is odd
                LD      DE,Frame_Buffer ; Read the staged frame from resident RAM
                JR      Z,Draw_Selected_Frame ; Use unshifted data for an even position
                LD      DE,Odd_Frame_Buffer ; Use the padded data for an odd position
Draw_Selected_Frame:                    ; HL is the destination and DE is the matching frame
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
                LD      A,B             ; Read the old pixel position
                AND     1               ; Check its old packed-nibble alignment
                LD      A,Sprite_Bytes  ; Begin with the 13-byte even-position width
                JR      Z,Old_Width_Ready ; Even old X must not erase the next screen byte
                INC     A               ; Odd old X previously occupied 14 destination bytes
Old_Width_Ready: LD   (Old_Width),A    ; Save the width belonging to the old position
                LD      A,B             ; Read the old pixel position again
                SRL     A               ; Convert it to its starting screen byte
                LD      L,A             ; Build the old horizontal byte offset in HL
                LD      H,0             ; Clear its high byte
                LD      DE,Sprite_Row*128 ; Use the unchanged vertical position
                ADD     HL,DE           ; Point at this page's previous sprite rectangle
                LD      C,Sprite_Rows   ; Clear every cropped row
Clear_Row:      LD      A,(Old_Width)   ; Read exactly the previous position's width
                LD      B,A             ; Clear the old rectangle's actual width
Clear_Byte:     LD      (HL),0          ; Restore the plain background's colour-zero pixels
                INC     HL              ; Advance across the row
                DJNZ    Clear_Byte      ; Finish the old 13- or 14-byte width
                LD      A,(Old_Width)   ; Read the old row width for the next row address
                CP      Odd_Bytes       ; Odd old positions cover one extra screen byte
                LD      DE,128-Sprite_Bytes ; Even positions leave 115 bytes to the next row
                JR      NZ,Clear_Row_Offset ; Preserve that 13-byte row stride
                LD      DE,128-Odd_Bytes ; Odd positions leave 114 bytes to the next row
Clear_Row_Offset:                       ; DE now advances from the old row's first byte
                ADD     HL,DE           ; Reach the old rectangle's next row
                DEC     C               ; Count the completed row
                JR      NZ,Clear_Row    ; Continue until all rows are clear
                RET                     ; The caller can draw at the new position
;
Draw_Sprite:    LD      C,Sprite_Rows    ; Process all 22 frame rows
Draw_Row:       PUSH    BC              ; Save the row counter while C holds pixel scratch
                LD      A,(Draw_Width)  ; Read the current 13- or 14-byte destination width
                LD      B,A             ; Process the selected width on this frame row
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
                LD      A,(Draw_Width)  ; Read the current row width before advancing
                CP      Odd_Bytes       ; Odd positions occupy 14 destination bytes
                LD      BC,128-Sprite_Bytes ; Even positions leave 115 bytes to the next row
                JR      NZ,Draw_Row_Offset ; Keep the 13-byte destination stride
                LD      BC,128-Odd_Bytes ; Odd positions leave 114 bytes to the next row
Draw_Row_Offset:                        ; BC now advances from the current row's last byte
                ADD     HL,BC           ; Advance to the next destination row
                POP     BC              ; Recover the remaining row count
                DEC     C               ; Count the completed row
                JR      NZ,Draw_Row     ; Continue while rows remain
                RET                     ; Return after drawing the entire frame
;
Saved_LMPR:     DEFB    0               ; Original mapping required by the ROM interrupt
Sprite_X:       DEFB    1               ; Current horizontal position measured in pixels
Move_Phase:     DEFB    0               ; Zero selects one pixel, one selects three pixels
Previous_X_10:  DEFB    1               ; Pixel position last drawn on physical screen 10
Previous_X_14:  DEFB    1               ; Pixel position last drawn on physical screen 14
Draw_Width:     DEFB    0               ; Current 13- or 14-byte destination width
Old_Width:      DEFB    0               ; Previous page position's 13- or 14-byte width
Previous_Mask:  DEFB    0               ; Prior source mask used to join adjacent nibbles
Previous_Pixel: DEFB    0               ; Prior source pixel byte used to join adjacent nibbles
Next_Mask:      DEFB    0               ; Current source mask retained during nibble shifting
Next_Pixel:     DEFB    0               ; Current source pixel retained during nibble shifting
Frame_Source:   DEFW    0               ; Selected banked frame address while staging
Cached_Frame:   DEFW    0xFFFF          ; Invalid initial address forces the first frame copy
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
Odd_Frame_Buffer: DEFS Odd_Frame_Size   ; Keep its one-pixel-shifted form resident too
Resident_End:                           ; Mark the end of code, state and frame buffer
                ASSERT  Resident_End < 0xC000 ; Keep all resident data below page 2 and the stack
                ORG     0               ; Assemble frame pointers for the lower memory window
                DUMP    Sprite_Page,0   ; Store frame bytes in physical pages 4 and 5
                INCLUDE "..\blog6\tidizzy_cropped.asm" ; Reuse the previous 38 cropped frames
Sprites_End:                            ; Mark the end of the banked frame data
                ASSERT  Sprites_End == Frame_Size*38 ; Validate the expected frame footprint
                ASSERT  Sprites_End < 0x8000 ; Both sprite pages must fit in the lower window
