;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorials - Room Draw Records                     |
; | Filename:   room-data.asm                                                       |
; -----------------------------------------------------------------------------------
;
; Generated seven-byte draw records; signed clipping is resolved offline.
;
Room_1: DEFB 85 ; Number of visible graphic blocks
                DEFW Room_Image_1+2 ; Source bytes after header and clipping
                DEFW 14009 ; Packed destination screen offset
                DEFB 11,21,11 ; Visible width, height and original source stride
                DEFW Room_Image_1+2 ; Source bytes after header and clipping
                DEFW 13333 ; Packed destination screen offset
                DEFB 11,21,11 ; Visible width, height and original source stride
                DEFW Room_Image_1+3 ; Source bytes after header and clipping
                DEFW 12800 ; Packed destination screen offset
                DEFB 10,21,11 ; Visible width, height and original source stride
                DEFW Room_Image_130+2 ; Source bytes after header and clipping
                DEFW 14646 ; Packed destination screen offset
                DEFB 8,16,8 ; Visible width, height and original source stride
                DEFW Room_Image_130+2 ; Source bytes after header and clipping
                DEFW 14622 ; Packed destination screen offset
                DEFB 8,16,8 ; Visible width, height and original source stride
                DEFW Room_Image_130+2 ; Source bytes after header and clipping
                DEFW 14800 ; Packed destination screen offset
                DEFB 8,16,8 ; Visible width, height and original source stride
                DEFW Room_Image_18+13 ; Source bytes after header and clipping
                DEFW 15872 ; Packed destination screen offset
                DEFB 21,68,32 ; Visible width, height and original source stride
                DEFW Room_Image_18+2 ; Source bytes after header and clipping
                DEFW 16916 ; Packed destination screen offset
                DEFB 32,60,32 ; Visible width, height and original source stride
                DEFW Room_Image_18+2 ; Source bytes after header and clipping
                DEFW 16948 ; Packed destination screen offset
                DEFB 32,60,32 ; Visible width, height and original source stride
                DEFW Room_Image_18+2 ; Source bytes after header and clipping
                DEFW 18753 ; Packed destination screen offset
                DEFB 32,46,32 ; Visible width, height and original source stride
                DEFW Room_Image_6+2 ; Source bytes after header and clipping
                DEFW 7311 ; Packed destination screen offset
                DEFB 41,77,41 ; Visible width, height and original source stride
                DEFW Room_Image_6+30 ; Source bytes after header and clipping
                DEFW 6784 ; Packed destination screen offset
                DEFB 13,77,41 ; Visible width, height and original source stride
                DEFW Room_Image_7+2 ; Source bytes after header and clipping
                DEFW 11732 ; Packed destination screen offset
                DEFB 25,51,25 ; Visible width, height and original source stride
                DEFW Room_Image_7+3 ; Source bytes after header and clipping
                DEFW 9856 ; Packed destination screen offset
                DEFB 24,51,25 ; Visible width, height and original source stride
                DEFW Room_Image_7+2 ; Source bytes after header and clipping
                DEFW 10788 ; Packed destination screen offset
                DEFB 25,51,25 ; Visible width, height and original source stride
                DEFW Room_Image_29+2 ; Source bytes after header and clipping
                DEFW 16155 ; Packed destination screen offset
                DEFB 15,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_5+2 ; Source bytes after header and clipping
                DEFW 16298 ; Packed destination screen offset
                DEFB 17,5,17 ; Visible width, height and original source stride
                DEFW Room_Image_5+2 ; Source bytes after header and clipping
                DEFW 16313 ; Packed destination screen offset
                DEFB 17,5,17 ; Visible width, height and original source stride
                DEFW Room_Image_4+2 ; Source bytes after header and clipping
                DEFW 16200 ; Packed destination screen offset
                DEFB 13,5,13 ; Visible width, height and original source stride
                DEFW Room_Image_29+2 ; Source bytes after header and clipping
                DEFW 15630 ; Packed destination screen offset
                DEFB 15,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_5+2 ; Source bytes after header and clipping
                DEFW 15232 ; Packed destination screen offset
                DEFB 17,5,17 ; Visible width, height and original source stride
                DEFW Room_Image_5+18 ; Source bytes after header and clipping
                DEFW 15232 ; Packed destination screen offset
                DEFB 1,5,17 ; Visible width, height and original source stride
                DEFW Room_Image_54+2 ; Source bytes after header and clipping
                DEFW 18296 ; Packed destination screen offset
                DEFB 8,50,33 ; Visible width, height and original source stride
                DEFW Room_Image_54+2 ; Source bytes after header and clipping
                DEFW 18268 ; Packed destination screen offset
                DEFB 33,50,33 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 20572 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 22108 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 23644 ; Packed destination screen offset
                DEFB 12,8,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 23645 ; Packed destination screen offset
                DEFB 12,8,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 21864 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 23400 ; Packed destination screen offset
                DEFB 12,10,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 23411 ; Packed destination screen offset
                DEFB 12,10,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 23423 ; Packed destination screen offset
                DEFB 1,10,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 20822 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 20045 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 22230 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+7 ; Source bytes after header and clipping
                DEFW 15744 ; Packed destination screen offset
                DEFB 7,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 15873 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16272 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16667 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16807 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16838 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_28+2 ; Source bytes after header and clipping
                DEFW 16208 ; Packed destination screen offset
                DEFB 14,10,14 ; Visible width, height and original source stride
                DEFW Room_Image_25+2 ; Source bytes after header and clipping
                DEFW 16992 ; Packed destination screen offset
                DEFB 7,25,7 ; Visible width, height and original source stride
                DEFW Room_Image_4+2 ; Source bytes after header and clipping
                DEFW 16469 ; Packed destination screen offset
                DEFB 13,5,13 ; Visible width, height and original source stride
                DEFW Room_Image_26+2 ; Source bytes after header and clipping
                DEFW 18273 ; Packed destination screen offset
                DEFB 13,18,13 ; Visible width, height and original source stride
                DEFW Room_Image_28+2 ; Source bytes after header and clipping
                DEFW 20331 ; Packed destination screen offset
                DEFB 14,10,14 ; Visible width, height and original source stride
                DEFW Room_Image_28+2 ; Source bytes after header and clipping
                DEFW 21365 ; Packed destination screen offset
                DEFB 11,10,14 ; Visible width, height and original source stride
                DEFW Room_Image_29+2 ; Source bytes after header and clipping
                DEFW 22399 ; Packed destination screen offset
                DEFB 1,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 17108 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 17360 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 18517 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 19803 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 20447 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 21353 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 22387 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 22516 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 23037 ; Packed destination screen offset
                DEFB 3,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_3+2 ; Source bytes after header and clipping
                DEFW 9069 ; Packed destination screen offset
                DEFB 19,10,44 ; Visible width, height and original source stride
                DEFW Room_Image_2+2 ; Source bytes after header and clipping
                DEFW 6384 ; Packed destination screen offset
                DEFB 16,21,38 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 16164 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 21365 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_8+27 ; Source bytes after header and clipping
                DEFW 20864 ; Packed destination screen offset
                DEFB 4,29,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+4 ; Source bytes after header and clipping
                DEFW 21248 ; Packed destination screen offset
                DEFB 27,26,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+2 ; Source bytes after header and clipping
                DEFW 21395 ; Packed destination screen offset
                DEFB 29,25,29 ; Visible width, height and original source stride
                DEFW Room_Image_9+2 ; Source bytes after header and clipping
                DEFW 22182 ; Packed destination screen offset
                DEFB 21,19,21 ; Visible width, height and original source stride
                DEFW Room_Image_12+2 ; Source bytes after header and clipping
                DEFW 23096 ; Packed destination screen offset
                DEFB 9,12,9 ; Visible width, height and original source stride
                DEFW Room_Image_10+2 ; Source bytes after header and clipping
                DEFW 23617 ; Packed destination screen offset
                DEFB 16,8,16 ; Visible width, height and original source stride
                DEFW Room_Image_12+2 ; Source bytes after header and clipping
                DEFW 21951 ; Packed destination screen offset
                DEFB 9,16,9 ; Visible width, height and original source stride
                DEFW Room_Image_12+2 ; Source bytes after header and clipping
                DEFW 19331 ; Packed destination screen offset
                DEFB 9,16,9 ; Visible width, height and original source stride
                DEFW Room_Image_16+2 ; Source bytes after header and clipping
                DEFW 23512 ; Packed destination screen offset
                DEFB 6,9,6 ; Visible width, height and original source stride
                DEFW Room_Image_16+2 ; Source bytes after header and clipping
                DEFW 19103 ; Packed destination screen offset
                DEFB 6,16,6 ; Visible width, height and original source stride
                DEFW Room_Image_16+2 ; Source bytes after header and clipping
                DEFW 18974 ; Packed destination screen offset
                DEFB 6,16,6 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 21040 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 20886 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 19597 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 21712 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 22228 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 23118 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 21672 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 20361 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 24039 ; Packed destination screen offset
                DEFB 5,5,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 19904 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16977 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_55+2 ; Source bytes after header and clipping
                DEFW 17910 ; Packed destination screen offset
                DEFB 10,4,20 ; Visible width, height and original source stride
                DEFW Room_Image_55+2 ; Source bytes after header and clipping
                DEFW 17890 ; Packed destination screen offset
                DEFB 20,4,20 ; Visible width, height and original source stride
Room_2: DEFB 90 ; Number of visible graphic blocks
                DEFW Room_Image_18+2 ; Source bytes after header and clipping
                DEFW 16475 ; Packed destination screen offset
                DEFB 32,64,32 ; Visible width, height and original source stride
                DEFW Room_Image_18+2 ; Source bytes after header and clipping
                DEFW 16571 ; Packed destination screen offset
                DEFB 32,63,32 ; Visible width, height and original source stride
                DEFW Room_Image_18+2 ; Source bytes after header and clipping
                DEFW 16540 ; Packed destination screen offset
                DEFB 32,63,32 ; Visible width, height and original source stride
                DEFW Room_Image_18+2 ; Source bytes after header and clipping
                DEFW 16506 ; Packed destination screen offset
                DEFB 6,64,32 ; Visible width, height and original source stride
                DEFW Room_Image_6+2 ; Source bytes after header and clipping
                DEFW 7209 ; Packed destination screen offset
                DEFB 41,77,41 ; Visible width, height and original source stride
                DEFW Room_Image_6+2 ; Source bytes after header and clipping
                DEFW 7650 ; Packed destination screen offset
                DEFB 30,77,41 ; Visible width, height and original source stride
                DEFW Room_Image_7+2 ; Source bytes after header and clipping
                DEFW 9245 ; Packed destination screen offset
                DEFB 25,51,25 ; Visible width, height and original source stride
                DEFW Room_Image_7+2 ; Source bytes after header and clipping
                DEFW 10175 ; Packed destination screen offset
                DEFB 25,51,25 ; Visible width, height and original source stride
                DEFW Room_Image_95+2 ; Source bytes after header and clipping
                DEFW 13258 ; Packed destination screen offset
                DEFB 11,22,11 ; Visible width, height and original source stride
                DEFW Room_Image_95+2 ; Source bytes after header and clipping
                DEFW 13562 ; Packed destination screen offset
                DEFB 6,22,11 ; Visible width, height and original source stride
                DEFW Room_Image_28+2 ; Source bytes after header and clipping
                DEFW 14780 ; Packed destination screen offset
                DEFB 14,10,14 ; Visible width, height and original source stride
                DEFW Room_Image_29+2 ; Source bytes after header and clipping
                DEFW 15554 ; Packed destination screen offset
                DEFB 15,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_24+2 ; Source bytes after header and clipping
                DEFW 15568 ; Packed destination screen offset
                DEFB 15,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_5+2 ; Source bytes after header and clipping
                DEFW 15071 ; Packed destination screen offset
                DEFB 17,5,17 ; Visible width, height and original source stride
                DEFW Room_Image_29+2 ; Source bytes after header and clipping
                DEFW 15470 ; Packed destination screen offset
                DEFB 15,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_24+2 ; Source bytes after header and clipping
                DEFW 15484 ; Packed destination screen offset
                DEFB 4,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 14470 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 15385 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 15710 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16110 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 15146 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 15927 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16202 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16347 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_8+22 ; Source bytes after header and clipping
                DEFW 9344 ; Packed destination screen offset
                DEFB 9,49,29 ; Visible width, height and original source stride
                DEFW Room_Image_15+2 ; Source bytes after header and clipping
                DEFW 15086 ; Packed destination screen offset
                DEFB 18,9,19 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 12942 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_29+2 ; Source bytes after header and clipping
                DEFW 13842 ; Packed destination screen offset
                DEFB 15,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_5+2 ; Source bytes after header and clipping
                DEFW 13984 ; Packed destination screen offset
                DEFB 17,5,17 ; Visible width, height and original source stride
                DEFW Room_Image_29+2 ; Source bytes after header and clipping
                DEFW 14253 ; Packed destination screen offset
                DEFB 15,5,15 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 14487 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 14889 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 14752 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 14625 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_9+2 ; Source bytes after header and clipping
                DEFW 13840 ; Packed destination screen offset
                DEFB 21,36,21 ; Visible width, height and original source stride
                DEFW Room_Image_16+2 ; Source bytes after header and clipping
                DEFW 17557 ; Packed destination screen offset
                DEFB 6,16,6 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 11920 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 12944 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16219 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 14897 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 15714 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16211 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 15268 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 14503 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16050 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16064 ; Packed destination screen offset
                DEFB 12,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_19+2 ; Source bytes after header and clipping
                DEFW 16120 ; Packed destination screen offset
                DEFB 8,12,12 ; Visible width, height and original source stride
                DEFW Room_Image_1+2 ; Source bytes after header and clipping
                DEFW 12519 ; Packed destination screen offset
                DEFB 11,21,11 ; Visible width, height and original source stride
                DEFW Room_Image_130+2 ; Source bytes after header and clipping
                DEFW 13027 ; Packed destination screen offset
                DEFB 8,16,8 ; Visible width, height and original source stride
                DEFW Room_Image_130+2 ; Source bytes after header and clipping
                DEFW 13529 ; Packed destination screen offset
                DEFB 8,16,8 ; Visible width, height and original source stride
                DEFW Room_Image_104+35 ; Source bytes after header and clipping
                DEFW 17280 ; Packed destination screen offset
                DEFB 2,57,35 ; Visible width, height and original source stride
                DEFW Room_Image_104+11 ; Source bytes after header and clipping
                DEFW 17280 ; Packed destination screen offset
                DEFB 26,57,35 ; Visible width, height and original source stride
                DEFW Room_Image_9+2 ; Source bytes after header and clipping
                DEFW 12928 ; Packed destination screen offset
                DEFB 21,36,21 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 17166 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+3 ; Source bytes after header and clipping
                DEFW 16128 ; Packed destination screen offset
                DEFB 4,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 17313 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 20394 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_16+2 ; Source bytes after header and clipping
                DEFW 21808 ; Packed destination screen offset
                DEFB 6,16,6 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 17830 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 16297 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 23481 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_9+2 ; Source bytes after header and clipping
                DEFW 8960 ; Packed destination screen offset
                DEFB 21,36,21 ; Visible width, height and original source stride
                DEFW Room_Image_8+21 ; Source bytes after header and clipping
                DEFW 13696 ; Packed destination screen offset
                DEFB 10,49,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+2 ; Source bytes after header and clipping
                DEFW 16261 ; Packed destination screen offset
                DEFB 29,49,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+2 ; Source bytes after header and clipping
                DEFW 18969 ; Packed destination screen offset
                DEFB 29,44,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+2 ; Source bytes after header and clipping
                DEFW 20529 ; Packed destination screen offset
                DEFB 29,32,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+2 ; Source bytes after header and clipping
                DEFW 21192 ; Packed destination screen offset
                DEFB 29,27,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+2 ; Source bytes after header and clipping
                DEFW 21473 ; Packed destination screen offset
                DEFB 29,25,29 ; Visible width, height and original source stride
                DEFW Room_Image_8+2 ; Source bytes after header and clipping
                DEFW 21496 ; Packed destination screen offset
                DEFB 8,25,29 ; Visible width, height and original source stride
                DEFW Room_Image_9+2 ; Source bytes after header and clipping
                DEFW 21521 ; Packed destination screen offset
                DEFB 21,24,21 ; Visible width, height and original source stride
                DEFW Room_Image_10+2 ; Source bytes after header and clipping
                DEFW 23587 ; Packed destination screen offset
                DEFB 16,8,16 ; Visible width, height and original source stride
                DEFW Room_Image_10+2 ; Source bytes after header and clipping
                DEFW 18990 ; Packed destination screen offset
                DEFB 16,15,16 ; Visible width, height and original source stride
                DEFW Room_Image_12+2 ; Source bytes after header and clipping
                DEFW 19273 ; Packed destination screen offset
                DEFB 9,16,9 ; Visible width, height and original source stride
                DEFW Room_Image_12+2 ; Source bytes after header and clipping
                DEFW 20340 ; Packed destination screen offset
                DEFB 9,16,9 ; Visible width, height and original source stride
                DEFW Room_Image_16+2 ; Source bytes after header and clipping
                DEFW 18496 ; Packed destination screen offset
                DEFB 6,16,6 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 20577 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 19054 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 20059 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 18206 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 18355 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 18588 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 20305 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 20720 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 19588 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 22287 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+6 ; Source bytes after header and clipping
                DEFW 8448 ; Packed destination screen offset
                DEFB 1,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+3 ; Source bytes after header and clipping
                DEFW 8960 ; Packed destination screen offset
                DEFB 4,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 8715 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 8719 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_9+58 ; Source bytes after header and clipping
                DEFW 6144 ; Packed destination screen offset
                DEFB 7,34,21 ; Visible width, height and original source stride
Room_3: DEFB 8 ; Number of visible graphic blocks
                DEFW Room_Image_8+29 ; Source bytes after header and clipping
                DEFW 21376 ; Packed destination screen offset
                DEFB 2,25,29 ; Visible width, height and original source stride
                DEFW Room_Image_12+6 ; Source bytes after header and clipping
                DEFW 22912 ; Packed destination screen offset
                DEFB 5,13,9 ; Visible width, height and original source stride
                DEFW Room_Image_3+25 ; Source bytes after header and clipping
                DEFW 10752 ; Packed destination screen offset
                DEFB 21,10,44 ; Visible width, height and original source stride
                DEFW Room_Image_3+2 ; Source bytes after header and clipping
                DEFW 14266 ; Packed destination screen offset
                DEFB 44,10,44 ; Visible width, height and original source stride
                DEFW Room_Image_2+2 ; Source bytes after header and clipping
                DEFW 11581 ; Packed destination screen offset
                DEFB 38,21,38 ; Visible width, height and original source stride
                DEFW Room_Image_2+22 ; Source bytes after header and clipping
                DEFW 8064 ; Packed destination screen offset
                DEFB 18,21,38 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 22016 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+6 ; Source bytes after header and clipping
                DEFW 22016 ; Packed destination screen offset
                DEFB 1,8,5 ; Visible width, height and original source stride
Room_4: DEFB 42 ; Number of visible graphic blocks
                DEFW Room_Image_135+25 ; Source bytes after header and clipping
                DEFW 17152 ; Packed destination screen offset
                DEFB 25,42,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 17165 ; Packed destination screen offset
                DEFB 48,42,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 15257 ; Packed destination screen offset
                DEFB 48,42,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 17700 ; Packed destination screen offset
                DEFB 48,42,48 ; Visible width, height and original source stride
                DEFW Room_Image_136+2 ; Source bytes after header and clipping
                DEFW 18632 ; Packed destination screen offset
                DEFB 49,25,49 ; Visible width, height and original source stride
                DEFW Room_Image_136+2 ; Source bytes after header and clipping
                DEFW 20043 ; Packed destination screen offset
                DEFB 49,25,49 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 17519 ; Packed destination screen offset
                DEFB 17,42,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 19312 ; Packed destination screen offset
                DEFB 16,42,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+34 ; Source bytes after header and clipping
                DEFW 19200 ; Packed destination screen offset
                DEFB 16,42,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 19721 ; Packed destination screen offset
                DEFB 48,38,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 19381 ; Packed destination screen offset
                DEFB 48,41,48 ; Visible width, height and original source stride
                DEFW Room_Image_135+2 ; Source bytes after header and clipping
                DEFW 20431 ; Packed destination screen offset
                DEFB 48,33,48 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21445 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21452 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21460 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21466 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21472 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21849 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21842 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21963 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21955 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21985 ; Packed destination screen offset
                DEFB 10,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 21626 ; Packed destination screen offset
                DEFB 6,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_86+2 ; Source bytes after header and clipping
                DEFW 22009 ; Packed destination screen offset
                DEFB 7,8,10 ; Visible width, height and original source stride
                DEFW Room_Image_88+2 ; Source bytes after header and clipping
                DEFW 22211 ; Packed destination screen offset
                DEFB 41,19,41 ; Visible width, height and original source stride
                DEFW Room_Image_88+2 ; Source bytes after header and clipping
                DEFW 22252 ; Packed destination screen offset
                DEFB 20,19,41 ; Visible width, height and original source stride
                DEFW Room_Image_88+2 ; Source bytes after header and clipping
                DEFW 22170 ; Packed destination screen offset
                DEFB 41,19,41 ; Visible width, height and original source stride
                DEFW Room_Image_88+17 ; Source bytes after header and clipping
                DEFW 22144 ; Packed destination screen offset
                DEFB 26,19,41 ; Visible width, height and original source stride
                DEFW Room_Image_12+2 ; Source bytes after header and clipping
                DEFW 20842 ; Packed destination screen offset
                DEFB 9,16,9 ; Visible width, height and original source stride
                DEFW Room_Image_10+2 ; Source bytes after header and clipping
                DEFW 19374 ; Packed destination screen offset
                DEFB 16,15,16 ; Visible width, height and original source stride
                DEFW Room_Image_10+2 ; Source bytes after header and clipping
                DEFW 20659 ; Packed destination screen offset
                DEFB 16,15,16 ; Visible width, height and original source stride
                DEFW Room_Image_9+2 ; Source bytes after header and clipping
                DEFW 20259 ; Packed destination screen offset
                DEFB 21,34,21 ; Visible width, height and original source stride
                DEFW Room_Image_14+2 ; Source bytes after header and clipping
                DEFW 23074 ; Packed destination screen offset
                DEFB 10,12,10 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 23835 ; Packed destination screen offset
                DEFB 5,6,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 22818 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_91+82 ; Source bytes after header and clipping
                DEFW 6144 ; Packed destination screen offset
                DEFB 38,134,59 ; Visible width, height and original source stride
                DEFW Room_Image_11+2 ; Source bytes after header and clipping
                DEFW 22394 ; Packed destination screen offset
                DEFB 6,18,10 ; Visible width, height and original source stride
                DEFW Room_Image_3+2 ; Source bytes after header and clipping
                DEFW 10723 ; Packed destination screen offset
                DEFB 29,10,44 ; Visible width, height and original source stride
                DEFW Room_Image_2+2 ; Source bytes after header and clipping
                DEFW 8038 ; Packed destination screen offset
                DEFB 26,21,38 ; Visible width, height and original source stride
                DEFW Room_Image_93+2 ; Source bytes after header and clipping
                DEFW 18635 ; Packed destination screen offset
                DEFB 13,31,13 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 21942 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
                DEFW Room_Image_17+2 ; Source bytes after header and clipping
                DEFW 21745 ; Packed destination screen offset
                DEFB 5,8,5 ; Visible width, height and original source stride
