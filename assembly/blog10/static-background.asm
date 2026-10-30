;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Static Background Runtime             |
; | Filename:   static-background.asm                                               |
; -----------------------------------------------------------------------------------
;
; Shared runtime for the two static-background examples; no moving player yet.
;
                ORG     0x8000          ; Keep executing code above the banked lower window
                DUMP    1,0             ; Load resident code into physical page 1
                AUTOEXEC                ; Start automatically after SAMDOS loads the file
LMPR:           EQU     250             ; Select the lower RAM pair and ROM mapping
VMPR:           EQU     252             ; Select the displayed screen and graphics mode
Start:          DI                      ; Keep interrupts out while lower RAM replaces ROM
                IN      A,(LMPR)        ; Read the complete original lower mapping
                LD      (Saved_LMPR),A ; Preserve it for ROM interrupt handling
                LD      SP,0xFF00       ; Keep the stack in resident physical page 2
                LD      A,10            ; Select the initially visible blank screen
                CALL    Map_Lower       ; Make that screen available for clearing
                CALL    Clear_Page      ; Fill its 24 KB with palette index zero
                LD      A,10+0x60       ; Combine the initial page with MODE 4
                OUT     (VMPR),A        ; Display the cleared screen while building the next
                LD      A,14            ; Select the hidden screen pair
                CALL    Map_Lower       ; Map it without changing resident code or stack
                CALL    Clear_Page      ; Start from a complete colour-zero background
                LD      HL,Source_Start ; Point at the first packed source row
                LD      (Source_Pointer),HL ; Retain the source across mapping changes
                LD      HL,Destination  ; Point at the first destination row
                LD      (Screen_Pointer),HL ; Retain its address independently
                LD      A,Copy_Rows     ; Count the rows selected by the entry point
                LD      (Rows_Left),A  ; Store the count outside the banked window
Copy_Row:       LD      A,4             ; Select the bank pair containing the source image
                CALL    Map_Lower       ; Make its current row visible
                LD      HL,(Source_Pointer) ; Recover the source row address
                LD      DE,Row_Buffer   ; Stage it above the banked lower window
                LD      BC,Copy_Width   ; Copy exactly one packed source row
                LDIR                    ; Retain the row while the lower mapping changes
                LD      (Source_Pointer),HL ; Remember the following packed source row
                LD      A,14            ; Select the hidden display pair again
                CALL    Map_Lower       ; Replace the source mapping with the drawing target
                LD      HL,Row_Buffer   ; Read the resident copy, not unmapped source RAM
                LD      DE,(Screen_Pointer) ; Recover the destination row's first byte
                LD      BC,Copy_Width   ; Copy only the graphic's selected row width
                LDIR                    ; Write the complete packed row to the hidden screen
                LD      HL,(Screen_Pointer) ; Recover this row's start, not its final byte
                LD      DE,128          ; MODE 4 always has a 128-byte screen stride
                ADD     HL,DE           ; Advance one screen row regardless of image width
                LD      (Screen_Pointer),HL ; Retain the following destination address
                LD      A,(Rows_Left)  ; Recover the remaining source-row count
                DEC     A               ; Count the row just copied
                LD      (Rows_Left),A  ; LD preserves the zero flag from DEC
                JR      NZ,Copy_Row     ; Continue until the complete image is ready
                LD      A,(Saved_LMPR) ; Retrieve SAMDOS's original ROM mapping
                OUT     (LMPR),A        ; Restore it before any interrupt or HALT
                CALL    LoadPalette     ; Keep the source game's cyan colour-zero entry
                LD      A,7             ; Select palette index seven for the black border
                OUT     (254),A         ; Keep the border distinct from the cyan playfield
                LD      A,14+0x60       ; Select the completed screen in MODE 4
                OUT     (VMPR),A        ; Reveal scenery only after all rows are ready
                EI                      ; The ROM interrupt is safely mapped in
Static_Loop:    HALT                    ; Wait without changing the static screen pixels
                DI                      ; Keep the sixteen palette writes together
                CALL    LoadPalette     ; Replace palette values reset by the ROM interrupt
                EI                      ; Allow the next ROM interrupt
                JR      Static_Loop     ; Reset the emulator to leave this static example
Map_Lower:      LD      C,A             ; Retain the requested physical starting page
                LD      A,(Saved_LMPR) ; Recover the original mapping flags
                AND     0xC0            ; Preserve ROM1 and write-protection settings
                OR      0x20            ; Replace ROM0 with lower RAM
                OR      C               ; Insert the new page number without changing flags
                OUT     (LMPR),A        ; Code and stack remain resident above 0x8000
                RET                     ; Leave ROM restoration to the initialization code
Clear_Page:     LD      HL,0            ; Seed the first byte of mapped display RAM
                LD      DE,1            ; Begin the repeated fill one byte later
                LD      BC,0x5FFF       ; Fill the remaining 24 KB minus its seed byte
                LD      (HL),0          ; Palette index zero is the cyan sky in this post
                LDIR                    ; Fill every MODE 4 row
                RET                     ; Return with the chosen screen still mapped
Saved_LMPR:     DEFB    0               ; Original mapping used by the ROM interrupt
Source_Pointer: DEFW    0               ; Address within source pages 4 and 5
Screen_Pointer: DEFW    0               ; Address within hidden display pages 14 and 15
Rows_Left:      DEFB    0               ; Remaining packed source rows
Row_Buffer:     DEFS    128             ; One maximum-width row survives paging changes
                INCLUDE "..\blog6\sam_palette.asm" ; Reuse the original palette unchanged
Resident_End:                           ; Mark resident program, palette, state and buffer end
                ASSERT  Resident_End < 0xC000 ; Keep ample separation from the resident stack
                ASSERT  Destination/128+Copy_Rows <= 192 ; Keep every source row on screen
                ASSERT  (Destination & 127)+Copy_Width <= 128 ; Keep every row within its stride
