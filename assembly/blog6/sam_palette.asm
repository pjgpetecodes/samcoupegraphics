; CALL LoadPalette; preserves AF, BC, DE and HL
; B is the CLUT index; C is the port low byte.
; Writes all 16 entries; does not change the screen mode or HMPR.
; Not interrupt-atomic: manage interrupts in the caller if required.
LoadPalette:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD HL,SAM_Palette
    LD C,&F8
    LD B,0
    LD D,16
LoadPalette_Loop:
    LD A,(HL)
    OUT (C),A
    INC HL
    INC B
    DEC D
    JR NZ,LoadPalette_Loop
    POP HL
    POP DE
    POP BC
    POP AF
    RET

; SAM CLUT entries 0-15 (7-bit hardware colours)
SAM_Palette:
    DEFB &5D ; Index 0: colour 93 ($5D), RGB #24ffff
    DEFB &7F ; Index 1: colour 127 ($7F), RGB #ffffff
    DEFB &6E ; Index 2: colour 110 ($6E), RGB #ffff24
    DEFB &6A ; Index 3: colour 106 ($6A), RGB #ffb624
    DEFB &2A ; Index 4: colour 42 ($2A), RGB #ff2424
    DEFB &39 ; Index 5: colour 57 ($39), RGB #b624ff
    DEFB &1D ; Index 6: colour 29 ($1D), RGB #246dff
    DEFB &00 ; Index 7: colour 0 ($00), RGB #000000
    DEFB &6C ; Index 8: colour 108 ($6C), RGB #b6ff24
    DEFB &42 ; Index 9: colour 66 ($42), RGB #499200
    DEFB &24 ; Index 10: colour 36 ($24), RGB #924900
    DEFB &7E ; Index 11: colour 126 ($7E), RGB #ffffb6
    DEFB &59 ; Index 12: colour 89 ($59), RGB #24b6ff
    DEFB &77 ; Index 13: colour 119 ($77), RGB #dbdbdb
    DEFB &70 ; Index 14: colour 112 ($70), RGB #929292
    DEFB &07 ; Index 15: colour 7 ($07), RGB #494949
