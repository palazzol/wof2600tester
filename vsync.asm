
	processor 6502
	include "vcs.h"
	include "macro.h"

	org  $f000

; Now we're going to drive the TV signal properly.
; Assuming NTSC standards, we need the following:
; - 3 scanlines of VSYNC
; - 37 blank lines
; - 192 visible scanlines
; - 30 blank lines

; We'll use the VSYNC register to generate the VSYNC signal,
; and the VBLANK register to force a blank screen above
; and below the visible frame (it'll look letterboxed on
; the emulator, but not on a real TV)

; Let's define a variable to hold the starting color
; at memory address $81
BGColor1 equ $81
BGColor2 equ $82
PrevFrame equ $83
Temp     equ $84

	lda #0
        sta SWBCNT

; The CLEAN_START macro zeroes RAM and registers
Start	CLEAN_START
        
NextFrame
; Enable VBLANK (disable output)
	lda #2
        sta VBLANK
; At the beginning of the frame we set the VSYNC bit...
	lda #2
	sta VSYNC
; And hold it on for 3 scanlines...
	sta WSYNC
	sta WSYNC
	sta WSYNC
; Now we turn VSYNC off.
	lda #0
	sta VSYNC

; Now we need 37 lines of VBLANK...
	ldx #37
LVBlank	sta WSYNC	; accessing WSYNC stops the CPU until next scanline
	dex		; decrement X
	bne LVBlank	; loop until X == 0

; Re-enable output (disable VBLANK)
	lda #0
        sta VBLANK
; 192 scanlines are visible
; We'll draw some rainbows
	ldx #192
ScanLoop
	lda BGColor1	; load the background color out of RAM
	sta COLUBK	; set the background color
        
	sta WSYNC	; WSYNC doesn't care what value is stored
        dex
        
	lda BGColor2	; load the background color out of RAM
	sta COLUBK	; set the background color
   
	sta WSYNC	; WSYNC doesn't care what value is stored        
	dex
	bne ScanLoop

; Enable VBLANK again
	lda #2
        sta VBLANK
; 30 lines of overscan to complete the frame
	ldx #30
LVOver	sta WSYNC
	dex
	bne LVOver
	
; The next frame will start with current color value - 1
; to get a downwards scrolling effect
        
        bit INPT4	 ; read button
        bmi NoFireButton ; bit 7 set?

        lda PrevFrame    
        cmp #1
        bne Ahead
        
	lda SWCHB
        and #8
        cmp #8
        beq Ahead2
        
	lda BGColor1
        sta Temp
        lda BGColor2
        sta BGColor1
        lda Temp
        sta BGColor2
        
Ahead2
        lda #1
        sta PrevFrame
        jmp NextFrame
Ahead
	lda #10
	sta BGColor1
	lda #14
	sta BGColor2
        lda #1
        sta PrevFrame
        jmp NextFrame
        
NoFireButton
	lda #12  
	sta BGColor1
	lda #12
	sta BGColor2
        lda #0
        sta PrevFrame
        jmp NextFrame
        
; Go back and do another frame
	jmp NextFrame
	
	org $fffc
	.word Start
	.word Start
