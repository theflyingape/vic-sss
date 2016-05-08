		.include "VIC-SSS-MMX.h"

		.segment "CODE"
		.global EFFECT
		.global EINDEX
		.global MYIRQ
		.global	NMES
		.global RESTART


;*********************************************************************
; Game entry point after boot
;
RESTART:
		JSR GAMEOVER


;*********************************************************************
; Reset playfield
;
NEXTLEVEL:
		LDA MODE
		JSR SWITCHMODE
		;
		LDX #38			; process sprite #1 - #38
		STX NMES
@loop:	LDA NMEPOS-1,X	; get matrix position
		TAY
		TXA
		STA NMECOL0-1,Y	; put sprite# in matrix
		DEX
		BNE @loop
		STX FLIP		; start out flippin'!
		STX LAYER		; restored shield layers


;*********************************************************************
; Player up!
;
NEXTBASE:
		LDA NMES
		PHA				;++
		LDA #0
		STA NMES
		STA STEPS
		;
		JSR STATUSLINE
		JSR SCORESTATUS
		; reset player's baseship
		LDX #39
		JSR SSSUSE
		LDA SPRITEDEF,X
		ORA #$80		; enable
		STA SPRITEDEF,X
		LDA #7			; yellow
		LDX MODE
		BEQ @classic
		LDX PLAYER
		BEQ @classic
		LDA #3			; cyan
@classic:
		LDX #<BASESHIP
		LDY #>BASESHIP
		JSR SSSANIM
		LDX #(12*8)
		LDY #(23*8)
		JSR SSSMOVEXY
		JSR INVADERS
		LDY #0			; immediate
		JSR SSSFLIP		; gratuitous
		;
		LDA #8
		STA R2
@flash:	LDA SPRITEDEF+39
		EOR #$80		; toggle enable
		STA SPRITEDEF+39
		LDY #18			; ~ 1/3 second pause
		JSR SSSFLIP
		DEC R2
		BNE @flash
		;
		INC STEPS
		PLA				;--
		STA NMES


;*********************************************************************
; Main game-playing loop
;
GAMELOOP:
		JSR FLYBY
		JSR INVADERS
		JSR NMEFIRE
		JSR MOVEBASE
		;
		LDY FLIP
		JSR SSSFLIP
		INC FRAME
		;
		JSR BASEFIRE
		LDA NMES
		BNE GAMELOOP
		;
		LDX PLAYER
		INC LEVEL,X
		;
NEXTPLAYER:
		LDA PLAYERS
		CMP #1
		BEQ @fini
		LDA PLAYER
		EOR #1
		TAX
		LDA BASES,X
		BEQ @fini		; any bases left?
@np:	STX PLAYER		; swap player up
@fini:	JMP NEXTLEVEL


;*********************************************************************
; End of game sequence
;
GAMEOVER:
		LDA #$8F		; orange aux, highest volume
		STA VIC+$0E
		LDA #0
		STA NMES
		STA LEVEL
		STA LEVEL+1
		STA PLAYER
		STA UFO
		LDA MODE
		JSR SWITCHMODE
		INC PLAYER
		JSR SCORESTATUS
		INC PLAYER
		;
		LDY #0
		STY $C6			; empty keyboard buffer
		DEY
		STY R3
		STY FRAME
		LDY #4
		STY R4
@cont:
		LDX #6
		LDY #0
		JSR SSSPLOT
		LDA JIFFYL
		AND #$40
		BNE @text
		JSR SSSPRINTS
		.byte	$C2,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$00
		JMP @anim
@text:	JSR SSSPRINTS	; print GAME
		.byte	$C2,$87,$81,$8D,$85,$00
		INC CRSRCOL
		INC CRSRCOL
		JSR SSSPRINTS	; print OVER
		.byte	$8F,$96,$85,$92,$00
@anim:
		JSR INVADERS
		LDY INVDY
		BEQ @vic20
		LDY R3
		BNE @flip
		STY INVDY		; aliens should only walk left/right
@vic20:	STY R3
@flip:	LDY #0			; immediate
		JSR SSSFFLIP	; skip a frame, if necessary
		INC FRAME
		LDA FRAME
		AND #$1F
		BNE @start
		INC R4
		LDA R4
		CMP #4
		BCC @fkey
		LDA #0
		STA R4
@fkey:	CMP #0
		BNE @fkey3
		LDX #1
		LDY #54
		JSR SHOWSTART
		JMP @fbot
@fkey3:	CMP #1
		BNE @fkey5
		LDX #2
		LDY #55
		JSR SHOWSTART
		JMP @fbot
@fkey5:	CMP #2
		BNE @fkey7
		JSR SHOWDIFFICULTY
		JMP @fbot
@fkey7:	JSR SHOWMODE
@fbot:	JSR SHOWBOTTOM
@start:
		LDY #$00
		STY $9113
@joy:	LDA #$FF
		STA $9122
		LDY $9111
		TYA
		AND #$20		; got joystick FIRE ?
		BEQ @p1
@kb:	JSR GETIN
		BEQ @next
		LDX #200
		STX FRAME
		STX VIC+$0C		; 3rd voice
		LDX #6
		STX BEEP
@f1:	CMP #$85
		BEQ @p1
@f3:	CMP #$86
		BEQ @p2
@f5:	CMP #$87
		BNE @f7
		INC DIFFICULTY
		LDA DIFFICULTY
		CMP #3
		BCC @xf5
		LDA #0
@xf5:	STA DIFFICULTY
		JSR SHOWDIFFICULTY
		JMP @cont
@f7:	CMP #$88
		BNE @next
		LDA MODE
		EOR #1
		STA R3
		JSR SWITCHMODE
@next:	JMP @cont
@p1:
		LDX #1
		STX PLAYERS
		LDY #54
		BNE @fini
@p2:
		LDA #3
		STA BASES+1
		LDX #2
		STX PLAYERS
		LDY #55
@fini:
		JSR SHOWSTART
		LDY #0			; immediate flip for a
		JSR SSSFLIP		; gratuitous video update,
		LDY #50			; then show again with a
		JSR SSSFLIP		; short pause
		LDX #0
		STX EXTRA
		STX EXTRA+1
		STX PLAYER
		STX SCORE
		STX SCORE+1
		STX SCORE+2
		STX SCORE+3
		LDA DIFFICULTY
		ASL
		STA LEVEL
		STA LEVEL+1
		LDA #3
		STA BASES
		LDA JIFFYL
		AND #$03		; randomize mothership 1st appearance
		STA JIFFYM
		INC JIFFYM
		RTS


;*********************************************************************
; Player missile firing solution
;
BASEFIRE:
		LDA BASEHIT
		BEQ @missile
		LDA #0
		STA BASEHIT
		ASL SPRITEDEF+41
		LSR SPRITEDEF+41
		LDA SPRITEZ+41
		AND #%1000
		BEQ @fini		; harmless miss
		LDX #41
		JSR DODAMAGE
@fini:	RTS
@missile:
		LDA SPRITEDEF+41
		ASL
		BCS @cont
		RTS
@cont:
		LDA #0
		STA VIC+$0D		; mute missile launch
		LDA SPRITEZ+41
		AND #%1000		; collision?
		BNE @hit
		LDA SPRITEY+41
		SEC
		SBC #6
		CMP #16
		BCC @top
		STA SPRITEY+41
		LDX #41
		JSR SSSTOUCH
		RTS
		; explode harmlessly at top of screen
@top:	LDA #%10101100	; enable+ghost+float
@exp:	DEC SPRITEX+41
		DEC SPRITEX+41
		LDX #<DAMAGE41
		LDY #>DAMAGE41
@done:	STA SPRITEDEF+41
		STX SPRITEIMGL+41
		STY SPRITEIMGH+41
		LDY #8			; lengthen to 8-pixels high
		STY SPRITEH+41
		LDX #41
		JSR SSSTOUCH
		INC BASEHIT
		; re-calculate for stepping speed
		LDY #0
		LDX NMES
		CPX #27
		BCS @bool
		INY
		CPX #17
		BCS @bool
		INY
		CPX #11
		BCS @bool
		INY
		CPX #6
		BCS @bool
		INY
		CPX #4
		BCS @bool
		INY
		CPX #2
		BCS @bool
		INY
@bool:	STY INVINDEX
		LDY #0			; fastest frame flip
		LDA DIFFICULTY
		BNE @nmes		; not for normal and harder modes
		INY				; keep refresh constant (slower)
@nmes:	LDA NMES
		CMP #11
		BCS @flip		; < 11 invaders,
		INY				; let's not get too frenetic
@flip:	STY FLIP
		RTS
@erase:
		ASL SPRITEDEF+41
		LSR SPRITEDEF+41
		RTS
;
; Sprites custom character allocation (64)
;	mothership:	7f,7e,7d,7c,7b,7a
;	alien 1:	79,78,77,76,75,74,73,72
;	alien 2:	71,70,6f,6e,6d,6c,6b,6a,69,68,67,66
;	alien 3:	65,64,63,62,61,60,5f,5e,5d,5c,5b,5a
;	baseship:	59,58,57,56,55,54
;	laser:		53,52,51,50,4f,4e,4d,4c
;	missile:	4b,4a,49,48,47,46,45,44
; Unallocated (10):
;	free chars:	43,42,41,40,3f,3e,3d,3c,3b,3a
; Graphic custom character allocation (18):
;	f-keycaps:	39,38,37,36,35,34,33
;	base icon:	32
;	digit font:	31,30,2f,2e,2d,2c,2b,2a,29,28
; Shields custom character allocation (40):
;	shield 4:	27,26,25,24,23,22,21,20,1f,1e
;	shield 3:	1d,1c,1b,1a,19,18,17,16,15,14
;	shield 2:	13,12,11,10,0f,0e,0d,0c,0b,0a
;	shield 1:	09,08,07,06,05,04,03,02,01,00
;
@hit:
		LDA SPRITEBACK+41
		CMP #$7A
		BCC @invader
		JMP @mothership
@invader:
		CMP #$72
		BCS @alien1
		CMP #$66
		BCS @alien2
		CMP #$5A
		BCS @alien3
		LDA #%11101100	; hit your own shield,
		JMP @exp		; do damage to it next frame
@alien1:
		LDX #10
@a1find:
		LDA SPRITEDEF,X
		ASL
		BCC @a1next
		LDA SPRITEX+41
		SEC
		SBC SPRITEX,X
		CMP #8
		BCS @a1next
		LDY #$30
		BNE @destroy
@a1next:
		DEX
		BNE @a1find
@alien2:
		LDX #24
@a2find:
		LDA SPRITEDEF,X
		ASL
		BCC @a2next
		LDA SPRITEX+41
		SEC
		SBC SPRITEX,X
		CMP #10
		BCS @a2next
		LDY #$20
		BNE @destroy
@a2next:
		DEX
		CPX #10
		BNE @a2find
@alien3:
		LDX #38
@a3find:
		LDA SPRITEDEF,X
		ASL
		BCC @a3next
		LDA SPRITEX+41
		SEC
		SBC SPRITEX,X
		CMP #12
		BCS @a3next
		LDY #$10
		BNE @destroy
@a3next:
		DEX
		CPX #24
		BNE @a3find
@destroy:
		LDA #1
		STA EFFECT		; invader effect
		LDA #17
		STA EINDEX
		DEC NMES
		ASL SPRITEDEF,X
		LSR SPRITEDEF,X
		LDA SPRITEX,X
		STA SPRITEX+41
		CPY #$30
		BEQ @adj
		INC SPRITEX+41
		CPY #$20
		BEQ @adj
		INC SPRITEX+41
@adj:	LDA SPRITEY,X
		STA SPRITEY+41
		LDA NMEPOS-1,X	; retrieve shot invader from matrix
		TAX
		LDA #0
		STA NMECOL0-1,X	; disable from future firing solution
		JSR SCOREUPDATE
		LDA #%10101100
		LDX #<EXPLODE
		LDY #>EXPLODE
		JMP @done
@mothership:
		LDA UFO
		BNE @ufo
		JMP @erase
@ufo:	LDA #2
		STA EFFECT		; mothership bonus effect
		LDA #$31
		STA EINDEX
		LDX #0
		STX UFO
		JSR SSSTOUCH
		LDY #$50		; start with 50-points
		JSR SCOREUPDATE
		LDX #<SCORE50
		LDY #>SCORE50
		LDA FRAME
		AND #$07		; oooh, a mystery score?
		BNE @100
		LDA #$71
		STA EINDEX
		LDA #5
		STA R4
@250:	LDY #$50		; +250
		JSR SCOREUPDATE
		DEC R4
		BNE @250
		LDX #<SCORE300
		LDY #>SCORE300
		BNE @50
@100:	AND #$01
		BNE @50
		LDA #$51
		STA EINDEX
		LDY #$50		; +50
		JSR SCOREUPDATE
		LDX #<SCORE100
		LDY #>SCORE100
@50:	STX SPRITEIMGL
		STY SPRITEIMGH
		LDA #2			; red
		STA SPRITECOL
		JMP @erase


;*********************************************************************
; Baseship destruction sequence
;
DEATH:
		LDA MODE
		BEQ @classic
		LDA #170		; pink screen / red border
		STA VIC+$0F
@classic:
		LDA #193
		STA VIC+$0D		; noise
		LSR
		SBC NMES
		STA DATASETTE
		LDY #0			; clear this level
		STY NMES
		STY EFFECT
		JSR SSSFLIP		; gratuitous
@loop:
		LDX #<BASEFIRE1
		LDY #>BASEFIRE1
		LDA DATASETTE
		AND #$01
		BEQ @b1
		LDX #<BASEFIRE2
		LDY #>BASEFIRE2
@b1:	STX SPRITEIMGL+39
		STY SPRITEIMGH+39
		JSR SSSREFRESH
		JSR FLYBY
		LDY #2			; allow the phosphur to burn a little
		JSR SSSFLIP
		INC FRAME
		JSR BASEFIRE
		DEC VIC+$0D
		DEC VIC+$0D
		DEC DATASETTE
		BNE @loop
		;
		ASL SPRITEDEF+39
		LSR SPRITEDEF+39
		LDA #0
		STA VIC+$0D		; mute noise
		JSR ESCAPE
		;
		LDX PLAYER
		DEC BASES,X
		LDA BASES
		BNE @nextp
		LDA BASES+1
		BNE @nextp
		JMP RESTART
@nextp:	JMP NEXTPLAYER


;*********************************************************************
; Incur some particle damage to a player's shield
; pass X for sprite (40=laser or 41=missile)
;
DODAMAGE:
		JSR SSSUSE
		LDA SPRITEBUFH,X
		STA VECTOR1+1
		STA VECTOR2+1
		LDA SPRITEBUFL,X
		STA VECTOR1
		CLC
		ADC sssNEXT
		BCC @cc1
		INC VECTOR2+1
@cc1:	STA VECTOR2
		;
		LDA SPRITEY,X
		TAY
@x40:	LDA SPRITEX,X
		TAX
		JSR SSSPEEKXY
		LDY #0
		LSR
		BCC @cc2
		LDY #8
@cc2:	STY R1			; save top of shield offset
		ASL
		JSR SSSIMAGE
		STX VECTORBG
		STY VECTORBG+1
		STY VECTORFG+1
		TXA
		CLC
		ADC #16
		BCC @cc3
		INC VECTORFG+1
@cc3:	STA VECTORFG
		;
		LDX sssNUM
		LDA SPRITEY,X
		AND #$07
		STA R0
		CLC
		ADC R1
		STA R1			; add collision offset to shield
		;
		LDA #8
		STA R2
@bits:	LDY R0
		LDA (VECTOR1),Y
		EOR #$FF
		LDY R1
		AND (VECTORBG),Y
		STA (VECTORBG),Y
		;
		LDY R0
		LDA (VECTOR2),Y
		EOR #$FF
		LDY R1
		AND (VECTORFG),Y
		STA (VECTORFG),Y
		;
		INC R0
		INC R1
		LDA R1
		CMP #16			; past bottom of shield?
		BCS @fini
		DEC R2
		BNE @bits
@fini:
		JSR SSSREFRESH	; force all sprites to redraw
		RTS


;*********************************************************************
; Something to distract the player by
;
FLYBY:
		LDA SPRITEDEF
		ASL
		BCS @active
		LDA NMES
		CMP #10
		BCC @fini
		LDA JIFFYM
		AND #%111
		BEQ @launch
@fini:	RTS
@launch:
		INC UFO
		LDA SPRITEDEF
		ORA #$80
		STA SPRITEDEF	; enable mothership sprite
		LDY #16
		STY SPRITEY
		LDX #0
		STX MOTHERDX
		LDA FRAME
		AND #$01
		BEQ @right
		INC MOTHERDX
		LDX SSSCLIPX
@right:	STX SPRITEX
		LDA #2			; red
		LDY MODE
		BEQ @hull
		LDA #9			; multicolor with white
@hull:	STA SPRITECOL
@active:
		LDA FRAME
		AND #$07
		TAX
		LDA MASK,X
		AND #%10101010	; speed
		BNE @cont
		RTS
@cont:
		LDA UFO
		BNE @alive
		LDA EINDEX
		BEQ @dead
		RTS
@dead:	ASL SPRITEDEF
		LSR SPRITEDEF
		RTS
@alive:	LDX MOTHERDX
		BEQ @mover
@movel:	DEC SPRITEX
		DEC SPRITEX
		BNE @anim
		BEQ ESCAPE
@mover:	INC SPRITEX
		INC SPRITEX
		LDA SPRITEX
		CMP SSSCLIPX
		BCS ESCAPE
@anim:
		LDX #<MOTHERSHIP1
		LDY #>MOTHERSHIP1
		LDA MODE
		BEQ @hires
		LDX #<MOTHERVIC1
		LDY #>MOTHERVIC1
@hires:	LDA SPRITEX
		LSR
		AND #$01
		BEQ @ms1
		LDX #<MOTHERSHIP2
		LDY #>MOTHERSHIP2
		LDA MODE
		BEQ @ms1
		LDX #<MOTHERVIC2
		LDY #>MOTHERVIC2
@ms1:	STX SPRITEIMGL
		STY SPRITEIMGH
		LDX #0
		JSR SSSTOUCH
		RTS
ESCAPE:	LDX #1			; mothership escapes!  penalize the
		STX JIFFYM		; player by delaying next appearance
		DEX
		STX UFO
		DEX
		STX JIFFYL
		ASL SPRITEDEF
		LSR SPRITEDEF
		RTS


;*********************************************************************
; Here they come
;
INVADERS:
		LDA INVDY
		BEQ @stepping
		LDA #0
		STA R0
		LDX #38
		LDA MODE
		BEQ @classic
		DEC INVDY
		DEC INVDY		; since we're moving 2-pixels down
@dmove:
		INC SPRITEY,X
		INC SPRITEY,X
		LDA SPRITEDEF,X
		ASL
		BCC @dnext
		LDA SPRITEY,X
		CMP #(23*8)
		BNE @dnext
		INC R0
@dnext:	DEX
		BNE @dmove
		LDA R0
		BNE @td			; touchdown!
		LDA SPRITEY+1
		AND #$04
		BNE @d2
@d1:	JMP @anim1
@d2:	JMP @anim2
@classic:
		LDA SPRITEY,X
		CLC
		ADC INVDY
		STA SPRITEY,X
		LDA SPRITEDEF,X
		ASL
		BCC @cnext
		LDA SPRITEY,X
		CMP #(23*8)
		BNE @cnext
		INC R0
@cnext:	DEX
		BNE @classic
		STX INVDY		; no more
		LDA R0
		BNE @td			; touchdown!
		JMP @anim
@td:	PLA				; pop return address
		PLA
		LDA #>(DEATH-1)	; replace with DEATH sequence
		PHA
		LDA #<(DEATH-1)
		PHA
		JMP @anim
@stepping:
		LDA FRAME
		AND #$07
		TAX
		LDA MASK,X
		LDY INVINDEX
		AND SPEED,Y
		BNE @cont
		RTS
@cont:
		LDY INVINDEX
		LDA STRIDE,Y
		STA ACOPY
		LDX #38
		LDA INVDX
		BEQ @rmove
@lmove:
		LDA SPRITEX,X
		SEC
		SBC ACOPY
		STA SPRITEX,X
		LDA SPRITEDEF,X
		ASL
		BCC @lok
		LDA SPRITEX,X
		CMP #17
		BCS @lok
		LDA #0
		STA INVDX		; go right on next pass
		LDA #8
		STA INVDY		; and go down
@lok:	DEX
		BNE @lmove
		BEQ @anim
@rmove:
		LDA SPRITEX,X
		CLC
		ADC ACOPY
		STA SPRITEX,X
		LDA SPRITEDEF,X
		ASL
		BCC @rok
		LDA SPRITEX,X
		CMP #(23*8)-2
		BCC @rok
		STA INVDX		; go left on next pass
		LDA #8
		STA INVDY		; and go down
@rok:	DEX
		BNE @rmove
@anim:
		LDA SPRITEX+1
		AND #$02
		BNE @anim2
@anim1:
		LDX #<INVADER1A
		LDY #>INVADER1A
		STX SPRITEIMGL+1
		STY SPRITEIMGH+1
		LDX #<INVADER2A
		LDY #>INVADER2A
		STX SPRITEIMGL+11
		STY SPRITEIMGH+11
		LDX #<INVADER3A
		LDY #>INVADER3A
		STX SPRITEIMGL+25
		STY SPRITEIMGH+25
		BNE @fini
@anim2:
		LDX #<INVADER1B
		LDY #>INVADER1B
		STX SPRITEIMGL+1
		STY SPRITEIMGH+1
		LDX #<INVADER2B
		LDY #>INVADER2B
		STX SPRITEIMGL+11
		STY SPRITEIMGH+11
		LDX #<INVADER3B
		LDY #>INVADER3B
		STX SPRITEIMGL+25
		STY SPRITEIMGH+25
@fini:
		LDA SPRITEZ+1
		ORA #%11100010	; force make / copy / null + fast copy
		STA SPRITEZ+1	; on alien1 master sprite
		LDA SPRITEZ+11
		ORA #%11100010	; force make / copy / null + fast copy
		STA SPRITEZ+11	; on alien2 master sprite
		LDA SPRITEZ+25
		ORA #%11100010	; force make / copy / null + fast copy
		STA SPRITEZ+25	; on alien3 master sprite
		RTS


;*********************************************************************
; Process player input
;
MOVEBASE:
		LDY #$00
		STY $9113
		LDA #$7F
		STA $9122
		LDA $9120
		AND #$80
		BNE @joy1
		INC SPRITEX+39	; move right
		INC SPRITEX+39
		BNE @check
@joy1:
		LDA #$FF
		STA $9122
		LDA $9111
		AND #$10
		BNE @fire
		DEC SPRITEX+39	; move left
		DEC SPRITEX+39
@check:
		LDX #39
		JSR SSSTOUCH	; redraw base
		LDA SPRITEX+39
		CMP #(3*8)
		BCS @okl
		LDA #(3*8)
@okl:	CMP #(21*8)
		BCC @okr
		LDA #(21*8)
@okr:	STA SPRITEX+39	; update
		AND #$07
		BNE @fire
		CMP #(12*8)+1	; influence next firing column
		BCC @div2
		ASL NMENEXT
		BNE @fire
@div2:	LSR NMENEXT
@fire:
		LDA SPRITEDEF+41
		ASL
		BCS @fini		; missile still active?
		LDA $9111
		AND #$20		; got joystick FIRE ?
		BNE @fini
		LDA #%11100100	; enable + collision + ghost + float Y
		STA SPRITEDEF+41
		LDA #6			; shorten to 6-pixels high
		STA SPRITEH+41
		LDA #<$8328
		STA SPRITEIMGL+41
		LDA #>$8328
		STA SPRITEIMGH+41
		LDA SPRITEX+39
		CLC
		ADC #7
		STA SPRITEX+41
		LDY #(23*8)-6
		STY SPRITEY+41
		LDX #41
		JSR SSSTOUCH	; redraw missile
		LDA #$FE
		STA VIC+$0D
@fini:	RTS


;*********************************************************************
; Enemy laser firing solution
;
NMEFIRE:
		INC NMENEXT
		LDA NMENEXT
		CMP #13
		BCC @next
		LDA #0
		STA NMENEXT
		; check for existing laser
@next:	LDA SPRITEDEF+40
		ASL
		BCS @cont
		INC NMEBOLT
		LDA NMEBOLT
		AND #$03
		CMP #$03
		BEQ @fini
		JMP @emit
@cont:
		LDA SPRITEZ+40
		AND #%1000		; collision?
		BNE @hit
@descend:
		LDA SPRITEY+40
		CLC
		ADC #3
		STA SPRITEY+40
		CMP #(24*8)		; just a border sanity check,
		BCS @miss		; should never occur
@anim:
		LDA NMEBOLT
		AND #$03
		ASL
		TAX
		LDA LASER,X
		STA SPRITEIMGL+40
		LDA LASER+1,X
		STA SPRITEIMGH+40
		LDA FRAME
		AND #$03
		ASL
		CLC
		ADC SPRITEIMGL+40
		BCC @cc
		INC SPRITEIMGH+40
@cc:	STA SPRITEIMGL+40
@anim2:	LDX #40			; redraw laser
		JSR SSSTOUCH
@fini:	RTS
@miss:
		LDA #%10101100	; floating 8x8 ghost w/o collision
		STA SPRITEDEF+40
@hit:
		LDA SPRITEBACK+40
		CMP #$80
		BCS @rom
		CMP #$5A		; friendly fire?
		BCS @descend	; allow laser to passthru
@rom:	LDA NMEHIT
		BNE @hit2
		INC NMEHIT		; set flag that bolt has exploded
		DEC SPRITEX+40	; adjust X for explosion image
		LDA SPRITECY+40
		CMP SPRITEY+40
		BCC @lower		; don't explode any higher
		AND #$F8
		STA SPRITEY+40	; adjust Y for explosion image
@lower:	LDX #<DAMAGE40
		LDY #>DAMAGE40
		STX SPRITEIMGL+40
		STY SPRITEIMGH+40
		BNE @anim2
@hit2:
		LDA SPRITEBACK+40
		CMP #$28
		BCC @shield		; hit part of player's shield?
		CMP #$54		; baseship sprite lo char
		BCC @done
		CMP #$5A		; baseship sprite hi char
		BCS @done
@gotme:	PLA				; pop return address
		PLA
		LDA #>(DEATH-1)	; replace with DEATH sequence
		PHA
		LDA #<(DEATH-1)
		PHA
		BNE @done
@shield:
		LDX #40
		JSR DODAMAGE
@done:	ASL SPRITEDEF+40
		LSR SPRITEDEF+40
		JMP @anim2
@emit:
		LDA NMENEXT
		ASL				; make index to fetch word
		TAX
		LDA NMECOL,X
		STA VECTOR1
		LDA NMECOL+1,X
		STA VECTOR1+1
		LDY #0
		STY NMEHIT		; clear flag
		STY R0			; clear invader sprite# to fire
@find:	LDA (VECTOR1),Y
		BEQ @chk
		STA R0			; save lowest invader
		INY
		BNE @find
@chk:
		LDX R0
		BNE @fire
		RTS				; no enemies this column, skip
@fire:
		LDA NMES
		CMP #20
		BCC @fire2
		CPX #11			; top enemy row does not fire, until 1/2
		BCS @fire2		; its invasion force is destroyed . . . 
		RTS
@fire2:	LDA SPRITEX,X
		ADC OFFSET-1,X
		STA SPRITEX+40
		LDA SPRITEY,X
		CLC
		ADC #8
		STA SPRITEY+40
		LDY #18
		CMP #(21*8)
		BNE @ck2
		JSR REMOVELAYER
@ck2:	INY
		CMP #(22*8)
		BNE @ok
		JSR REMOVELAYER
@ok:	LDA #%11101100	; floating 8x8 ghost w/ collision
		STA SPRITEDEF+40
		JMP @anim


;*********************************************************************
; Remove a shield layer
; pass Y (18 or 19)
;
REMOVELAYER:
		CPY #18
		BEQ @y18
		LDA LAYER
		CMP #2
		BNE @y19
		RTS				; already removed bottom layer
@y19:	
		LDX #$08		; index to bottom
		BNE @remove
@y18:
		LDX #$00		; index to top
		LDA LAYER
		CMP #1
		BNE @remove
		RTS				; already removed top layer
@remove:
		INC LAYER
		LDY #$1C
		STX VECTOR1
		STY VECTOR1+1
		LDA #20
		STA R0
		;
@top:	LDA #0
		LDY #7
@zero:	STA (VECTOR1),Y
		DEY
		BPL @zero
		LDA VECTOR1
		CLC
		ADC #16
		BCC @cc
		INC VECTOR1+1
@cc:	STA VECTOR1
		DEC R0
		BNE @top
		RTS


;*********************************************************************
; Show player's score
;
SCORESTATUS:
		LDX #1
		LDA PLAYER
		BEQ @p1
		CMP #2
		BCS @fini
		LDX #17
@p1:	LDY #22
		JSR SSSPLOT
		LDA #2
		STA R0
		LDA #5			; green
		STA COLORCODE
		LDA PLAYER
		ASL
		TAX
@loop:	LDA SCORE,X
		LSR
		LSR
		LSR
		LSR
		CLC
		ADC #40
		JSR SSSPRINT
		LDA SCORE,X
		AND #$0F
		CLC
		ADC #40
		JSR SSSPRINT
		INX
		DEC R0
		BNE @loop
		;
		LDX #1
		LDA PLAYER
		BNE @p2
		LDX #20
@p2:	LDY #22
		JSR SSSPLOT
		LDX PLAYER
		LDA BASES,X
		BEQ @fini
		TAX
@bases:	DEX
		BEQ @xicon
		LDA #50			; baseship icon
		JSR SSSPRINT
		LDA PLAYER
		BNE @bases
		DEC CRSRCOL
		DEC CRSRCOL
		BNE @bases
@xicon:	LDA #$E3
		JSR SSSPRINT
@fini:	RTS


;*********************************************************************
; Update player's score
; send Y with decimal number to add
;
SCOREUPDATE:
		LDA PLAYER
		ASL
		TAX
		INX				; 1's
		TYA
		SED
		CLC
		ADC SCORE,X
		STA SCORE,X
		BCC @cc
@cs:	DEX				; too bad if 10,000 is breached ... no one
		LDA SCORE,X		; likes a smarty-pants!  :P
		CLC
		ADC #$01
		STA SCORE,X
		BCS @cs
@cc:	CLD
		LDX PLAYER
		LDA EXTRA,X
		BNE @show
		TXA
		ASL
		TAX
		LDA SCORE,X
		CMP #$15
		BCC @show
		LDA #3			; bonus effect
		STA EFFECT
		LDA #$81
		STA EINDEX
		LDX PLAYER
		INC EXTRA,X		; woot!
		INC BASES,X
@show:	JSR SCORESTATUS
		RTS


;*********************************************************************
; Display function key top
;
SHOWTOP:
		LDX #4
		LDY #13
		JSR SSSPLOT
		JSR SSSPRINTS
		.byte	$C9,$EC,$E2,$E2,$FB,$00
		LDX #4
		LDY #14
		JSR SSSPLOT
		RTS


;*********************************************************************
; Display [Fy] START Px
;
SHOWSTART:
		STY @n
		LDY #$C5		; green
		TXA
		CMP #1
		BEQ @p1
		LDY #$C3		; cyan
@p1:	CLC
		ADC #$B0
		STA @p
		STY @c
		JSR SHOWTOP
		JSR SSSPRINTS
		.byte	51,52
@n:		.byte	54,$E1
@c:		.byte	$C5,$A0,$93,$94,$81,$92,$94,$A0
@p:		.byte	$B1,$90,$00
		JMP SHOWBOTTOM


;*********************************************************************
; Display [F5] EASIER|NORMAL|HARDER
;
SHOWDIFFICULTY:
		JSR SHOWTOP
		JSR SSSPRINTS
		.byte	51,52,56,$E1,$00
		LDA DIFFICULTY
		BNE @nez
@ez:	JSR SSSPRINTS
		.byte	$C7,$A0,$85,$81,$93,$89,$85,$92,$A0,$A0,$00
		RTS
@nez:	CMP #1
		BNE @adv
		JSR SSSPRINTS
		.byte	$C5,$A0,$8E,$8F,$92,$8D,$81,$8C,$A0,$A0,$00
		RTS
@adv:	JSR SSSPRINTS
		.byte	$C4,$A0,$88,$81,$92,$84,$85,$92,$A0,$A0,$00
		RTS


;*********************************************************************
; Display [F7] CLASSIC| VIC= 20
;
SHOWMODE:
		JSR SHOWTOP
		JSR SSSPRINTS
		.byte	51,52,57,$E1,$00
		LDA MODE
		BNE @vic20
@classic:
		JSR SSSPRINTS
		.byte	$C1,$A0,$83,$8C,$81,$93,$93,$89,$83,$A0,$00
		RTS
@vic20:
		JSR SSSPRINTS
		.byte	$C6,$A0,$96,$C7,$89,$C5,$83,$C2,$BD,$A0,$C1,$B2,$B0,$A0,$00
		RTS


;*********************************************************************
; Display function key bottom
;
SHOWBOTTOM:
		LDX #4
		LDY #15
		JSR SSSPLOT
		JSR SSSPRINTS
		.byte	$C9,$FC,53,53,$FE,$00
		LDY #0			; immediate
		JSR SSSFLIP
		RTS


;*********************************************************************
; Draw bottom status line
;
STATUSLINE:
		LDA #5			; green
		STA COLORCODE
		LDX #0
		LDY #23
		JSR SSSPLOT
@draw:	LDA #$E3
		JSR SSSPRINT
		LDX CRSRCOL
		BNE @draw
		RTS


;*********************************************************************
; Pass A for MODE desired (0=CLASSIC, 1=DELUXE)
;
SWITCHMODE:
		STA MODE
		BNE @deluxe
@classic:
		LDA #8			; black screen / black border
		BNE @sprites
@deluxe:
		LDA #12			; black screen / magenta border
		LDY PLAYER
		BEQ @sprites
		LDA #14			; black screen / blue border
		;
@sprites:
		STA VIC+$0F
		LDX #1			; fill with white character color
		STX COLORCODE
		JSR SSSINIT		; initialize software sprite stack
@init:
		; mothership
		LDA #%00001010	; float horizontal 16w x 8h sprite
		LDY #8
		JSR SSSCREATE
		;
		LDY #(4*8)		; start from top
		LDA MODE
		BEQ @dy
		LDY #(-7*8)-2	; start from off-screen
@dy:	STY R0
		;
		; top row invaders
		LDX MODE
		LDA ALIENS,X	; floating 8x8 sprite
		LDY #8
		JSR SSSCREATE
		LDA #7			; yellow
		LDX #<INVADER1A
		LDY #>INVADER1A
		JSR SSSANIM
		LDX #(3*8)+4
		LDY R0
		JSR SSSMOVEXY
@alien1:
		LDX MODE
		LDA ALIENS,X
		ORA #SPRITEDEF4	; repeating sprite
		LDY #8
		JSR SSSCREATE
		LDA #7			; yellow
		STA SPRITECOL,X
		LDA SPRITEX-1,X
		CLC
		ADC #16
		STA SPRITEX,X
		LDA R0
		STA SPRITEY,X
		CPX #10
		BNE @alien1
		;
		; next 2 row of invaders
		LDX MODE
		LDA ALIENS+2,X	; floating 16w x 8h sprite
		LDY #8
		JSR SSSCREATE
		LDA #3			; cyan
		LDX #<INVADER2A
		LDY #>INVADER2A
		JSR SSSANIM
		LDX #(3*8)+3
		LDA R0
		CLC
		ADC #16
		STA R0
		TAY
		JSR SSSMOVEXY
@alien2a:
		LDX MODE
		LDA ALIENS+2,X
		ORA #SPRITEDEF4	; repeating sprite
		LDY #8
		JSR SSSCREATE
		LDA #3			; cyan
		STA SPRITECOL,X
		LDA SPRITEX-1,X
		CLC
		ADC #24
		STA SPRITEX,X
		LDA R0
		STA SPRITEY,X
		CPX #17
		BNE @alien2a
		LDX #(3*8)+3
		STX XCOPY
		LDA R0
		CLC
		ADC #16
		STA R0
@alien2b:
		LDX MODE
		LDA ALIENS+2,X
		ORA #SPRITEDEF4	; repeating sprite
		LDY #8
		JSR SSSCREATE
		LDA #3			; cyan
		STA SPRITECOL,X
		LDA XCOPY
		STA SPRITEX,X
		CLC
		ADC #24
		STA XCOPY
		LDA R0
		STA SPRITEY,X
		CPX #24
		BNE @alien2b
		;
		; next 2 row of invaders
		LDX MODE
		LDA ALIENS+4,X	; floating 16w x 8h sprite
		LDY #8
		JSR SSSCREATE
		LDA #5			; green
		LDX #<INVADER3A
		LDY #>INVADER3A
		JSR SSSANIM
		LDX #(3*8)+2
		STX XCOPY
		LDA R0
		CLC
		ADC #16
		STA R0
		TAY
		JSR SSSMOVEXY
@alien3a:
		LDX MODE
		LDA ALIENS+4,X
		ORA #SPRITEDEF4	; repeating sprite
		LDY #8
		JSR SSSCREATE
		LDA #5			; green
		STA SPRITECOL,X
		LDA SPRITEX-1,X
		CLC
		ADC #24
		STA SPRITEX,X
		LDA R0
		STA SPRITEY,X
		CPX #31
		BNE @alien3a
		LDX #(3*8)+2
		STX XCOPY
		LDA R0
		CLC
		ADC #16
		STA R0
@alien3b:
		LDX MODE
		LDA ALIENS+4,X
		ORA #SPRITEDEF4	; repeating sprite
		LDY #8
		JSR SSSCREATE
		LDA #5			; green
		STA SPRITECOL,X
		LDA XCOPY
		STA SPRITEX,X
		CLC
		ADC #24
		STA XCOPY
		LDA R0
		STA SPRITEY,X
		CPX #38
		BNE @alien3b
@player:
		LDA #%00001010	; float horizontal 16w x 8h sprite
		LDY #8
		JSR SSSCREATE
@laser:
		LDA #%01101100	; floating 8x8 ghost w/ collision
		LDY #8
		JSR SSSCREATE
@missile:
		LDA #%01101100	; floating 8x8 ghost w/ collision
		LDY #8
		JSR SSSCREATE
		;
		; adjust for level
		LDA #0
		STA INVINDEX
		LDX PLAYER
		LDA LEVEL,X
		CMP #6
		BCC @cc
		LDA #6
@cc:	ASL
		ASL
		ASL
		LDY MODE
		BEQ @fixed
		CLC
		ADC #11*8+2
@fixed:	STA INVDY
		;
		; refresh player's shields
		LDX #$00
		LDY #$1C
		STX VECTOR1
		STY VECTOR1+1
		LDX #<SHIELD
		LDY #>SHIELD
		STX VECTOR2
		STY VECTOR2+1
		LDY #4
		STY R2
@r0:	LDY #80
		STY R0
		LDY #79
		STY R1
@r1:	LDA (VECTOR2),Y
		DEC R0
		LDY R0
		STA (VECTOR1),Y
		DEC R1
		LDY R1
		BPL @r1
		LDA VECTOR1
		CLC
		ADC #80
		BCC @np
		INC VECTOR1+1
@np:	STA VECTOR1
		DEC R2
		BNE @r0
		;
		LDA VIC+$0F
		AND #$07		; use border color as
		STA R4			; shield paint
		LDA MODE
		BNE @shields
		LDA #5			; green
		STA COLORCODE
		LDA SPRITEDEF+39
		ORA #SPRITEDEF5	; ghost mode on
		STA SPRITEDEF+39
		LDX #0
		LDY #18
		JSR SSSPLOT
@cgrn:	LDA #SSSNULL	; apply colored cellophane on monitor
		JSR SSSPRINT
		LDY CRSRROW
		BNE @cgrn
		LDA #2			; red
		STA COLORCODE
@cred:	LDA #SSSNULL	; apply colored cellophane on monitor
		JSR SSSPRINT
		LDX CRSRCOL
		BNE @cred
		LDA #5			; use green as
		STA R4			; shield paint
@shields:
		LDA #0
		STA R0
		LDX #1
@p0:	LDA #4
		STA R1
@p1:	LDY #18
@p2:	STX XCOPY
		STY YCOPY
		JSR SSSPLOT
		LDA R4			; dip brush in shield paint
		LDX MODE
		BEQ @char		; classic keeps green across entire row
		LDX CRSRCOL		; while VIC allows white between shields
		CPX #2
		BCC @vic
		CPX #5
		BCC @char
		CPX #7
		BCC @vic
		CPX #10
		BCC @char
		CPX #12
		BCC @vic
		CPX #15
		BCC @char
		CPX #17
		BCC @vic
		CPX #20
		BCC @char
@vic:	LDA #1			; make spaces between shields white
@char:	STA COLORCODE
		LDA R0
		JSR SSSPOKE
@skip:	LDY YCOPY
		LDX XCOPY
		INC R0
		INY
		CPY #20
		BNE @p2
		INX
		DEC R1
		BPL @p1
		CPX #20
		BCC @p0
		;
		JSR STATUSLINE
		JSR SCORESTATUS
		RTS


;*********************************************************************
; Background software interrupt routine
;
MYIRQ:
		CLD
		LDA NMES
		BEQ @v1
@step:	LDX BEEP
		BNE @v1x
		ASL
		STA BEEP
		INC STEPS
		LDA STEPS
		AND #$07
		TAX
		LDA STEP,X
		BEQ @v1
		LDX #4
		STX BEEP
@v1:	STA VIC+$0A		; voice #1
@v1x:	DEC BEEP
		;
		LDA EFFECT
		BEQ @v2
		CMP #1
		BNE @ms
@inv:	DEC EINDEX
		LDA EINDEX
		BEQ @xv2
		AND #$07
		BEQ @invd
		LDA VIC+$0B
		CLC
		ADC #4
		BNE @v2
@invd:	LDA #200
		BNE @v2
@ms:	CMP #2
		BNE @bonus
		DEC EINDEX
		LDA EINDEX
		BEQ @xv2
		AND #$08
		BNE @msdec
		LDA VIC+$0B
		CLC
		ADC #$02
		BNE @v2
@msdec:	LDA VIC+$0B
		SEC
		SBC #$03
		BNE @v2
@bonus:	DEC EINDEX
		LDA EINDEX
		BEQ @xv2
		AND #$18
		BEQ @v2
		LDA JIFFYL
		AND #$01
		BEQ @v2
		LDA #$F0
		BNE @v2
@xv2:	STA EFFECT
@v2:	STA VIC+$0B		; voice #2
@v2x:	LDA UFO
		BEQ @v3
		INC CYCLE
		LDA CYCLE
		LSR
		LSR
		LSR
		TAX
		CPX #28
		BCC @cycle
		LDX #0			; reset
		STX CYCLE
@cycle:	LDA MCOLOR,X
		STA VIC+$0E		; set new aux color / volume
		LDA VIC+$0C
		BEQ @v3n
		SEC
		SBC #3
		CMP #232
		BCS @v3
@v3n:	LDA #247
@v3:	STA VIC+$0C		; voice #3
		JMP SSSIRQ		; process synchronous flipping


;*********************************************************************
; Game runtime variables
;
BASEHIT:	.byte 0		; flag when a missile hits
BASES:		.res 2		; players' lives
BEEP:		.byte 0		; duration
CYCLE:		.byte 0		; auxiliary color cycle
DIFFICULTY:	.byte 1		; 0=easier, 1=normal, 2=harder
EFFECT:		.byte 0		; 0=none, 1=invader, 2=mothership, 3=bonus
EINDEX:		.byte 0		; sound effect register
INVDX:		.byte 0		; 0 (right) or <>0 (left)
INVDY:		.byte 0		; 0 (horizontal) <>0 (vertical)
INVINDEX:	.byte 0		; index into SPEED & STRIDE table (0-6)
EXTRA:		.res 2		; extra base bonus @ 1500-points
FLIP:		.byte 0		; wait for vsync counter
FRAME:		.byte 0		; video frame counter for action/animation timing
LAYER:		.byte 0		; remove next shield layer (0-2)
LEVEL:		.res 2		; players' level
MODE:		.byte 0		; 0=classic, 1=color
MOTHERDX:	.byte 0		; 0 (right) or <>0 (left)
NMEBOLT:	.byte 0		; type: 0-2
NMECOL0:	.res 6		; array with occupied invaders
NMECOL1:	.res 2		; array with occupied invaders
NMECOL2:	.res 5		; array with occupied invaders
NMECOL3:	.res 2		; array with occupied invaders
NMECOL4:	.res 6		; array with occupied invaders
NMECOL5:	.res 2		; array with occupied invaders
NMECOL6:	.res 5		; array with occupied invaders
NMECOL7:	.res 2		; array with occupied invaders
NMECOL8:	.res 6		; array with occupied invaders
NMECOL9:	.res 2		; array with occupied invaders
NMECOLA:	.res 5		; array with occupied invaders
NMECOLB:	.res 2		; array with occupied invaders
NMECOLC:	.res 6		; array with occupied invaders
NMEHIT:		.byte 0		; flag when a bolt hits
NMENEXT:	.byte 0		; next firing column: 0-C
NMES:		.byte 0		; 0-38
PLAYER:		.byte 0		; player up: 0/1
PLAYERS:	.byte 0		; # of players up (0 = initial startup)
SCORE:		.res 4		; players' score in BCD
STEPS:		.byte 0		; invader step counter
UFO:		.byte 0		; mothership sound effect


		.segment "RODATA"

;*********************************************************************
; Game data
;
ALIENS:	.byte %10101100,%10001100,%10101110,%10001110,%10101110,%10001110
LASER:	.word	LASER1,LASER2,LASER3

MCOLOR:	.byte	$2F,$AF,$2F,$AF
		.byte	$8F,$9F,$8F,$9F
		.byte	$7F,$FF,$7F,$FF
		.byte	$5F,$DF,$5F,$DF
		.byte	$3F,$BF,$3F,$BF
		.byte	$6F,$ED,$6F,$ED
		.byte	$4F,$CF,$4F,$CF

OFFSET:	.byte	2,2,3,3,2,3,2,2,3,3
		.byte	3,4,3,4,3,4,3
		.byte	4,3,4,3,4,3,4
		.byte	4,5,4,5,4,5,4
		.byte	5,4,5,4,5,4,5

NMECOL:	.word	NMECOL0,NMECOL1,NMECOL2,NMECOL3,NMECOL4
		.word	NMECOL5,NMECOL6,NMECOL7,NMECOL8,NMECOL9
		.word	NMECOLA,NMECOLB,NMECOLC

NMEPOS:	.byte	1,7,14,16,22,29,31,37,44,46
		.byte	2,9,17,24,32,39,47
		.byte	3,10,18,25,33,40,48
		.byte	4,11,19,26,34,41,49
		.byte	5,12,20,27,35,42,50

SPEED:	.byte	%10000000	; 27-38
		.byte	%10001000	; 17-26
		.byte	%10010010	; 11-16
		.byte	%10101010	; 6-10
		.byte	%11101110	; 4-5
		.byte	%11101110	; 2-3
		.byte	%11111111	; 1

STRIDE:	.byte	1,1,1,1,1,2,2

STEP:	.byte	0,175,0,159,0,147,0,135


;*********************************************************************
; Sprite data
;
BASESHIP:
		.byte	%00000001
		.byte	%00000011
		.byte	%00000011
		.byte	%01111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		;
		.byte	%00000000
		.byte	%10000000
		.byte	%10000000
		.byte	%11111100
		.byte	%11111110
		.byte	%11111110
		.byte	%11111110
		.byte	%11111110
BASEFIRE1:
		.byte	%00000000
		.byte	%00000110
		.byte	%00101000
		.byte	%01101101
		.byte	%10101010
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		;
		.byte	%00000000
		.byte	%00011000
		.byte	%10100000
		.byte	%10110100
		.byte	%10101010
		.byte	%11111110
		.byte	%11111110
		.byte	%11111110
BASEFIRE2:
		.byte	%00000000
		.byte	%01100000
		.byte	%00010010
		.byte	%10110110
		.byte	%01010101
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		;
		.byte	%00000000
		.byte	%01100000
		.byte	%00010100
		.byte	%11011000
		.byte	%01010100
		.byte	%11111110
		.byte	%11111110
		.byte	%11111110

DAMAGE40:
		.byte	%00110000
		.byte	%10011000
		.byte	%00110100
		.byte	%01111000
		.byte	%10111000
		.byte	%01111100
		.byte	%10111000
		.byte	%01010100

DAMAGE41:
		.byte	%01101000
		.byte	%10111000
		.byte	%01110000
		.byte	%11101000
		.byte	%01110000
		.byte	%01111000
		.byte	%11110000
		.byte	%01111000

INVADER1A:
		.byte	%00011000
		.byte	%00111100
		.byte	%01111110
		.byte	%11011011
		.byte	%11111111
		.byte	%00100100
		.byte	%01011010
		.byte	%10100101
INVADER1B:
		.byte	%00011000
		.byte	%00111100
		.byte	%01111110
		.byte	%11011011
		.byte	%11111111
		.byte	%01011010
		.byte	%10000001
		.byte	%01000010

INVADER2A:
		.byte	%00100001
		.byte	%10010010
		.byte	%10111111
		.byte	%11101101
		.byte	%01111111
		.byte	%00111111
		.byte	%00100001
		.byte	%01000000
		;
		.byte	%00000000
		.byte	%01000000
		.byte	%01000000
		.byte	%11000000
		.byte	%10000000
		.byte	%00000000
		.byte	%00000000
		.byte	%10000000
INVADER2B:
		.byte	%00100001
		.byte	%00010010
		.byte	%00111111
		.byte	%01101101
		.byte	%11111111
		.byte	%10111111
		.byte	%10100001
		.byte	%00010010
		;
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%10000000
		.byte	%11000000
		.byte	%01000000
		.byte	%01000000
		.byte	%00000000

INVADER3A:
		.byte	%00001111
		.byte	%01111111
		.byte	%11111111
		.byte	%11100110
		.byte	%11111111
		.byte	%00011001
		.byte	%00110110
		.byte	%11000000
		;
		.byte	%00000000
		.byte	%11100000
		.byte	%11110000
		.byte	%01110000
		.byte	%11110000
		.byte	%10000000
		.byte	%11000000
		.byte	%00110000
INVADER3B:
		.byte	%00001111
		.byte	%01111111
		.byte	%11111111
		.byte	%11100110
		.byte	%11111111
		.byte	%00111001
		.byte	%01100110
		.byte	%00110000
		;
		.byte	%00000000
		.byte	%11100000
		.byte	%11110000
		.byte	%01110000
		.byte	%11110000
		.byte	%11000000
		.byte	%01100000
		.byte	%11000000

LASER1:	; 0
		.byte	%01000000
		.byte	%00100000
		.byte	%01000000
		.byte	%10000000
		.byte	%01000000
		.byte	%00100000
		.byte	%01000000
		.byte	%01000000
		; 1
		.byte	%10000000
		.byte	%01000000
		; 2
		.byte	%00100000
		.byte	%01000000
		; 3
		.byte	%10000000
		.byte	%01000000

LASER2:	; 0
		.byte	%01000000
		.byte	%01000000
		.byte	%01000000
		.byte	%10100000
		.byte	%01000000
		.byte	%01000000
		.byte	%01000000
		.byte	%10100000
		; 1
		.byte	%01000000
		.byte	%01000000
		; 2
		.byte	%01000000
		.byte	%10100000
		; 3
		.byte	%01000000
		.byte	%01000000

LASER3:	; 0
		.byte	%01000000
		.byte	%01000000
		.byte	%01000000
		.byte	%01000000
		.byte	%01000000
		.byte	%01000000
		.byte	%01000000
		.byte	%11100000
		; 1
		.byte	%01000000
		.byte	%01000000
		; 2
		.byte	%01000000
		.byte	%01000000
		; 3
		.byte	%01000000
		.byte	%01000000

MOTHERSHIP1:
		.byte	%00000011
		.byte	%00001111
		.byte	%00011111
		.byte	%00111111
		.byte	%01001100
		.byte	%11111111
		.byte	%00111001
		.byte	%00010000
		;
		.byte	%11000000
		.byte	%11110000
		.byte	%11111000
		.byte	%11111100
		.byte	%11001100
		.byte	%11111111
		.byte	%10011100
		.byte	%00001000
MOTHERSHIP2:
		.byte	%00000011
		.byte	%00001111
		.byte	%00011111
		.byte	%00111111
		.byte	%00110011
		.byte	%11111111
		.byte	%00111001
		.byte	%00010000
		;
		.byte	%11000000
		.byte	%11110000
		.byte	%11111000
		.byte	%11111100
		.byte	%00110010
		.byte	%11111111
		.byte	%10011100
		.byte	%00001000

MOTHERVIC1:
		.byte	%00000011
		.byte	%00001111
		.byte	%00111111
		.byte	%11111111
		.byte	%01100110
		.byte	%11111111
		.byte	%00111111
		.byte	%00001100
		;
		.byte	%11000000
		.byte	%11110000
		.byte	%11111100
		.byte	%11111111
		.byte	%01100110
		.byte	%11111111
		.byte	%11111100
		.byte	%00110000
MOTHERVIC2:
		.byte	%00000011
		.byte	%00001111
		.byte	%00111111
		.byte	%11111111
		.byte	%10011001
		.byte	%11111111
		.byte	%00111111
		.byte	%00001100
		;
		.byte	%11000000
		.byte	%11110000
		.byte	%11111100
		.byte	%11111111
		.byte	%10011001
		.byte	%11111111
		.byte	%11111100
		.byte	%00110000

SHIELD:
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		;
		.byte	%00000001
		.byte	%00011111
		.byte	%00111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111111
		.byte	%01111110
		.byte	%01111100
		.byte	%01111000
		.byte	%01111000
		;
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		;
		.byte	%00000000
		.byte	%11110000
		.byte	%11111000
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%11111100
		.byte	%01111100
		.byte	%00111100
		.byte	%00111100
		;
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000
		.byte	%00000000

EXPLODE:
		.byte	%00000000
		.byte	%01001001
		.byte	%00101010
		.byte	%00000000
		.byte	%01100011
		.byte	%00000000
		.byte	%00101010
		.byte	%01001001

SCORE50:
		.byte	%00000000
		.byte	%00111110
		.byte	%00100000
		.byte	%00111100
		.byte	%00000010
		.byte	%00100010
		.byte	%00011100
		.byte	%00000000
		;
		.byte	%00000000
		.byte	%00111000
		.byte	%01000100
		.byte	%01000100
		.byte	%01000100
		.byte	%01000100
		.byte	%00111000
		.byte	%00000000
SCORE100:
		.byte	%00000000
		.byte	%00100011
		.byte	%01100100
		.byte	%00100100
		.byte	%00100100
		.byte	%00100100
		.byte	%01110011
		.byte	%00000000
		;
		.byte	%00000000
		.byte	%00011000
		.byte	%10100100
		.byte	%10100100
		.byte	%10100100
		.byte	%10100100
		.byte	%00011000
		.byte	%00000000
SCORE300:
		.byte	%00000000
		.byte	%01110001
		.byte	%00001010
		.byte	%00110010
		.byte	%00001010
		.byte	%00001010
		.byte	%01110001
		.byte	%00000000
		;
		.byte	%00000000
		.byte	%10001100
		.byte	%01010010
		.byte	%01010010
		.byte	%01010010
		.byte	%01010010
		.byte	%10001100
		.byte	%00000000

