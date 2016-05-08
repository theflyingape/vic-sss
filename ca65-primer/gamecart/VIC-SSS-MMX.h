;*********************************************************************
; Commodore VIC 20 Software Sprite Stack - MMX Edition
; written by Robert Hurst <robert@hurst-ri.us>
; last updated: 30-Oct-2011
;
; === IMPORTANT ===
; required symbols you need to define for your game:
;
;SPRITEDEF4	= $10		; un-comment this for "repeating" flag usage
SPRITEDEF5	= $20		; un-comment this for "ghost" flag usage
SPRITEDEF6	= $40		; un-comment this for "collision" flag usage
SPRITEWIDE	= 1			; comment this out to skip 16-bit wide sprites
SPRITEMAX	= 16		; reserves this many SPRITE registers (1-?)
SSSNULL		= $A0		; your character used for a blank background

;*********************************************************************
; some pertinent VIC 20 symbols
;
RNDSEED		= $8B		; -$8F: BASIC RND seed value
JIFFYH		= $A0		; jiffy clock high
JIFFYM		= $A1		; jiffy clock med
JIFFYL		= $A2		; jiffy clock low
DATANEXT	= $A6		; DATASETTE pointer (0-191)
KEYCHARS	= $C6		; number of characters in KEYBUF (0-10)
RVSFLAG		= $C7		; character reverse flag
PLAYROWS	= $C8		; current screen row length (16-24)
CURSOR		= $CC		; cursor enable (0=flash)
CRSRCHAR	= $CE		; character under cursor
SCRNLINE	= $D1		; pointer to cursor's screen line
CRSRCOL		= $D3		; position of cursor on screen line
PLAYCOLS	= $D5		; current screen line length (16-24)
CRSRROW		= $D6		; screen row where cursor is
COLORLINE	= $F3		; pointer to cursor's color line
INPUT		= $0200		; -$0258: 89-character BASIC INPUT buffer
KEYBUF		= $0277		; -$0280: 10-character keyboard buffer
COLORCODE	= $0286		; current cursor color
CRSRCOLOR	= $0287		; color under cursor
SCRNPAGE	= $0288		; active screen memory page (unexpanded = $1E)
SHIFTMODE	= $0291		; 0=allow, 128=locked
SCROLLFLAG	= $0292		; auto scrolldown flag
ACOPY		= $030C		; temp storage for A register
XCOPY		= $030D		; temp storage for X register
YCOPY		= $030E		; temp storage for Y register
DATASETTE	= $033C		; -$03FB: 192-byte tape input buffer
MASK		= $8270		; ROM character $40 - Shift-M (\)
VIC			= $9000		; start of Video Interface Chip registers
MACHINE		= $EDE4		; NTSC=$05, PAL=$0C
STOPKEY		= $F770		; check for STOP key pressed
RESET		= $FD22		; warm startup
CHROUT		= $FFD2		; print character with cursor translation
GETIN		= $FFE4		; get a character from keyboard queue

;*********************************************************************
; volatile VIC-SSS symbols
;
VECTORBG	= $01		; sprite temp pointer to an image source
DIRTYLINE2	= $59		; -$70: 24 screen rows for last dirty column +1
NEWDIRT		= $BF		; bit 7=VIDEO1, 6=VIDEO2, 5=PLAYFIELD, 4=STATIC
DIRTYLINE	= $D9		; -$F0: 24 screen rows for starting dirty column
DIRTMAP		= $F1		; pointer to PLAYCOLOR for dirty-bit updates
VECTORFG	= $F7		; sprite temp pointer to an image target
VECTOR1		= $F9		; sprite temp pointer
VECTOR2		= $FB		; sprite temp pointer
VECTOR3		= $FD		; sprite temp pointer
FPS			= $0285		; number of VIC re-directions every 64-jiffies
PENDING		= $0293		; next video page: $10 or $12
ACTUAL		= $0294		; save VIC startup video page
VSYNC		= $0295		; set when waiting for vertical sync(s)
VSYNC2		= $0296		; frames skipped
VCOUNT		= $0297		; current SSSFLIP count
SSSCLIPX	= $0298		; pixels to right border: 8 * (PLAYCOLS + 2)
SSSCLIPY	= $0299		; pixels to bottom border: 8 * (PLAYROWS + 2)
R0			= $029A		; unused temporary register
R1			= $029B		; unused temporary register
R2			= $029C		; unused temporary register
R3			= $029D		; unused temporary register
R4			= $029E		; unused temporary register

;*********************************************************************
; FRAME REGISTERS
;
VICFRAME1	= $1000		; first video buffer
VICCOLOR1	= $9400		; first color buffer
VICFRAME2	= $1200		; second video buffer
VICCOLOR2	= $9600		; second color buffer
PLAYFIELD	= $1400		; write-pending screen buffer
PLAYCOLOR	= $1600		; write-pending color buffer (bits 0-3)
						; bit 4 = static cell bit, sprites go behind
						; bit 5 = dirty bit for pending page
						; bit 6 = dirty bit for video page 2 only
						; bit 7 = dirty bit for video page 1 only

;*********************************************************************
; SPRITE REGISTERS
;
.global SSSBUF			; defaults to $1800, but can be relocated by linker
.global SPRITEBACK		; character code this sprite is in collision with
.global	SPRITEBUFH		; pointer within sprite image buffer @ $1800 - $19FF
.global	SPRITEBUFL
.global	SPRITEC1H		; pointer within sprite display character pool
.global	SPRITEC1L
.global SPRITEC2H		; pointer within sprite display character pool
.global SPRITEC2L
.global	SPRITECOL		; 4-bit VIC color code
.global SPRITECX		; sprite collision X-coord
.global SPRITECY		; sprite collision Y-coord
.global	SPRITEDEF		; matrix definition:
						; bit 0: height		0 = 8px; 1 = 16px
						; bit 1: width		0 = 8px; 1 = 16px
						; bit 2: float Y	0=fixed cell; 1=vertical float
						; bit 3: float X	0=fixed cell; 1=horizontal float
						; bit 4: repeat		0=independent; 1=re-use previous
						; bit 5: ghost		0=merge image; 1=invert image
						; bit 6: collision	0=ignore; 1=detect
						; bit 7: enabled	0=invisible; 1=visible
.global	SPRITEH			; number of raster lines (1-16)
.global	SPRITEIMGH		; pointer to source graphic for rendering at 0,0
.global	SPRITEIMGL
.global	SPRITEX			; horizontal pixel coordinate, visible >0 - <SSSCLIPX
.global	SPRITEY			; vertical pixel coordinate, visible >0 - <SSSCLIPY
.global	SPRITEZ			; bit 0: last rendered (0 = SPRITEC1; 1 = SPRITEC2)
						; bit 1: fast copy (0 = merge; 1 = copy)
						; bit 3: sprite-pixel collision with a non-static cell
                        ; bit 4: foreground clipped flag
                        ; bit 5: background is all SSSNULLs
						; bit 6: copy/merge into alternate sprite char pool
						; bit 7: copy/shift sprite image into its buffer
;--- above registers repeat for each sprite allocated ---
.global sss				; screen row index -- computed by PLAYCOLS
.global	sssALLOC		; table of sprite sizes (in custom characters)
.global	sssCOLS			; sprite size in columns: 1, 2, 3
.global	sssROWS			; sprite size in rows: 1, 2, 3
;--- above registers need storage assigned
sssNUM		= $90		; current sprite # (0-1)
sssX		= $92		; current sprite width: 0=8w, 1=16w, 2=24w
sssY		= $93		; current sprite height: 0=8h, 1=16h, 2=24h
sssBYTES	= $94		; number of bytes this sprite occupies
sssNEXT		= $95		; offset to adjacent character
sssCHAR		= $96		; next custom character to use on PENDING frame
sssDX		= $97		; delta X counter
sssDY		= $98		; delta Y counter
sssLINE		= $9A		; current sprite make line: 0, 8, 16
sssLINENUM	= $9B		; current sprite line countdown
sssROR1		= $9C		; bit shift register column #1
sssROR2		= $9D		; bit shift register column #2
.ifdef SPRITEWIDE
sssROR3		= $9E		; bit shift register column #3
.endif
sssXFER		= $9F		; transfer to custom character counter
SPRITES		= $B7		; number of active sprite registers (0 - SPRITEMAX)

;*********************************************************************
; Common API entry points
;
.global	SSSINIT			; must be called first
.global	SSSIRQ			; necessary only if video flip timing is required
.global	SSSCELL
.global	SSSCLEAR
.global	SSSPLOT
.global	SSSPRINT
.global	SSSPRINTS
.global	SSSPEEK			; can be called to read a char from the PLAYFIELD
.global	SSSPEEKXY
.global	SSSPOKE			; can be called to put a char on the PLAYFIELD
.global	SSSCREATE		; must be called to allocate a sprite buffer
.global SSSUSE			; must be called prior to manipulating a sprite
.global	SSSANIM			; must be called to load a sprite image
.global	SSSMOVEXY		; must be called to put a sprite in the visible area
.global SSSTOUCH		; can be called to force a sprite to re-render
.global	SSSREFRESH		; can be called to force all sprites to re-render
.global	SSSFFLIP		; same as FLIP, but may drop a frame refresh for speed
.global	SSSFLIP			; must be called to see updates on the VIC display
;
; used internally by SSS, but may have use by program:
;
.global	SSSCOMMIT
.global	SSSIMAGE
.global SSSMASK
.global	SSSPLOTS
.global	SSSPEEKS
.global	SSSREAD
.global SSSUPDATE
.global	SSSWRITE
;
; useful .asciiz translations for SSSPRINTS
;
.charmap '@', $80
.charmap 'A', $81
.charmap 'B', $82
.charmap 'C', $83
.charmap 'D', $84
.charmap 'E', $85
.charmap 'F', $86
.charmap 'G', $87
.charmap 'H', $88
.charmap 'I', $89
.charmap 'J', $8A
.charmap 'K', $8B
.charmap 'L', $8C
.charmap 'M', $8D
.charmap 'N', $8E
.charmap 'O', $8F
.charmap 'P', $90
.charmap 'Q', $91
.charmap 'R', $92
.charmap 'S', $93
.charmap 'T', $94
.charmap 'U', $95
.charmap 'V', $96
.charmap 'W', $97
.charmap 'X', $98
.charmap 'Y', $99
.charmap 'Z', $9A
.charmap '{', $9B
.charmap '|', $9C	; British pound symbol
.charmap '}', $9D
.charmap '^', $9E	; uparrow symbol
.charmap '`', $9F	; left arrow symbol
.charmap ' ', SSSNULL
.charmap '!', $A1
.charmap '"', $A2
.charmap '#', $A3
.charmap '$', $A4
.charmap '%', $A5
.charmap '&', $A6
.charmap ''', $A7
.charmap '(', $A8
.charmap ')', $A9
.charmap '*', $AA
.charmap '+', $AB
.charmap ',', $AC
.charmap '-', $AD
.charmap '.', $AE
.charmap '/', $AF
.charmap '0', $B0
.charmap '1', $B1
.charmap '2', $B2
.charmap '3', $B3
.charmap '4', $B4
.charmap '5', $B5
.charmap '6', $B6
.charmap '7', $B7
.charmap '8', $B8
.charmap '9', $B9
.charmap ':', $BA
.charmap ';', $BB
.charmap '<', $BC
.charmap '=', $BD
.charmap '>', $BE
.charmap '?', $BF
.charmap '~', $DE	; PI symbol

