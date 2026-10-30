;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Collision                             |
; | Filename:   collision.asm                                                       |
; -----------------------------------------------------------------------------------
;
; The solidity mask and the box tests that movement uses.
;
Load_Collision: LD      A,Collision_Page ; Reuse the same 24 KB destination for every room
                CALL    Map_Lower       ; The compact source stream stays resident above the lower window
                LD      HL,Room_1_Collision ; Prepare the starting beach's run stream
                LD      A,(Current_Room) ; Keep collision and visible scenery selected by one identifier
                CP      1               ; Choose between the two connected rooms
                JR      Z,Collision_Stream ; Screen 1 retains the prepared pointer
                LD      HL,Room_2_Collision ; Screen 2 uses its cliff-side solidity
                CP      2               ; The sparse escape destination is the only additional room
                JR      Z,Collision_Stream ; Keep the prepared cliff mask
                LD      HL,Room_3_Collision ; Screen 3 is source-derived sparse sky, not a reward fixture
                CP      3               ; Only the fourth room needs a further collision selection
                JR      Z,Collision_Stream ; Keep the prepared sparse-room mask
                LD      HL,Room_4_Collision ; Screen 4 uses its real tree, clouds and grassy ground solidity
Collision_Stream: LD    DE,0            ; Expand starting at the collision plane's first byte
Collision_Run:  LD      C,(HL)          ; Read the run length's little-endian low byte
                INC     HL              ; Advance to the run length's high byte
                LD      B,(HL)          ; Complete the consecutive-byte count
                INC     HL              ; Advance to the packed solidity value
                LD      A,B             ; A zero word terminates this room's stream
                OR      C               ; Check both count bytes without inspecting beyond the terminator
                RET     Z               ; Chest support is tested separately, not painted into body solidity
                LD      A,(HL)          ; Read the repeated packed solidity byte
                INC     HL              ; Advance to the next resident run record
                PUSH    HL              ; Keep its pointer while H holds the repeated value
                LD      H,A             ; Retain the value independently of the loop's count test
Collision_Fill: LD      A,H             ; Recover the current run's packed empty/solid nibbles
                LD      (DE),A          ; Store one byte in the selected collision bank
                INC     DE              ; Advance through the complete 24 KB plane
                DEC     BC              ; Count one expanded byte
                LD      A,B             ; Test the full remaining run length
                OR      C               ; Runs can be longer than one byte can count
                JR      NZ,Collision_Fill ; Continue until all bytes in this run were written
                POP     HL              ; Recover the next resident run record
                JR      Collision_Run   ; Continue until the generated zero-word terminator
;
Has_Support:    LD      A,(Candidate_Y) ; Locate the row immediately below the collision box
                ADD     A,Box_Bottom+1  ; The last body row itself must remain empty
                LD      D,A             ; Give the row probe its screen Y
                LD      A,(Candidate_X) ; Locate the footprint's left pixel
                ADD     A,Box_Left      ; Apply the stable horizontal inset
                LD      E,A             ; Give the row probe its first screen X
                CALL    Solid_Row       ; Static terrain keeps its established support semantics
                RET     NZ              ; Do not replace real ground with a puzzle-specific result
                LD      A,(Current_Room) ; The placed chest supports only the cliff room
                CP      2               ; Never create a platform in another room
                JR      NZ,Support_None ; A false support result must return Z
                LD      A,(Chest_Placed) ; Carrying alone does not provide support
                OR      A               ; Require a successful physical trigger
                RET     Z               ; The unsolved chest is an ordinary collectible
                LD      A,(World_Items+4) ; Read the accepted drop's actual top row
                LD      B,A             ; Keep rendering and support at the same Y
                LD      A,(Candidate_Y) ; Only the feet resting on its top count as contact
                ADD     A,Box_Bottom+1  ; Upward body probes deliberately ignore this one-way support
                CP      B               ; Do not catch a player already below or inside the chest
                JR      NZ,Support_None ; Jump through it, then land on its top
                LD      A,(World_Items+3) ; Use the accepted drop's actual byte X
                ADD     A,A             ; Convert the support's left edge to pixels
                LD      B,A             ; Retain that inclusive left edge
                LD      A,(Candidate_X) ; Locate the footprint's inclusive right edge
                ADD     A,Box_Right     ; Transparent sprite margins do not provide support
                CP      B               ; Require at least one overlapping footprint pixel
                JR      C,Support_None ; A player entirely left of the chest is unsupported
                LD      A,B             ; Recover the chest's left edge
                ADD     A,20            ; Its extracted image is twenty pixels wide
                LD      B,A             ; Retain its exclusive right edge
                LD      A,(Candidate_X) ; Locate the footprint's left edge
                ADD     A,Box_Left      ; Use the same body inset as static ground
                CP      B               ; Equality is already outside the supporting top
                JR      NC,Support_None ; A player entirely right of the chest is unsupported
                LD      A,1             ; Report contact without moving or teleporting the player
                OR      A               ; Return NZ for this physical supporting top
                RET                     ; The existing landing resolver consumes the result
Support_None:   XOR     A               ; Return Z when neither terrain nor chest supports the feet
                RET                     ; Preserve the established support-call contract
;
Box_Clear:      LD      A,(Candidate_Y) ; Start with the proposed world origin
                ADD     A,Box_Top       ; Inspect the first row inside the stable body box
                LD      D,A             ; Keep the current collision row in D
                LD      A,(Candidate_X) ; Read the proposed horizontal origin
                ADD     A,Box_Left      ; Inspect the body's left inset rather than its drawing margin
                LD      E,A             ; Keep the first pixel of each body row in E
                LD      B,Box_Bottom-Box_Top+1 ; Include every row through the bottom of the box
Box_Row:        PUSH    BC              ; Preserve the body-row counter across the packed-row probe
                CALL    Solid_Row       ; Return NZ if any selected nibble in this body row is solid
                POP     BC              ; Recover the remaining rows without changing the result flags
                RET     NZ              ; A ceiling, side or floor inside the body rejects this candidate
                INC     D               ; Advance one screen row, keeping the same horizontal span
                DJNZ    Box_Row         ; Do not accept a box from corner probes alone
                XOR     A               ; Return Z when all body pixels were empty
                RET                     ; Leave D and E as scratch, with the result in flags
;
Solid_Row:      LD      H,D             ; Begin forming row Y times 256
                LD      L,0             ; Clear the lower byte before dividing that product by two
                SRL     H               ; Shift the high half towards the 128-byte row stride
                RR      L               ; Complete Y times 128 without losing an odd row's high bit
                LD      A,E             ; Read the first pixel's X
                SRL     A               ; Convert the pixel to a packed-byte offset
                ADD     A,L             ; Combine offsets; neither half-row can overflow this byte
                LD      L,A             ; Complete the first collision address
                LD      B,Box_Right-Box_Left+1 ; Count the selected pixels, not bytes outside the box
                BIT     0,E             ; An odd first pixel must ignore the byte's high nibble
                JR      Z,Solid_Bytes   ; An even first pixel begins with a complete packed pair
                LD      A,(HL)          ; Inspect the leading partial byte
                AND     0x0F            ; Only its low nibble belongs to this footprint
                RET     NZ              ; A selected solid nibble is sufficient
                INC     HL              ; Advance to the first complete packed pair
                DEC     B               ; Account for the single odd starting pixel
Solid_Bytes:    LD      A,B             ; Check whether fewer than two selected pixels remain
                CP      2               ; A final odd pixel must not inspect its neighbour
                JR      C,Solid_Last    ; Handle that final high nibble separately
                LD      A,(HL)          ; Both nibbles of this complete byte belong to the footprint
                OR      A               ; Any nonzero solidity nibble blocks this row
                RET     NZ              ; Preserve NZ as the collision result
                INC     HL              ; Advance to the next packed pair
                DEC     B               ; Account for the first pixel
                DEC     B               ; Account for the second pixel
                JR      NZ,Solid_Bytes  ; Continue while selected pixels remain
                XOR     A               ; All selected pixels were empty
                RET                     ; Return Z without inspecting a pixel outside the box
Solid_Last:     LD      A,(HL)          ; Read the final byte when one selected pixel remains
                AND     0xF0            ; Ignore its unrelated low nibble
                RET                     ; Return Z for empty or NZ for solid
;
                INCLUDE "assets\room-collision.asm" ; Compact source-derived masks stay resident
