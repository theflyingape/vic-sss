;*********************************************************************
; Commodore VIC 20 Software Sprite Stack - MMX Edition
; last updated: 22-Sep-2011
; written by Robert Hurst <robert@hurst-ri.us>
; with contributions from:
; Matt Dawson <matsondawson@gmail.com>
;*********************************************************************

		.fileopt author,	"Robert Hurst"
        .fileopt comment,	"Software Sprite Stack"
        .fileopt compiler,	"VIC 20 ASSEMBLER"


;*********************************************************************
; To assemble this source using cc65.org project:
;	ca65.exe --cpu 6502 --listing VIC-SSS-MMX.s
; Then link it into your project:
;   ld65.exe -C yourlinker.cfg -o yourgame.prg yourgame.o VIC-SSS-MMX.o
;
; See the various .bat files used for working examples.
;
		.include "VIC-SSS-MMX.h"
		.segment "SPRITE"


;*********************************************************************
; Software Sprite Stack INITIALIZATION
;
; MUST BE INVOKED ONCE BEFORE USING ANY OTHER SSS CALL
; Value in COLORCODE will be used to fill the color buffers.
;
SSSINIT:
		; SSS geometry
		LDA VIC+$02
		AND #$1F
		STA PLAYCOLS
		ASL				; CLC
		ADC #$04
		ASL
		ASL
		STA SSSCLIPX
		LDA VIC+$03
		AND #$7E
		LSR
		STA PLAYROWS
		ASL				; CLC
		ADC #$04
		ASL
		ASL
		STA SSSCLIPY
		;
		LDA #$00
		STA CRSRROW
		STA CRSRCOL
		TAY
		TAX
@sss:	TYA
		STA sss+1,X
		LDA CRSRCOL
		STA sss,X
		CLC
		ADC PLAYCOLS
		BCC @cc
		INY
@cc:	STA CRSRCOL
		INX
		INX
		INC CRSRROW
		LDA CRSRROW
		CMP PLAYROWS
		BNE @sss
        ;
		; SSS active / pending video page pointers
		LDA #>VICFRAME1
		STA SCRNPAGE
		LDA #>VICFRAME2
		STA PENDING
		LDA #$40
		STA NEWDIRT
		;
		; kernal init
		LDA #$01
		STA RVSFLAG		; character reverse flag
		LDA #$80
		STA SHIFTMODE	; locked
		LDA #$00
		STA SCROLLFLAG	; disable
		;
		; SPRITE register init
		STA SPRITES
		;
		; fill VIC screen / color buffers
		LDA #SSSNULL
		JSR SSSCLEAR
		;
		; VIC register init
		LDA VIC+$02
		AND #$7F		; if $80 enabled, +$0200 to base screen address
		STA VIC+$02
		LDA #$CF		; point VIC screen @ $1000 w/ char set @ $1C00
	;	LDA #$C0		; uncomment for debugging display purposes
		STA VIC+$05
		;
		; FRAME register init
		LDY #$00
		STY FPS
		STY VSYNC
		STY VSYNC2
		STY VCOUNT
		JSR SSSFLIP
		RTS


;*********************************************************************
; Software Sprite Stack IRQ HANDLER
;
; PROGRAM USE OF THIS HANDLER IS OPTIONAL
;
; customize to your liking, i.e.,
; - change JMP $EABF here to continue to your custom IRQ handler; or
; - JMP SSSIRQ at the end of your IRQ handler.
;
SSSIRQ:
		LDA JIFFYL
		AND #%00111111
		BNE @cont
		LDX VCOUNT
		STX FPS
		STA VCOUNT
@cont:
		INC VSYNC2		; frame skipped?
		LDA VSYNC
		BEQ @fskip		; program is NOT waiting ...
		LDX #$00
		SEC
		SBC VSYNC2
		STA VSYNC		; save result
		BCS @reset		; program wants more than 1 screen refresh
		STX VSYNC		; clear wait for vertical sync flag
@reset:	STX VSYNC2		; clear frame skip counter
@fskip:
		JMP $EABF


;*********************************************************************
; Software Sprite Stack CLEAR SCREEN
;
; Pass A with the character code to fill the PLAYFIELD buffer.
; Value in COLORCODE will be used to fill the PLAYCOLOR buffer.
;
; These changes will go into effect only after a call to SSSFLIP
;
SSSCLEAR:
		PHA				;++ save character fill code
		LDX #$00
		LDY #$00
		JSR SSSPLOT		; home "cursor"
@reset:	TYA
		STA DIRTYLINE,X
		LDA PLAYCOLS
		STA DIRTYLINE2,X
		INX
		CPX PLAYROWS
		BNE @reset
		;
@cls:	PLA				;--
		PHA				;++
		JSR SSSPRINT
		LDX CRSRCOL
		BNE @cls		; loop until column wraps
		LDY CRSRROW
		BNE @cls		; loop until row wraps, too
		PLA				;--
		RTS


;*********************************************************************
; Software Sprite Stack PLOT CURSOR IN FRAME BUFFER
;
; SSSPLOT uses PLAYFIELD frame buffer.
; SSSPLOTS uses PENDING frame buffer.
;
; Pass X/Y with coordinate to put cursor.
;
SSSPLOT:
		LDA #>PLAYFIELD
		STA SCRNLINE+1
		LDA #>PLAYCOLOR
		STA COLORLINE+1
		BNE SSSPLOTX
;
; PENDING frame cursor (for writing SPRITE chars)
SSSPLOTS:
		LDA PENDING
		STA SCRNLINE+1
		ORA #$84
		STA COLORLINE+1
;
SSSPLOTX:
		LDA #>PLAYCOLOR
		STA DIRTMAP+1
@x:		CPX PLAYCOLS
		BMI @y
		LDX PLAYCOLS
		DEX
@y:		CPY PLAYROWS
		BMI @ok
		LDY PLAYROWS
		DEY
@ok:	STX CRSRCOL		; maintain column offset to row
		STY CRSRROW		; maintain row number
		TYA
		ASL
		TAY
		LDA sss+1,Y
		BEQ @top
		INC SCRNLINE+1
		INC COLORLINE+1
		INC DIRTMAP+1
@top:	LDA sss,Y
		STA SCRNLINE
		STA COLORLINE
		STA DIRTMAP
		LDY CRSRROW
		RTS


;*********************************************************************
; Software Sprite Stack PRINT TO A FRAME BUFFER
;
; Like SSSPOKE, writes to current cursor, but also advances it to
; the right (with line/screen wrap) upon completion.
;
; All registers are preserved from this call, for common loop use.
;
SSSPRINT:
		STX XCOPY		; save index registers
		STY YCOPY
		JSR SSSPOKE
		INC CRSRCOL		; cursor right
		LDA CRSRCOL
		CMP PLAYCOLS	; moved past right edge?
		BCC @fini		; no, all done
		LDA #$00
		STA CRSRCOL		; reset to 1st column
		INC CRSRROW		; and advance down a row
		LDA CRSRROW
		CMP PLAYROWS	; moved past bottom edge?
		BCS @toprow		; yes, wrap back to top
		LDA SCRNLINE	; no, re-calculate new row pointer
		CLC
		ADC PLAYCOLS
		BCC @cc
		INC SCRNLINE+1
		INC COLORLINE+1
@cc:	STA SCRNLINE
		STA COLORLINE
@fini:	LDY CRSRCOL
		LDA (COLORLINE),Y
		STA CRSRCOLOR
		LDA (SCRNLINE),Y
		STA CRSRCHAR
		LDX XCOPY		; restore index registers
		LDY YCOPY
		RTS
@toprow:
		LDA #$00
		STA CRSRROW
		STA SCRNLINE
		STA COLORLINE
		DEC SCRNLINE+1
		DEC COLORLINE+1
		BNE @fini


;*********************************************************************
; Software Sprite Stack PRINT STRING FROM POINTER ON STACK
;
; Will print bytes, until a NULL, following the JSR call here.
; Carriage control and color codes are interpreted.
;
SSSPRINTS:
		PLA
		STA VECTORFG
		PLA
		STA VECTORFG+1
		LDY #$01
@loop:	LDA (VECTORFG),Y
		BEQ @fini
		CMP #$0D
		BNE @ctrl
		TYA
		PHA
		LDY CRSRROW
		INY
		LDX #0
		JSR SSSPLOT
		PLA
		TAY
		JMP @next
@ctrl:	CMP #$C0
		BCC @cont
		CMP #$D0
		BCS @cont		; color code?
		AND #$0F		; filter for 16-colors
		STA COLORCODE	; 0=blk,1=wht,2=red,3=cyn,4=mag,5=grn,6=blu,7=yel
		JMP @next
@cont:	JSR SSSPRINT
@next:	INY
		BNE @loop
		INC VECTORFG+1
		BNE @loop
		;
@fini:	TYA
		CLC
		ADC VECTORFG
		BCC @cc
		INC VECTORFG+1
@cc:	STA VECTORFG
		LDA VECTORFG+1
		PHA
		LDA VECTORFG
		PHA
		RTS


;*********************************************************************
; Software Sprite Stack READ FROM A FRAME BUFFER
;
; SSSPEEK reads from PLAYFIELD frame buffer.
; SSSPEEKS reads from PENDING frame buffer.
; SSSPEEKXY reads from PLAYFIELD frame buffer, using the sprite pixel
; coordinate system to determine X/Y cursor positioning.
;
; Pass X/Y with the coordinate to put cursor.
; CRSRCHAR and CRSRCOLOR are filled with values under cursor, with
; the former returned in Accumulator.
;
SSSPEEKS:
		JSR SSSPLOTS
		JMP SSSPEEKX
;
; pixel X/Y
SSSPEEKXY:
		CPX #$10
		BCC @fini		; hidden by left border
		CPX SSSCLIPX
		BCS @fini		; hidden by right border
		CPY #$10
		BCC @fini		; above top border
		CPY SSSCLIPY
		BCC @ok			; below bottom border
@fini:	RTS
@ok:	TYA
		SEC
		SBC #$10
		LSR
		LSR
		LSR
		TAY
		;
		TXA
		SEC
		SBC #$10
		LSR
		LSR
		LSR
		TAX
;
SSSPEEK:
		JSR SSSPLOT
;
SSSPEEKX:
		LDY CRSRCOL
		LDA (COLORLINE),Y
		STA CRSRCOLOR
		LDA (SCRNLINE),Y
		STA CRSRCHAR
		RTS


;*********************************************************************
; Software Sprite Stack WRITE TO A FRAME BUFFER
;
; Pass Accumulator with character code to write to current cursor.
; COLORCODE is used to fill same space with that value.
;
SSSPOKE:
		LDY CRSRCOL
		STA (SCRNLINE),Y
		LDA (DIRTMAP),Y
		LDX SCRNLINE+1
		CPX #>PLAYFIELD
		BPL @bg
		ORA NEWDIRT
		STA (DIRTMAP),Y	; update sprite's dirty bits only
	.ifdef SPRITEDEF5
		LDA (COLORLINE),Y
		BIT COLORCODE
		BMI @color		; keep color in place
	.endif
		LDA COLORCODE	; add color directly to map
		JMP @color
@bg:	AND #%11000000	; keep any sprite dirt
		ORA #%00100000	; dirty this PLAYFIELD cell
		ORA COLORCODE	; add color
@color:	STA (COLORLINE),Y
		LDX CRSRROW
		LDY CRSRCOL
		LDA DIRTYLINE,X
		CMP CRSRCOL
		BCC @ok			; is dirty seek lower than this write?
		STY DIRTYLINE,X	; start looking for dirty cells from here
@ok:	TYA
		CMP DIRTYLINE2,X
		BCC @ok2		; is dirty seek higher than this write?
		INY
		STY DIRTYLINE2,X ; stop looking for dirty cells after here
@ok2:	RTS


;*********************************************************************
; Software Sprite Stack FLIP ACTIVE / PENDING FRAME BUFFERS
;
; Pass Y with the number of vertical sync counts to wait for, or zero
; to make changes visible immediately.
;
; Only the current cursor position is preserved when completed.
;
; If user is holding RUN/STOP key down, the current video frame is
; paused until it is released.
;
SSSFFLIP:
		LDA #$00		; gameplay needs its action to move faster
		BIT VSYNC2
		BPL SSSFLIP2	; do we need to drop a frame?
		STA VSYNC2
		RTS
		;
SSSFLIP:
		LDA #$00
		STA VSYNC2
SSSFLIP2:
		LDA CRSRROW
		PHA				;++ save row
		LDA CRSRCOL
		PHA				;++ save column
		TYA
		PHA				;++ save Y (frame count)
		;
		; Phase I:
		; - write any new PLAYFIELD updates to PENDING frame
		; - erase any SPRITE characters from PENDING frame
		;
		LDA #%00010000	; clean TOPFIELD dirt only after this update
		JSR SSSCOMMIT
		;
		; Phase II:
		; - render & write SPRITE characters to PENDING frame
		;
		JSR SSSUPDATE
		;
		; PHASE III:
		; - signal IRQ to flip video to PENDING frame
		; - wait for the all clear
		;
		PLA				;-- restore A (frame count)
		TAY
		INY				; account for a 'missed' frame
	;	INY				; allow for another 'missed' frame
		CPY VSYNC2
		BCS @pace		; is game loop & rendering ok?
		LDY #$80		; nope, flag next call to SSSFFLIP
		STY VSYNC2		; to skip rendering/flip altogether
		LDA #$00		; and don't wait for this vsync either
@pace:	STA VSYNC		; enable screen to flip
@vsync:	LDA VSYNC
		BNE @vsync		; and wait for it to occur
		BIT VSYNC2
		BMI @ok
		STA VSYNC2		; fast flip, gauge again for next frame
		;
@ok:	LDA VIC+$02
		EOR #$80
		STA VIC+$02		; re-direct VIC to other screen buffer
		INC VCOUNT
		LDA SCRNPAGE
		STA PENDING		; make active screen as pending
		EOR #$02
		STA SCRNPAGE	; maintain VIC active video page
		;
		; PHASE IV:
		; - write the same PLAYFIELD updates to new PENDING frame
		;
		LDA #%00100000	; clean PLAYFIELD dirt as part of this update
		JSR SSSCOMMIT
		;
		PLA				;-- restore X (column)
		TAX
		PLA				;-- restore Y (row)
		TAY
		JSR SSSPLOT
		;
@pause:	JSR STOPKEY
		BNE @fini
		LDA #$00		; clear skipped frame count
		STA VSYNC2
		STA VCOUNT
	;	=== write any custom PAUSE or RESET code here ===
		PLA
		PLA
		.global RESTART
		JMP RESTART		; label speaks for itself
		;
@fini:	RTS


;*********************************************************************
; Software Sprite Stack COMMIT CHANGES TO PENDING FRAME BUFFER
;
; pass Accumulator with the PLAYFIELD bit(s) set for cleaning:
; - bit 7 for video #1
; - bit 6 for video #2
; - bit 5 for playfield
; - bit 4 for topfield
;
; SPRITE dirt for the PENDING frame is always cleaned.
;
; This is used by SSSFLIP and NOT normally called by user programs.
;
DIRTYMASK	= $00
CLEANER		= $01		; bit 7=VIDEO1, 6=VIDEO2, 5=PLAYFIELD, 4=STATIC
;
SSSCOMMIT:
		LDX PENDING
		CPX #>VICFRAME1	; will flip to video #1 next?
		BNE @scrn2
		ORA #%10000000	; erase old sprites from video #1
		BNE @cont
@scrn2:	ORA #%01000000	; erase old sprites from video #2
@cont:	TAY
		EOR #$FF		; reverse check to clean
		STA CLEANER
		TYA
		ORA #%00100000	; but always look for PLAYFIELD dirt
		STA DIRTYMASK
		TXA
		STA VECTOR2+1
		ORA #$84		; and its COLOR
		STA VECTOR3+1
		LDX #$00
		STX VECTOR2
		STX VECTOR3
		LDY #$00
		JSR SSSPLOT		; home "cursor"
		;
		LDX #$00
@forx:	LDA DIRTYLINE2,X
		STA ACOPY
		LDA DIRTYLINE,X	; dirty start column for this row
		CMP ACOPY
		BCS @nextx		; reached end of this line?
		LDY PLAYCOLS
		STY NEWDIRT
		STY DIRTYLINE,X	; reset this line's seek for next commit
		LDY #$00
		STY DIRTYLINE2,X ; reset this line's end for next commit
		TAY				; but start this commit from this column
@fory:	LDA (COLORLINE),Y
		AND #%11100000	; is this cell dirty for ANY update?
		BEQ @nexty		; no, skip it
		STY DIRTYLINE2,X ; new ending column for this line
		INC DIRTYLINE2,X ; new ending column for this line
		CPY NEWDIRT
		BCS @more
		STY NEWDIRT
		STY DIRTYLINE,X	; new starting column for this line
@more:	AND DIRTYMASK	; is this cell dirty for THIS update?
		BEQ @nexty		; no, skip it
		LDA (COLORLINE),Y
		STA (VECTOR3),Y	; update color cell
		AND CLEANER		; remove this dirt from this cell
		STA (COLORLINE),Y
		LDA (SCRNLINE),Y
		STA (VECTOR2),Y	; update video cell
@nexty:	INY
		CPY ACOPY
		BCC @fory
@nextx:	LDA SCRNLINE
		CLC
		ADC PLAYCOLS
		BCC @cc
		INC SCRNLINE+1
		INC COLORLINE+1
		INC VECTOR2+1
		INC VECTOR3+1
@cc:	STA SCRNLINE
		STA COLORLINE
		STA VECTOR2
		STA VECTOR3
		INX
		CPX PLAYROWS
		BCC @forx
		;
		LDA #%10000000
		LDX PENDING
		CPX #>VICFRAME2	; will flip to video #2 next?
		BNE @scrn1
		LDA #%01000000
@scrn1:	STA NEWDIRT
		RTS


;*********************************************************************
; Software Sprite Stack CREATE A NEW SPRITE IN THE LIST
;
; pass Accumulator with the SPRITEDEF value (see HEADER)
; pass Y with the SPRITEH value (1-16)
; returns X with sprite index #0 thru SPRITEMAX-1
;
SSSCREATE:
		STY YCOPY
		LDX SPRITES
		CPX #SPRITEMAX
		BCC @cont
		RTS				; sorry, increase SPRITEMAX and re-compile
@cont:
		STA SPRITEDEF,X
		CPX #$00
		BNE @append		; >1 sprite
		;
		; this is the first sprite in the list ...
		LDA #<SSSBUF
		LDY #>SSSBUF
		STA SPRITEBUFL
		STY SPRITEBUFH
		LDY #$20		; start at top of custom character
		STX SPRITEC1L
		STY SPRITEC1H
		STX SPRITEC2L
		STY SPRITEC2H
		BNE @compute
@append:
		; copy prior sprite vectors
		LDA SPRITEBUFL-1,X
		STA SPRITEBUFL,X
		LDA SPRITEBUFH-1,X
		STA SPRITEBUFH,X
		LDA SPRITEC1L-1,X
		STA SPRITEC2L,X
		LDA SPRITEC1H-1,X
		STA SPRITEC1H,X
		STA SPRITEC2H,X
	.ifdef SPRITEDEF4
		; repeating sprite?
		LDA SPRITEDEF,X
		AND #SPRITEDEF4
		BNE @same
	.endif
		; no, allocate new image and character buffers
		LDA SPRITEDEF-1,X
		AND #$0F
		TAY
		LDA sssALLOC,Y
		CLC
		ADC SPRITEBUFL,X
		BCC @cc
		INC SPRITEBUFH,X
@cc:	STA SPRITEBUFL,X
@compute:
		LDA SPRITEDEF,X
		AND #$0F
		TAY
		LDA sssALLOC,Y
		STA sssBYTES
		; vector#2 into custom char set
		LDA SPRITEC2L,X
		SEC
		SBC sssBYTES	; account for its entire buffer size
		BCS @cc1
		DEC SPRITEC2H,X
		DEC SPRITEC1H,X
@cc1:	STA SPRITEC2L,X
		STA SPRITEC1L,X
		; vector#1 into custom char set
		SEC
		SBC sssBYTES	; account for its entire buffer size
		BCS @cc2
		DEC SPRITEC1H,X
@cc2:	STA SPRITEC1L,X
		JMP @new
		; keep repeating sprite pointing to same custom characters
@same:	LDA SPRITEC1L-1,X
		STA SPRITEC1L,X
		LDA SPRITEC2L-1,X
		STA SPRITEC2L,X
		LDA SPRITEC2H-1,X
		STA SPRITEC2H,X
@new:	LDA YCOPY
		STA SPRITEH,X
	.ifdef SPRITEDEF6
		LDA #SSSNULL	; init with nothing in contact
		STA SPRITEBACK,X
	.endif
		LDA #$00
	.ifdef SPRITEDEF6
		STA SPRITECX,X	; init collision X-coord
		STA SPRITECY,X	; init collision Y-coord
	.endif
		STA SPRITEX,X	; sprite is not in visible area to start
		STA SPRITEY,X
		STA SPRITEZ,X   ; all flags off
		LDX SPRITES		; return this new sprite # as initialized
		STX sssNUM
		INC SPRITES		; account for the new sprite allocated
		RTS


;*********************************************************************
; Software Sprite Stack SELECT A SPRITE TO MANIPULATE
;
; pass X index with the SPRITES number (0 - <SPRITEMAX)
; preset values for sssNUM, sssX, sssY, sssBYTES, sssNEXT
;
SSSUSE:
		CPX SPRITES
		BCC @cont
		BRK				; debugging is in your future
@cont:	STX sssNUM
		LDA SPRITEDEF,X
		AND #$0F
		TAY
		AND #%00000100	; Y-float enabled?
		BEQ @y
		LDA SPRITEY,X
		AND #$07
		BNE @y
		TYA
		AND #%00001011	; shave overflow row off
		TAY
@y:		TYA
		AND #%00001000	; X-float enabled?
		BEQ @x
		LDA SPRITEX,X
		AND #$07
		BNE @x
		TYA
		AND #%00000111	; shave overflow column off
		TAY
@x:		;
		LDA sssALLOC,Y
		STA sssBYTES
		;
		LDA sssROWS,Y
		STA sssY
		ASL
		ASL
		ASL             ; x8
		STA sssNEXT
		;
		LDA sssCOLS,Y
		STA sssX
@fini:	RTS


;*********************************************************************
; Software Sprite Stack LOAD SPRITE BUFFER WITH NEW IMAGE DATA
;
; SSSUSE must be called prior to point to sprite register entry
; pass Accumulator with this sprite's color
; pass X,Y as the source image pointer
;
SSSANIM:
		STX sssDX
		LDX sssNUM
		STA SPRITECOL,X
		LDA sssDX
		STA SPRITEIMGL,X
		TYA
		STA SPRITEIMGH,X
		BNE SSSTOUCH


;*********************************************************************
; Software Sprite Stack MOVE A SPRITE TO ABSOLUTE X,Y COORDINATES
;
; SSSUSE must be called prior to point to sprite register entry
; pass X,Y with the sprite coordinates
;
SSSMOVEXY:
		TXA
		LDX sssNUM
@x:		STA SPRITEX,X
@y:		TYA
		STA SPRITEY,X


;*********************************************************************
; Software Sprite Stack FLAG A SPRITE FOR RENDERING
;
; Pass X with the sprite#
;
SSSTOUCH:
		LDA SPRITEZ,X
		AND #%11		; reset flags, except fast copy + custom char
		ORA #%11000000	; force sprite to do make + copy/merge
		STA SPRITEZ,X
		RTS


;*********************************************************************
; Software Sprite Stack FLAG ALL SPRITES FOR RENDERING
;
SSSREFRESH:
		LDX #$00
@loop:	CPX SPRITES
		BCS @fini
		JSR SSSTOUCH
		INX
		BNE @loop
@fini:	RTS


;*********************************************************************
; Software Sprite Stack UPDATE PENDING FRAME BUFFER WITH SPRITES
;
; This is part of the SSSFLIP operation and is NOT expected to be
; called by user programs.
;
SSSUPDATE:
		LDX #0
		STX sssNUM
@do:
		CPX SPRITES
		BCC @cc
		RTS
@cc:	LDA SPRITEDEF,X

	.ifdef SPRITEDEF4	; repeating sprite?
		AND #SPRITEDEF4
		BEQ @own
		LDA SPRITEZ-1,X
		STA SPRITEZ,X	; copy Z-flags for display & results
		JMP @matrix
	.else
		ASL
		BCC @redraw		; sprite is disabled
		LDA SPRITEX,X
		BEQ @redraw		; 0 = outside left border visible range
		CMP SSSCLIPX
		BCS @redraw		; >= outside right border visible range
		LDA SPRITEY,X
		BEQ @redraw		; 0 = outside top border visible range
		CMP SSSCLIPY
		BCS @redraw		; >= outside bottom border visible range
	.endif

        ; preset sprite image buffer:
		; VECTOR1 = pointer to top-left within sprite matrix
		; VECTOR2&3 = pointer to adjacent chars, as necessary
@own:	;
		JSR SSSUSE
		LDA SPRITEBUFH,X
		STA VECTOR1+1
		STA VECTOR2+1

	.ifdef SPRITEWIDE
		STA VECTOR3+1
	.endif

		LDA SPRITEBUFL,X
		STA VECTOR1
		CLC
		ADC sssNEXT
		BCC @cc1
		INC VECTOR2+1

	.ifdef SPRITEWIDE
		INC VECTOR3+1
	.endif

@cc1:	STA VECTOR2

	.ifdef SPRITEWIDE
		CLC
		ADC sssNEXT
		BCC @cc2
		INC VECTOR3+1
@cc2:	STA VECTOR3
	.endif

	.ifdef SPRITEDEF5
		LDY #$11		; ORA opcode
		LDA SPRITEDEF,X
		AND #SPRITEDEF5	; ghost image?
		BEQ @bit
		LDY #$51		; EOR opcode
@bit:	TYA
		STA @OP1
		STA @OP2
		EOR #$40		; swap opcode
		STA @OP3
	.endif

        ; branch on make control flags
		LDA SPRITEZ,X
		ASL
		PHA
		BCC @copy		; $80 - (re)make buffered image
		JSR @Make
@copy:	PLA
		ASL
		BCC @matrix		; $40 - copy buffered image
		JSR @Copy
@matrix:
		JSR @Display	; display sprite matrix
		JMP @loop
@redraw:
		LDA SPRITEZ,X
		AND #%11
		ORA #%11110000	; make + copy/merge + null bg + clipped fg
		STA SPRITEZ,X
@loop:
		INC sssNUM
		LDX sssNUM
		JMP @do
		;
		; INIT PHASE
		; ----------
		; (re)make this sprite's image buffer
@Make:	;
		LDA SPRITEH,X
		STA sssXFER		; sprite image raster count
		LDA SPRITEY,X
		AND #$07
		CLC
		ADC sssXFER
		STA sssDY       ; 1st raster below image
		;
		; VECTORBG = pointer to your compact source image
		LDA SPRITEIMGL,X
		STA VECTORBG
		LDA SPRITEIMGH,X
		STA VECTORBG+1
		LDA sssNEXT
		STA sssLINENUM  ; this many raster lines to copy
		CMP sssDY
		BCS @Mloop		; fits within height of sprite
		LDA sssDY
		SEC
		SBC sssLINENUM
		STA ACOPY		; compute how many rasters to clip
		LDA sssXFER
		SBC ACOPY
		STA sssXFER		; clip image within sprite height
@Mloop:
		LDA #$00		; erase raster registers
		STA sssROR1
		STA sssROR2

	.ifdef SPRITEWIDE
		STA sssROR3
	.endif

		DEC sssLINENUM
		LDY sssLINENUM
		LDA sssXFER
		BEQ @Mcopy		; no more rasters to copy - zero them
		CPY sssDY
		BCS @Mcopy		; below sprite image - zero this raster
@Mxfer:
		DEC sssXFER		; copying sprite image rasters
		LDY sssXFER
		LDA (VECTORBG),Y
		STA sssROR1
		LDA SPRITEDEF,X
		AND #%00000010
		BEQ @Mxfer2		; 16w ?
		LDY #$08
		LDA SPRITEDEF,X
		LSR
		BCC @Monly8 	; 16h ?
		LDY #$10
@Monly8:
		TYA
		CLC
		ADC sssXFER
		TAY
		LDA (VECTORBG),Y
		STA sssROR2     ; load adjacent register
@Mxfer2:
		LDA SPRITEX,X
		AND #$07
		BEQ @Mcopy
		STA sssDX
@Mx2:	LSR sssROR1
		ROR sssROR2		; shift into image overflow register #1

	.ifdef SPRITEWIDE
		ROR sssROR3		; shift into image overflow register #2
	.endif

		DEC sssDX
		BNE @Mx2
@Mcopy:
		LDX #$01
		LDY sssLINENUM
		LDA sssROR1
		STA (VECTOR1),Y
		CPX sssX
		BEQ @Mnext
		LDA sssROR2		; write image overflow register #1
		STA (VECTOR2),Y

	.ifdef SPRITEWIDE
		INX
		CPX sssX
		BEQ @Mnext
		LDA sssROR3		; write image overflow register #2
		STA (VECTOR3),Y
	.endif

@Mnext:
        LDX sssNUM
		LDA sssLINENUM
		BEQ @Mfini
		JMP @Mloop
@Mfini:	RTS
		;
		; PHASE II
		; --------
		; copy/merge buffered image with background into
		; sprite character matrix
@Copy:	;
        LDA SPRITEZ,X
        AND #%11
		EOR #%1			; flip to other character set
		STA SPRITEZ,X
		AND #%1
		BNE @Cfb2
		LDA SPRITEC1L,X
		STA VECTORFG
		LDA SPRITEC1H,X
		STA VECTORFG+1
		BNE @Ccopy
@Cfb2:	LDA SPRITEC2L,X
		STA VECTORFG
		LDA SPRITEC2H,X
		STA VECTORFG+1
@Ccopy:
		LDA SPRITEX,X
		STA sssDX
		LDA sssNEXT
		STA sssLINE
		LDY #0
		STY sssCHAR
		STY sssLINENUM
		STY ACOPY
@Cdocol:
		LDX sssNUM
		LDA SPRITEY,X
		STA sssDY
@Cbgimage:
		LDX sssNUM
		LDA SPRITEZ,X
		AND #%10
		BNE @Cjmp		; fast copy?
		LDX sssDX
		LDY sssDY
		JSR SSSREAD
		CMP #SSSNULL
		BNE @Cmore
@Cjmp:	JMP @Ccpfast
@Cmore:
		LDX sssNUM
		LDA CRSRCOLOR
		AND #%10000
		BEQ @Ccont		; static cell?
		LDA SPRITEZ,X
		ORA #%10000		; flag that sprite's foreground is clipped
        STA SPRITEZ,X
		JMP @Cnextrow	; don't bother merging with a background
@Ccont:

	.ifdef SPRITEDEF4
		LDA SPRITEDEF,X
		AND #SPRITEDEF4
		BNE @Cjmp
	.endif

		LDA CRSRCHAR
		JSR SSSIMAGE
		STX VECTORBG
		STY VECTORBG+1
		LDX #0
		STX sssXFER
		INC sssCHAR     ; flag that there is something behind this sprite

	.ifdef SPRITEDEF6
		LDY sssNUM
		LDA SPRITEZ,Y
		AND #%1000
		BNE @Ccploop	; already a collision?
		LDA SPRITEDEF,Y
		AND #SPRITEDEF6
		BNE @Ccploopx	; collision detection enabled?
	.endif

@Ccploop:
		LDY sssXFER		; from ...
		LDA (VECTORBG),Y
		LDY sssLINENUM	; to ...
@OP1:	ORA (VECTOR1),Y	; opcode modification #1: ORA / EOR
		STA (VECTORFG),Y
@Ccpnxt:
		INC sssLINENUM
		INC sssXFER
		INX
		CPX #8
		BNE @Ccploop
		BEQ @Cnextrow

	.ifdef SPRITEDEF6
@Ccploopx:
		LDY sssXFER		; from ...
		LDA (VECTORBG),Y
		PHA				;++
		LDY sssLINENUM	; to ...
@OP2:	ORA (VECTOR1),Y	; opcode modification #2: ORA / EOR
		STA (VECTORFG),Y
		PLA				;--
@OP3:	EOR (VECTOR1),Y	; opcode modification #3: ORA / EOR
		CMP (VECTORFG),Y
		BEQ @Cnohit		; any overlapping pixel(s)?
		LDY sssNUM
		LDA sssDX
		STA SPRITECX,Y	; save X sprite coord of what was hit
		LDA sssDY
		STA SPRITECY,Y	; save Y sprite coord of what was hit
		LDA CRSRCHAR	; save character code of what was hit
		STA SPRITEBACK,Y
		LDA SPRITEZ,Y
		ORA #%1000		; sprite-pixel collision with non-static cell
        STA SPRITEZ,Y
		BNE @Ccpnxt		; resume normal copy/merge operation
@Cnohit:
		INC sssLINENUM
		INC sssXFER
		INX
		CPX #8
		BNE @Ccploopx
		BEQ @Cnextrow
	.endif

		; faster copy, because there is no backgound to merge with ... 
@Ccpfast:				
		LDX #8
		LDY sssLINENUM
@Ccploop2:
		LDA (VECTOR1),Y
		STA (VECTORFG),Y
		INY
		DEX
		BNE @Ccploop2
		STY sssLINENUM
@Cnextrow:
		LDA sssDY
		CLC
		ADC #8
		STA sssDY
		LDY sssLINENUM
		CPY sssLINE
		BEQ @Cnextcol
		JMP @Cbgimage
@Cnextcol:
		LDA ACOPY
		CLC
		ADC sssNEXT
		STA ACOPY
		STA sssLINENUM
        LDA sssLINE
        CLC
        ADC sssNEXT
		STA sssLINE
		LDA sssDX
		CLC
		ADC #$08
		STA sssDX
		DEC sssX
		BEQ @Cdone
		JMP @Cdocol
@Cdone:
		LDA sssCHAR
		BNE @Cfini
		LDX sssNUM		; all null background, if no new changes occur
		LDA SPRITEZ,X	; don't do a merge on next flip either
		ORA #$20        ; enable this sprite to be re-used as-is
        STA SPRITEZ,X   ; on next frame flip
@Cfini:	RTS
		;
		; PHASE III
		; ---------
		; display sprite character matrix
		; by row, then by column
@Display:
		LDX sssNUM

	.ifdef SPRITEDEF4
		LDA SPRITEDEF,X
		ASL
		BCC @Cfini		; sprite is disabled
	.endif

		JSR SSSUSE
		DEC sssY
		DEC sssX
		LDA SPRITEX,X
		STA sssDX
		LDA SPRITECOL,X
		STA COLORCODE

	.ifdef SPRITEDEF5
		LDA SPRITEDEF,X
		AND #SPRITEDEF5	; ghost mode?
		BEQ @Dok
		LDA COLORCODE
		ORA #$80
		STA COLORCODE	; flag to keep PLAYFIELD colored cells
	.endif

@Dok:	LDA SPRITEZ,X
		AND #%1
		BNE @Dfb2		; which character set to use?
		LDA SPRITEC1L,X
		STA VECTORFG
		LDA SPRITEC1H,X
		BNE @Dchar
@Dfb2:	LDA SPRITEC2L,X
		STA VECTORFG
		LDA SPRITEC2H,X
@Dchar:	STA VECTORFG+1
		SEC
		SBC #$1C		; starting page of custom chars
		ASL
		ASL
		ASL
		ASL
		ASL				; x32
		STA sssCHAR
		LDA VECTORFG
		LSR
		LSR
		LSR				; /8
		ADC sssCHAR
		STA sssCHAR		; start with this custom character
@Dcol:
		LDA sssY
		STA sssLINENUM
		LDX sssNUM
		LDA SPRITEY,X
		STA sssDY		; custom character row (0, 1?, 2?)
@Drow:
		LDA sssCHAR
		LDX sssDX
		LDY sssDY
		JSR SSSWRITE	; display it
@Dskip:
		INC sssCHAR		; account for it, even if it is not displayed
		LDA sssLINENUM
		BEQ @Dnrow
		DEC sssLINENUM
		LDA sssDY
		CLC
		ADC #8
		STA sssDY		; next Y-pixel
		JMP @Drow
@Dnrow:
		LDA sssDX
		CLC
		ADC #8
		STA sssDX
		LDA sssX
		BEQ @Dncol
		DEC sssX
		JMP @Dcol
@Dncol:
		RTS


;*********************************************************************
; Software Sprite Stack GET IMAGE ADDRESS FROM A CHARACTER
;
; This is used by SSSUPDATE and NOT normally called by user programs.
;
; Pass A with the character code.
; returns X/Y as a pointer to its image source.
;
SSSIMAGE:
		TAY
		ASL
		ASL
		ASL				; x8
		TAX				; save image low byte
		TYA
		ROL				; set carry bit
		LDY #$00		; point to custom chars
		BCC @cont		; is character reversed?
		INY
@cont:	ROL
		ROL
		ROL
		AND #%00000011
		ORA @vic,Y		; prepend page pointer
		TAY				; save image high byte
		RTS
		; VIC custom or ROM characters
@vic:	.byte	$1C, $80


;*********************************************************************
; Software Sprite Stack READ FROM PENDING FRAME BUFFER
;
; This is used by SSSUPDATE and NOT normally called by user programs.
;
; Pass X/Y with a sprite pixel coordinate.
; CURSOR is re-plotted to this location.
; returns Accumulator with character code from PENDING frame buffer,
; or a SPACE if the coordinate is outside the screen borders.
; returns X/Y cell coordinates.
;
SSSREAD:
		LDA #SSSNULL	; default to an empty background
		CPX #$10
		BCC @fini		; hidden by left border
		CPX SSSCLIPX
		BCS @fini		; hidden by right border
		CPY #$10
		BCC @fini		; above top border
		CPY SSSCLIPY
		BCS @fini		; below bottom border
		;
		LDA PENDING
		STA SCRNLINE+1
		LDA #>PLAYCOLOR
		STA COLORLINE+1
		;
		TYA
		SEC
		SBC #$10
		LSR
		LSR
		LSR				; /8
		TAY
		STY CRSRROW
		;
		TXA
		SEC
		SBC #$10
		LSR
		LSR
		LSR				; /8
		STA CRSRCOL
		;
@ok:	TYA
		ASL
		TAY
		LDA sss+1,Y
		BEQ @top
		INC SCRNLINE+1
		INC COLORLINE+1
@top:	LDA sss,Y
		STA SCRNLINE
		STA COLORLINE
		LDY CRSRCOL
		LDA (COLORLINE),Y	; read from pending color buffer
		STA CRSRCOLOR
		LDA (SCRNLINE),Y	; read from pending video buffer
		STA CRSRCHAR
		LDY CRSRROW
@fini:	RTS


;*********************************************************************
; Software Sprite Stack WRITE TO PENDING FRAME BUFFER
;
; This is used by SSSUPDATE and NOT normally called by user programs.
;
; Pass X/Y with a sprite pixel coordinate.
; Pass A with SPRITE character code to write to PENDING screen buffer.
; COLORCODE is used to fill same space with that value.
;
; Write does not occur if X/Y lie outside the screen borders.
;
SSSWRITE:
		CPX #$10
		BCC @fini		; hidden by left border
		CPX SSSCLIPX
		BCS @fini		; hidden by right border
		CPY #$10
		BCC @fini		; above top border
		CPY SSSCLIPY
		BCS @fini		; below bottom border
		PHA				;++
		JSR SSSPEEKXY
		LDA CRSRCOLOR
		AND #$10		; static cell?
		BEQ @ok
		PLA				; yes, don't overwrite it!
		RTS
		;
@ok:	LDX CRSRCOL
		LDY CRSRROW
		JSR SSSPLOTS
		PLA				;--
		JSR SSSPOKE
@fini:	RTS


;*********************************************************************
; Software Sprite Stack PROTECTED WRITE TO PENDING FRAME BUFFER
;
; Pass X/Y with a screen cell coordinate.
; Pass A with character code to write to PENDING screen buffer.
; COLORCODE is used to fill same space with that value.
;
SSSCELL:
		PHA				;++
		LDA NEWDIRT
		STA $01
		LDA #$10
		STA NEWDIRT
		JSR SSSPLOTS
		PLA				;--
		JSR SSSPOKE
		LDA $01
		STA NEWDIRT
		RTS

