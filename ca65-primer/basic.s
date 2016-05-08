;*********************************************************************
; COMMODORE VIC 20 BOOT USING BASIC 2.0
; written by Robert Hurst <robert@hurst-ri.us>
; updated version: 30-Oct-2011
;
		.fileopt author,	"your name"
        .fileopt comment,	"your program name"
        .fileopt compiler,	"VIC 20 ASSEMBLER"

		.include "VIC-SSS-MMX.h"

;*********************************************************************
; Commodore BASIC 2.0 program
;
; LOAD "YOUR PROGRAM.PRG",8
; RUN
;
		.segment "BASIC"

		.word	RUN		; load address
RUN:	.word	@end	; next line link
		.word	2010	; line number
		.byte	$9E		; BASIC token: SYS
		.byte	<(MAIN / 1000 .mod 10) + $30
		.byte	<(MAIN / 100 .mod 10) + $30
		.byte	<(MAIN / 10 .mod 10) + $30
		.byte	<(MAIN / 1 .mod 10) + $30
		.byte	0		; end of line
@end:	.word	0		; end of program

;*********************************************************************
; Starting entry point for this program
;
		.segment "STARTUP"

MAIN:
		LDX $FFFC
		LDY $FFFD
		STX $0318
		STY $0319		; enable RESTORE key as RESET
		LDA MACHINE
		CMP #$05
		BNE PAL
		;
		; NTSC setup
NTSC:	LDX #<@NTSC		; load the timer low-byte latches
		LDY #>@NTSC
		LDA #$69		; raster line 210/211
		BNE IRQSYNC
@NTSC = $4243			; (261 * 65 - 2)
		;
		; PAL setup
PAL:	LDX #<@PAL		; load the timer low-byte latches
		LDY #>@PAL
		LDA #$76		; raster line 228/229
@PAL = $5686			; (312 * 71 - 2)
		;
IRQSYNC:
		CMP VIC+$04
		BNE IRQSYNC
		STX $9126		; load T1 latch low
		STY $9125		; load T1 latch high, and transfer both to T1 counter


;*********************************************************************
; Now that all the VIC startup initialization stuff is completed,
; you can append one-time startup code/data here, i.e., like a splash
; title screen.  Then, you must jump to your CODE segment, linked
; outside of VIC's internal RAM address space ...
;
RUNONCE:
		;
		;====  INSERT ANY ADDITIONAL STARTUP CODE HERE  ====
		;
		JMP RESTART


;*********************************************************************
; VIC Software Sprite Stack 2010 (VIC-SSS-MMX)
;
; The above BASIC loader will be overwritten by SSS upon its
; initialization (SSSINIT).  The linker will fill this reserved space
; with values used for the dual video frame buffers, play field, and
; the sprite image buffers and registers: 4096 - 6207 ($1000 - $1BFF)
;
; $1000 - $11FF		VICFRAME1 - first video buffer
; $1200 - $13FF		VICFRAME2 - second video buffer
; $1400 - $15FF		PLAYFIELD - write-pending screen buffer
; $1600 - $17FF		PLAYCOLOR - write-pending color / dirty buffer
; $1800 - $1BFF		Sprite image buffers & registers
;
			.segment "SSSBUF"

SSSBUF:		.res 64 * 8		; this can be resized as required --
							; if all 64-chars are used by sprites, that
							; exhausts all 128 custom characters for
							; double-buffering (x2)
;
; SPRITE REGISTERS (17)
;
SPRITEBACK:	.res SPRITEMAX	; 1st char this sprite is in collision with
SPRITEBUFH:	.res SPRITEMAX	; pointer within sprite image buffer
SPRITEBUFL:	.res SPRITEMAX	; pointer within sprite image buffer
SPRITEC1H:	.res SPRITEMAX	; pointer within sprite display character pool
SPRITEC1L:	.res SPRITEMAX	; pointer within sprite display character pool
SPRITEC2H:	.res SPRITEMAX	; pointer within sprite display character pool
SPRITEC2L:	.res SPRITEMAX	; pointer within sprite display character pool
SPRITECOL:	.res SPRITEMAX	; 4-bit VIC color code
SPRITECX:	.res SPRITEMAX	; sprite collision X-coord
SPRITECY:	.res SPRITEMAX	; sprite collision Y-coord
SPRITEDEF:	.res SPRITEMAX	; function/matrix definition (see explanation below)
SPRITEH:	.res SPRITEMAX	; number of raster lines (1-16)
SPRITEIMGH:	.res SPRITEMAX	; pointer to source graphic for rendering at 0,0
SPRITEIMGL:	.res SPRITEMAX	; pointer to source graphic for rendering at 0,0
SPRITEX:	.res SPRITEMAX	; horizontal pixel coordinate, visible >0 - <SSSCLIPX
SPRITEY:	.res SPRITEMAX	; vertical pixel coordinate, visible >0 - <SSSCLIPY
SPRITEZ:	.res SPRITEMAX	; bit 0: last rendered (0 = SPRITEC1; 1 = SPRITEC2)
							; bit 1: fast copy (0 = merge; 1 = copy)
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
; - repeat		bit 4: flag: 0=independent, 1=same as previous
; - ghost		bit 5: flag: 0=merge image, 1=invert image
; - collision	bit 6: flag: 0=fast copy, 1=detect
; - enabled		bit 7: flag: 0=invisible, 1=visible
;
						; SSS runtime variables:
sss:		.res 24*2	; screen row index, computed from PLAYCOLS in SSSINIT
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

;*********************************************************************
; VIC Custom Graphic Characters
;
; If < 64 will be used for the software sprite stack, the remaining
; unused characters can be used for other custom graphics, beginning
; at $1C00 where "@", "A", "B", ... characters can be redefined.
;
; Do not use this as an initialized segment if you plan on linking
; this source as a future game cartridge later.  You must COPY any
; read-only data into this address space.
;
; If your data was saved from some tool in binary format, you can
; include that binary file here as:
;		.incbin "graphics.dat"
;
; else, just enter each 8x8 values here, such as:
;		.byte	$FF,$81,$81,$81,$81,$81,$81,$FF
; or:
;		.byte	%11111111	; square
;		.byte	%10000001
;		.byte	%10000001
;		.byte	%10000001
;		.byte	%10000001
;		.byte	%10000001
;		.byte	%10000001
;		.byte	%11111111
;
		.segment "MYCHAR"


;*********************************************************************
; Your main program code starts here
;
		.segment "CODE"

RESTART:
		.global RESTART

