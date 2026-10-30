;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Hazards                               |
; | Filename:   hazards.asm                                                         |
; -----------------------------------------------------------------------------------
;
; Rectangles that are deadly to touch, tested against Dizzy's body box.
; Tutorial 28 change: the bee's body is a second, moving record in the table.
;
Check_Hazards:  XOR     A               ; Assume no contact until a rectangle overlaps the body
                LD      (Hazard_Contact),A ; Recompute contact from scratch on every update
                LD      IX,Hazard_Table ; Start at the first five-byte hazard record
                LD      DE,5            ; Each record holds room, left, right, top and bottom
Hazard_Test:    LD      A,(IX+0)        ; Read the record's room number
                OR      A               ; Room zero terminates the table
                RET     Z               ; No record overlapped the body this update
                LD      B,A             ; Keep the record's room while reading the current one
                LD      A,(Current_Room) ; Hazards belong to exactly one room's scenery
                CP      B               ; Compare the record with the displayed room
                JR      NZ,Hazard_Next  ; Ignore hazards drawn in other rooms
                LD      A,(Sprite_X)    ; Find the body's inclusive right edge
                ADD     A,Box_Right     ; Use the same footprint as solid collision
                CP      (IX+1)          ; Compare it with the hazard's left edge
                JR      C,Hazard_Next   ; The body is entirely left of the hazard
                LD      A,(Sprite_X)    ; Find the body's inclusive left edge
                ADD     A,Box_Left      ; Transparent sprite margins never touch hazards
                LD      B,A             ; Keep the body's left edge for the next comparison
                LD      A,(IX+2)        ; Read the hazard's inclusive right edge
                CP      B               ; Carry means the right edge is left of the body
                JR      C,Hazard_Next   ; The body is entirely right of the hazard
                LD      A,(Sprite_Y)    ; Find the body's inclusive bottom row
                ADD     A,Box_Bottom    ; The feet are the lowest body row
                CP      (IX+3)          ; Compare them with the hazard's top row
                JR      C,Hazard_Next   ; The body is entirely above the hazard
                LD      A,(Sprite_Y)    ; Find the body's inclusive top row
                ADD     A,Box_Top       ; Use the same inset as the solidity test
                LD      B,A             ; Keep the body's top row for the next comparison
                LD      A,(IX+4)        ; Read the hazard's inclusive bottom row
                CP      B               ; Carry means the hazard ends above the body
                JR      C,Hazard_Next   ; The body is entirely below the hazard
                LD      A,1             ; All four edge tests overlapped
                LD      (Hazard_Contact),A ; Record contact for the debug border to report
                RET                     ; One overlapping hazard is enough
Hazard_Next:    ADD     IX,DE           ; Advance to the next five-byte record
                JR      Hazard_Test     ; Continue until the zero terminator
;
Hazard_Contact: DEFB    0               ; One while the body box overlaps any hazard in this room
Hazard_Table:                           ; Room, left X, right X, top Y, bottom Y (all inclusive)
                DEFB    1,200,255,144,191 ; Starting beach sea, traced from the visible water pixels
Bee_Hazard:     DEFB    Bee_Room        ; A live record: Advance_Bee rewrites its left and right edges
                DEFB    Bee_Start_X*2+Bee_Box_Left ; Body left pixel at the start position
                DEFB    Bee_Start_X*2+Bee_Box_Right ; Body right pixel at the start position
                DEFB    Bee_Y+Bee_Box_Top,Bee_Y+Bee_Box_Bottom ; Body top and bottom rows
                DEFB    0               ; Room zero ends the table
