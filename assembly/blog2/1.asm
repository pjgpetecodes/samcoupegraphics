               			autoexec					; Automatically Execute the Program
				ORG 		32768				; Store the program in User Address Space
;
; Print an ASCII Table with 96 Characters
;
print_test:			LD 		B,96				; We want 96 characters in our ASCII Tabe
				LD 		A,32				; 32 is the ASCII code for space

loop2:				LD		C,A				; Temp store for the A Register as it's zeroed by the RST 16 call below
				RST 		16				; Output A to current stream (Print the character in the A Register)
				LD		A,C				; Retrieve the A Register 
				ADD 		A,1				; Set for the next ASCII Character
				CP 		B				; Check if we've reached the last character
				JR 		NZ,loop2			; Keep looping until A=96
;
; Print a Text String
;
print_text:			LD 		HL,text2			; Set pointer to start of text 
				LD 		B,20				; Set up loop counter, 20 characters to print

print_loop:			LD 		A,(HL)				; Get character from pointer
				RST 		16				; Print character
				INC 		HL				; Move to next character
				DJNZ 		print_loop			; If we've not yet reach the last character, then loop
;
; Now we wait for the User to press a key
;
wait_for_key:			CALL		&0169				; Read the Keyboard (Zero if no key)
       				JR 		Z,wait_for_key  		; If no key pressed, then loop
										; A key was pressed....				
				RET						; Return back to BASIC
;
; Some Text Data
;
text2:				DM 		"Howsaboutis, then!!!"