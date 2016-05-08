;*********************************************************************
; Commodore VIC 20 Software Sprite Stack - MMX Edition
; written by Robert Hurst <robert@hurst-ri.us>
; last updated: 30-Oct-2011
;
; use this for hard-coding RAM memory locations for
; sprite registers and run-time variables ...
;
SSSBUF		= $1800			; this can be resized smaller as required --
							; if all 64-chars are used by sprites, that
							; exhausts all 128 custom characters for
							; double-buffering (x2)
;
; SPRITE REGISTERS
;
SPRITEBACK	= SSSBUF + 64*8				; 1st char this sprite is in collision with
SPRITEBUFH	= SPRITEBACK + SPRITEMAX	; pointer within sprite image buffer
SPRITEBUFL	= SPRITEBUFH + SPRITEMAX	; pointer within sprite image buffer
SPRITEC1H	= SPRITEBUFL + SPRITEMAX	; pointer within sprite display character pool
SPRITEC1L	= SPRITEC1H + SPRITEMAX		; pointer within sprite display character pool
SPRITEC2H	= SPRITEC1L + SPRITEMAX		; pointer within sprite display character pool
SPRITEC2L	= SPRITEC2H + SPRITEMAX		; pointer within sprite display character pool
SPRITECOL	= SPRITEC2L + SPRITEMAX		; 4-bit VIC color code
SPRITECX	= SPRITECOL + SPRITEMAX		; sprite collision X-coord
SPRITECY	= SPRITECX + SPRITEMAX		; sprite collision Y-coord
SPRITEDEF	= SPRITECY + SPRITEMAX		; function/matrix definition (see explanation below)
SPRITEH		= SPRITEDEF + SPRITEMAX		; number of raster lines (1-16)
SPRITEIMGH	= SPRITEH + SPRITEMAX		; pointer to source graphic for rendering at 0,0
SPRITEIMGL	= SPRITEIMGH + SPRITEMAX	; pointer to source graphic for rendering at 0,0
SPRITEX		= SPRITEIMGL + SPRITEMAX	; horizontal pixel coordinate, visible >0 - <SSSCLIPX
SPRITEY		= SPRITEX + SPRITEMAX		; vertical pixel coordinate, visible >0 - <SSSCLIPY
SPRITEZ		= SPRITEY + SPRITEMAX		; bit 0: last rendered (0 = SPRITEC1; 1 = SPRITEC2)
										; bit 3: sprite collision
										; bit 4: sprite image is clipped by a static cell
										; bit 5: background is all SSSNULLs
										; bit 6: copy/merge into alternate sprite character pool
										; bit 7: copy/shift sprite image into its buffer
;
; SPRITEDEF is a bit-structure of these characteristics:
; - height		bit 0: 0 = 8px; 1 = 16px
; - width		bit 1: 0 = 8px; 1 = 16px
; - float Y		bit 2: flag: 0=fixed cell, 1=vertical float
; - float X		bit 3: flag: 0=fixed cell, 1=horizontal float
; - ghost		bit 5: flag: 0=merge image; 1=invert image
; - collision	bit 6: flag: 0=fast copy; 1=detect
; - enabled		bit 7: flag: 0=invisible; 1=visible
;
								; SSS runtime variables:
sss			= SPRITEZ + SPRITEMAX		; screen row index, computed from PLAYCOLS in SSSINIT
;
; other initialized data can be appended here:
;
			.segment "RODATA"
sssALLOC:	; 8x8, 16x8, 8x16, 16x16
			.byte	8,16,16,32	; fixed:	1,2,2,4
			.byte	16,24,32,48	; float Y:	2,3,4,6
			.byte	16,32,24,48	; float X:	2,4,3,6
			.byte	32,48,48,72	; both:		4,6,6,9
sssROWS:	.byte	1,2,1,2	; fixed
			.byte	2,3,2,3	; float Y
			.byte	1,2,1,2	; float X
			.byte	2,3,2,3	; both
sssCOLS:	.byte	1,1,2,2	; fixed
			.byte	1,1,2,2	; float Y
			.byte	2,2,3,3	; float X
			.byte	2,2,3,3	; both

