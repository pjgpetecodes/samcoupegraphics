;-=-=-=-=-=-=-=-	=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;-  PROJECT: Animation Test For Peter
;-  AUTHOR:  Adrian Brown
;-  DATE:    26/11/2017
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

				ORG		&8000
				DUMP	1, &0000
				AUTOEXEC

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Start:
				; Set the stack - this is a test program so i havent bothered storing it elsewhere ;)
				ld		sp, Stack

				; Set the palette
				ld		hl, Palette
				ld		b, 16
				ld		e, 0
SetPalette:
				push	hl
				push	bc
				push	de
				ld		b, (hl)
				ld		c, b
				ld		a, &ff

				call	&0154

				pop		de
				pop		bc
				pop		hl

				inc		hl
				inc		e
				djnz	SetPalette

				; Set our animation
				ld		hl, Animation1
				call	SetAnimation

Loop:			halt

				; Do a simple check - only swap when on frame 0, if a key is pressed on that time play jump
				ld		a, (CurrentFrame)
				and		a
				jr		nz, DontChange

				call	&0169
				jr		z, NoKeySoIdle

				ld		hl, Animation2
				call	SetAnimation
				jr		DontChange

NoKeySoIdle:	
				ld		hl, Animation1
				call	SetAnimation

DontChange:
				; Update the animation
				call	UpdateAnimatedSprite
				
				; Show the page - not bothered with double buffering for this quick example
				ld		a, (VideoPage)
				or		&60
				out		(252), a

				; Draw the image... really we need to clear the old one etc
				ld		hl, 34 + 12800
				call	DrawAnimatedSprite
			
				jr		Loop

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

SetAnimation:
				ex		de, hl
				ld		hl, (Animation)
				
				; If its the same animation - dont worry
				xor		a
				sbc		hl, de
				ret		z

				ex		de, hl
				ld		(Animation), hl

				; Get this animation speed
				ld		a, (hl)
				ld		(AnimSpeed), a
				inc		hl

				; Get this animation number of frames
				ld		a, (hl)
				ld		(NumFrames), a
				inc		hl

				; Remember the animation frame start address
				ld		(AnimationFrameList), hl

				; Clear the current delay and frame
				xor		a
				ld		(CurrentDelay), a
				ld		(CurrentFrame), a
				ret

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

UpdateAnimatedSprite:
				; Hold each frame the right length of time (if its 255 we wrapped and so need the next frame)
				ld		a, (CurrentDelay)
				dec		a
				cp		255
				jr		z, NextFrame
				ld		(CurrentDelay), a
				ret

NextFrame:				
				; Reset it
				ld		a, (AnimSpeed)
				ld		(CurrentDelay), a

				; Move on the animation 
				ld		a, (NumFrames)
				ld		b, a
				ld		a, (CurrentFrame)
				inc		a
				cp		b
				jr		nz, NotLoopFrame
				xor		a
NotLoopFrame:
				ld		(CurrentFrame), a
				ret

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

DrawAnimatedSprite:
				push	hl

				; Get the frame number
				ld		a, (CurrentFrame)
				ld		e, a
				ld		d, 0

				; Get this from our frame index table
				ld		hl, (AnimationFrameList)
				add		hl, de
				ld		e, (hl)

				; Add it to the list of frames (twice as its words)
				ld		hl, GraphicFrames
				add		hl, de
				add		hl, de

				; Get the graphic pointer
				ld		a, (hl)
				inc		hl
				ld		h, (hl)
				ld		l, a

				; Recall the address
				pop		de

				call	DrawImage

				ret

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

DrawImage:
				di

				in		a, (250)
				ld		(lmpr + 1), a

				ld		a, (VideoPage)
				or		&20
				out		(250), a
				
				ld		b, 0
				ld		c, (hl)
				inc		hl
				ld		a, (hl)
				inc		hl
YLoop:			
				push	bc
				push	de
				ldir
				pop		de
				pop		bc
				push	hl
				ld		hl, 128
				add		hl, de
				ex		de, hl
				pop		hl
				dec		a
				jr		nz, YLoop
				
lmpr:			ld		a, 0
				out		(250), a
				ei

				ret

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Animation:		dw		0
AnimSpeed:		db		0
NumFrames:		db		0
AnimationFrameList:
				dw		0
CurrentDelay:	db		0
CurrentFrame:	db		0

GraphicFrames:
				dw		Image1
				dw		Image2
				dw		Image3
				dw		Image4
				dw		Image5
				dw		Image6
				dw		Image7
				dw		Image8
				dw		Image9
				dw		Image10
				dw		Image11
				dw		Image12
				dw		Image13
				dw		Image14
				dw		Image15


Animation1:
				db		4, 2
				db		0, 1

Animation2:
				db		2, 8
				db		0,2,3,4,5,6,7,8

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

				include "Dizzy.asm"

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

StackStart:		ds		256
Stack:
VideoPage:		db		30

;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
