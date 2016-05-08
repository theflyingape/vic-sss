;*********************************************************************
; DEMO featuring VIC Software Sprite Stack - MMX edition
; written by Robert Hurst <spock@hurst-ri.us>
; updated version: 19-Apr-2010
;*********************************************************************

		.include "VIC-SSS-MMX.h"
		.include "SSS.h"

		.segment "CODE"

		LDA #$1B
		STA VIC+$0F
		LDA #6
		STA COLORCODE
		JSR SSSINIT		; must occur BEFORE re-directing IRQ
;
; implement my interrupt vector
		SEI
		LDX #<SSSIRQ
		LDY #>SSSIRQ
		STX $0314
		STY $0315
		CLI

		LDA #%10001101	; enable an 8x16 sprite that floats X-Y
		LDY #16			; pixel height
		JSR SSSCREATE
		LDX #0
		STX R0
		LDY #(8*12)+16
		JSR SSSMOVEXY

		LDA #%10001100	; enable an 8x8 sprite that floats X-Y
		LDY #8			; pixel height
		JSR SSSCREATE
		LDA SSSCLIPX
		CLC
		ADC #8
		TAX
		LDY #(8*9)+20
		JSR SSSMOVEXY

		LDA #%10001011	; enable an 16x16 sprite that floats X
		LDY #16			; pixel height
		JSR SSSCREATE
		LDX #0
		STX R1
		LDY #(8*15)+16
		JSR SSSMOVEXY

TITLE:
		JSR SSSPRINTS
		.byte $F2,"SOFTWARE ",$F5,"SPRITE ",$F6,"STACK",13,13,0
		JSR SSSPRINTS
		.byte $F0,"  A TUTORIAL DEMO",13,0
		JSR SSSPRINTS
		.byte $F4,"  BY ROBERT HURST",13,13,0
		JSR SSSPRINTS
		.byte $F3," RELEASED 19-APR-2010"
		.byte 0
@loop:	JSR HEROMOVE
		JSR QMANMOVE
		JSR ANYKEY
		BEQ @loop

DEMO1:
		JSR SSSPRINTS
		.byte $F4,"THE FIRST THING TO DO",13
		.byte "IS TO INITIALIZE THE",13
		.byte "SOFTWARE SPRITE STACK:",13,13,0
		JSR SSSPRINTS
		.byte $F6,"JSR ",$F2,"SSSINIT",13,13,13
		.byte $F0,"IT PUTS THE VIC IN A",13
		.byte "DUAL-BUFFER VIDEO MODE"
		.byte $F6,"  @ $1000 & $1200",13
		.byte $F0,"A PLAYFIELD AND COLOR",13
		.byte $F6,"  @ $1400 & $1600",13
		.byte $F0,"REGISTERS AND STORAGE",13
		.byte $F6,"  @ $1800 - $1B7F",13
		.byte $F0,"USES CUSTOM CHARACTERS"
		.byte $F6,"  @ $1C00 - $1FFF"
		.byte 0
@loop:	JSR ANYKEY
		BEQ @loop

DEMO2:
		JSR SSSPRINTS
		.byte $F4,"WRITING TO THE",13
		.byte "PLAYFIELD:",13,13
		.byte $F6,"LDY #",$F5,"4",13
		.byte $F6,"LDX #",$F5,"18",13
		.byte $F6,"JSR ",$F2,"SSSPLOT",13
		.byte $F6,"JSR ",$F2,"SSSPRINTS",13
		.byte $F0,".ASCIIZ ",$F5,"'ABC'",13,13
		.byte $F6,"LDA #",$F5,"6",13
		.byte $F6,"STA ",$F4,"COLORCODE",13
		.byte $F6,"LDY #",$F5,"6",13
		.byte $F6,"LDX #",$F5,"19",13
		.byte $F6,"JSR ",$F2,"SSSPLOT",13
		.byte $F6,"LDA #",$F5,"$84",13
		.byte $F6,"JSR ",$F2,"SSSPOKE",13,13
		.byte $F6,"LDY #",$F5,"0",13
		.byte $F6,"JSR ",$F2,"SSSFLIP",13
		.byte 0
		LDY #4
		LDX #18
		JSR SSSPLOT
		JSR SSSPRINTS
		.asciiz "ABC"
		LDY #6
		LDX #19
		JSR SSSPLOT
		LDA #6
		STA COLORCODE
		LDA #$84
		JSR SSSPOKE
@loop:	JSR ANYKEY
		BEQ @loop

DEMO3:
		JSR SSSPRINTS
		.byte $F4,"MAKING A SIMPLE",13
		.byte "SPRITE (",$F2,"RED HEART",$F4,"):",13,13
		.byte $F6,"LDA #",$F5,"%10001100",13
		.byte $F6,"LDY #",$F5,"8",13
		.byte $F6,"JSR ",$F2,"SSSCREATE",13,13
		.byte $F6,"LDA #",$F5,"2",13
		.byte $F6,"LDX #",$F5,"$98",13
		.byte $F6,"LDY #",$F5,"$82",13
		.byte $F6,"JSR ",$F2,"SSSANIM",13,13
		.byte $F6,"LDX #",$F5,"160",13
		.byte $F6,"LDY #",$F5,"96",13
		.byte $F6,"JSR ",$F2,"SSSMOVEXY",13,13
		.byte $F6,"LDY #",$F5,"0",13
		.byte $F6,"JSR ",$F2,"SSSFLIP"
		.byte 0
		JSR HEART
@loop:	JSR ANYKEY
		BEQ @loop

DEMO4:
		JSR SSSPRINTS
		.byte $F4,"MOVING A SIMPLE",13
		.byte "SPRITE:",13,13
		.byte $F0,"@LOOP:",13
		.byte $F6,"LDX #",$F5,"0",13
		.byte $F6,"JSR ",$F2,"SSSUSE",13,13
		.byte $F6,"LDX ",$F4,"SPRITEX",13
		.byte $F6,"INC ",$F4,"SPRITEY",13
		.byte $F6,"LDY ",$F4,"SPRITEY",13
		.byte $F6,"JSR ",$F2,"SSSMOVEXY",13,13
		.byte $F6,"LDY #",$F5,"1",13
		.byte $F6,"JSR ",$F2,"SSSFLIP",13
		.byte $F6,"JMP ",$F0,"@LOOP",13
		.byte 0
		JSR HEART
@loop:	LDX #0
		JSR SSSUSE
		LDX SPRITEX
		INC SPRITEY
		LDY SPRITEY
		JSR SSSMOVEXY
		JSR ANYKEY
		BEQ @loop

DEMO5:
		JSR SSSPRINTS
		.byte $F4,"STATIC CELLS ON",13
		.byte "THE PLAYFIELD:",13,13
		.byte $F6,"LDY #",$F5,"10",13
		.byte $F6,"LDX #",$F5,"18",13
		.byte $F6,"JSR ",$F2,"SSSPLOT",13
		.byte $F6,"LDA #",$F5,"6",13
		.byte $F6,"STA ",$F4,"COLORCODE",13
		.byte $F6,"LDA #",$F5,"128+81",13
		.byte $F6,"JSR ",$F2,"SSSCELL",13
		.byte $F6,"LDY #",$F5,"0",13
		.byte $F6,"JSR ",$F2,"SSSFLIP",13
		.byte $F6,"LDY #",$F5,"10",13
		.byte $F6,"LDX #",$F5,"18",13
		.byte $F6,"JSR ",$F2,"SSSPLOT",13
		.byte $F6,"LDA #",$F5,"3",13
		.byte $F6,"STA ",$F4,"COLORCODE",13
		.byte $F6,"LDA #",$F5,"128+87",13
		.byte $F6,"JSR ",$F2,"SSSCELL",13
		.byte $F6,"LDY #",$F5,"0",13
		.byte $F6,"JSR ",$F2,"SSSFLIP",13
		.byte 0
		;
		JSR HEART
		JSR BALL
		;
@loop:	LDX #0
		JSR SSSUSE
		LDX SPRITEX
		INC SPRITEY
		LDY SPRITEY
		JSR SSSMOVEXY
		JSR ANYKEY
		BEQ @loop

DEMO6:
		JSR SSSPRINTS
		.byte $F4,"COLLISION",13
		.byte "DETECTION:",13,13
		.byte $F6,"LDA ",$F4,"SPRITEDEF",13
		.byte $F6,"ORA #",$F5,"$40",13
		.byte $F6,"STA ",$F4,"SPRITEDEF",13
		.byte $F7,"... MOVE SPRITE",13
		.byte $F6,"LDY #",$F5,"0",13
		.byte $F6,"JSR ",$F2,"SSSFLIP",13,13
		.byte $F6,"LDY #",$F5,"27",13
		.byte $F6,"LDA ",$F4,"SPRITEZ",13
		.byte $F6,"AND #",$F5,"$08",13
		.byte $F6,"BEQ ",$F0,"@CONT",13
		.byte $F6,"DEY",13
		.byte $F0,"@CONT:",13
		.byte $F6,"STY ",$F5,"$900F",13,13,13
		.byte $F4,"SPRITEBACK",$F6," = "
		.byte 0
		LDX CRSRCOL
		STX R3
		LDY CRSRROW
		STY R4
		;
		LDY #4
		LDX #18
		JSR SSSPLOT
		JSR SSSPRINTS
		.asciiz "ABC"
		JSR HEART
		JSR BALL
		LDA SPRITEDEF
		ORA #$40
		STA SPRITEDEF
		;
@loop:	LDX #0
		JSR SSSUSE
		LDX SPRITEX
		INC SPRITEY
		LDY SPRITEY
		JSR SSSMOVEXY
		JSR ANYKEY
		BNE DEMO7
		LDY #27
		LDA SPRITEZ
		AND #$08
		BEQ @cont
		DEY
@cont:	STY $900F
		LDX R3
		LDY R4
		JSR SSSPLOT
		LDA #0
		STA COLORCODE
		LDA SPRITEBACK
		JSR SSSPRINT
		JMP @loop

DEMO7:
		LDA #30
		STA $900F
		JSR SSSPRINTS
		.byte $F4,"'GHOST MODE':",13,13
		.byte $F6,"LDA ",$F4,"SPRITEDEF",13
		.byte $F6,"ORA #",$F5,"$20",13
		.byte $F6,"STA ",$F4,"SPRITEDEF",13
		.byte 0
		LDX #7
		LDA #$FF
@fill:	STA $1C08,X
		DEX
		BPL @fill
		;
		LDA #%11101111	; 16x16 sprite floats X-Y
		LDY #$10		; height
		JSR SSSCREATE
		LDA #$02		; red
		LDX #<BIGRED
		LDY #>BIGRED
		JSR SSSANIM
		LDX #0
		LDA SSSCLIPY
		LSR
		TAY
		JSR SSSMOVEXY
		;
		LDY #9
		LDX #2
		STY R3
		STX R4
@bar1:
		LDX R4
		JSR SSSPLOT
		JSR SSSPRINTS
		.byte $F5,1,1,1,SSSNULL,SSSNULL,SSSNULL
		.byte $F6,1,1,1,SSSNULL,SSSNULL,SSSNULL
		.byte $F7,1,1,1,SSSNULL,SSSNULL,SSSNULL
		.byte 0
		INC R3
		LDY R3
		CPY #14
		BNE @bar1

@loop:	LDX #0
		JSR SSSUSE
		INC SPRITEX
		LDX SPRITEX
		LDY SPRITEY
		JSR SSSMOVEXY
		JSR ANYKEY
		BEQ @loop

FINI:	JMP RESET		; bye-bye!

ANYKEY:
		LDY PLAYROWS
		DEY
		LDX #0
		JSR SSSPLOT
		JSR SSSPRINTS
		.byte $F6,"-=: PRESS ANY KEY :=-"
		.byte 0
		;
@user:	LDY #1
		JSR SSSFLIP
		LDA $C5
		CMP #$40
		BEQ @repeat		; keypress?
@wait:	LDA $C5
		CMP #$40
		BNE @wait		; release key
		JSR SSSINIT		; start over
		LDA #1
@repeat:
		RTS

BALL:
		LDY #10
		LDX #18
		JSR SSSPLOT
		LDA #4
		STA COLORCODE
		LDA #128+81
		JSR SSSCELL
		LDY #0
		JSR SSSFLIP
		;
		LDY #10
		LDX #18
		JSR SSSPLOT
		LDA #7
		STA COLORCODE
		LDA #128+87
		JSR SSSCELL
		;
		RTS

HEART:
		LDA #%10001100	; enable 8X8 float
		LDY #8
		JSR SSSCREATE
		; RED HEART
		LDA #2
		LDX #$98
		LDY #$82
		JSR SSSANIM
		LDX #160
		LDY #96
		JSR SSSMOVEXY
		LDY #0
		JSR SSSFLIP
		RTS

HEROMOVE:
		LDX #0
		STX sssNUM
		LDA #5
		LDX #<HERO
		LDY #>HERO
		JSR SSSANIM
		LDA SPRITEX
		LSR
		AND #$03
		BEQ @ck0
		CMP #$02
		BEQ @r2
@r1:
		LDX #<(HERO+16)
		LDY #>(HERO+16)
		STX SPRITEIMGL
		STY SPRITEIMGH
		BNE @ck0
@r2:
		LDX #<(HERO+32)
		LDY #>(HERO+32)
		STX SPRITEIMGL
		STY SPRITEIMGH
@ck0:					; process RIGHT
		LDA R0
		CMP #-1
		BEQ @ck2
		LDA SPRITEX
		SEC
		SBC #8
		CMP SSSCLIPX
		BEQ @ck1
		INC SPRITEX
		BNE @fini
@ck1:	LDA #-1
		STA R0
@ck2:					; process LEFT
		LDA R0
		AND #%00000100
		BEQ @ck3
		LDA SPRITEIMGL
		CLC
		ADC #$30
		BCC @lcc
		INC SPRITEIMGH
@lcc:	STA SPRITEIMGL
		LDA SPRITEX
		BEQ @ck3
		DEC SPRITEX
@fini:	RTS
@ck3:	LDA #0
		STA R0
		RTS

QMANMOVE:
		LDA R1
		CMP #-1
		BEQ @big
		LDX #1
		STX sssNUM
		LDX #<QBALL
		LDY #>QBALL
		DEC SPRITEX+1
		BEQ @fini1
		LDA SPRITEX+1
		AND #$02
		BEQ @ck1
		LDX #<QBALL2
		LDY #>QBALL2
@ck1:	LDA #7
		JSR SSSANIM
		RTS
@fini1:	LDA #-1
		STA R1
		LDA SSSCLIPX
		CLC
		ADC #8
		STA SPRITEX+1
		RTS
@big:
		LDX #2
		STX sssNUM
		LDY #>QUIKMAN
		INC SPRITEX+2
		LDA SPRITEX+2
		CMP SSSCLIPX
		BEQ @fini2
		AND #$03
		ASL
		ASL
		ASL
		ASL
		ASL
		ADC #<QUIKMAN
		BCC @cc
		INY
@cc:	TAX
		LDA #7
		JSR SSSANIM
		RTS
@fini2:	LDA #0
		STA R1
		STA SPRITEX+2
		RTS

		.segment "RODATA"
BIGRED:
		.byte	%00001111
		.byte	%00111111
		.byte	%01111111
		.byte	%11111111
		.byte	%11100111
		.byte	%11000011
		.byte	%11100111
		.byte	%11111111

		.byte	%11111111
		.byte	%11111111
		.byte	%11110011
		.byte	%11001100
		.byte	%11111111
		.byte	%11111111
		.byte	%11001100
		.byte	%10001000

		.byte	%11110000
		.byte	%11111100
		.byte	%11111110
		.byte	%11111111
		.byte	%11100111
		.byte	%11000011
		.byte	%11100111
		.byte	%11111111

		.byte	%11111111
		.byte	%11111111
		.byte	%11001111
		.byte	%00110011
		.byte	%11111111
		.byte	%11111111
		.byte	%00110011
		.byte	%00010001

HERO:
		; moving right frame #0 (& standing)
		.byte	%00011000
		.byte	%00011000
		.byte	%00000000
		.byte	%00111100
		.byte	%01011010
		.byte	%01011010
		.byte	%01011010
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011100
		.byte	%00010000
		; moving right frame #1 / #3
		.byte	%00000000
		.byte	%00011000
		.byte	%00011000
		.byte	%00000000
		.byte	%00111100
		.byte	%01011100
		.byte	%01011100
		.byte	%00111110
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00010100
		.byte	%11110010
		.byte	%10000010
		.byte	%00000010
		.byte	%00000011
		; moving right frame #2
		.byte	%00011000
		.byte	%00011000
		.byte	%00000000
		.byte	%00111100
		.byte	%01011010
		.byte	%10011001
		.byte	%01011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00100100
		.byte	%00100010
		.byte	%01000001
		.byte	%01000001
		.byte	%10000001
		.byte	%10000001
		.byte	%00000000
OREH:	.global OREH
		; moving left frame #0
		.byte	%00011000
		.byte	%00011000
		.byte	%00000000
		.byte	%00111100
		.byte	%01011010
		.byte	%01011010
		.byte	%01011010
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00111000
		.byte	%00001000
		; moving left frame #1 / #3
		.byte	%00000000
		.byte	%00011000
		.byte	%00011000
		.byte	%00000000
		.byte	%00111100
		.byte	%00111010
		.byte	%00111010
		.byte	%01111100
		.byte	%00011000
		.byte	%00011000
		.byte	%00011000
		.byte	%00101000
		.byte	%01001111
		.byte	%01000001
		.byte	%01000000
		.byte	%11000000
		; moving left frame #2
		.byte	%00011000
		.byte	%00011000
		.byte	%00000000
		.byte	%00111100
		.byte	%01011010
		.byte	%10011001
		.byte	%00011010
		.byte	%00011000
		.byte	%00011000
		.byte	%00100100
		.byte	%01000100
		.byte	%10000010
		.byte	%10000010
		.byte	%10000001
		.byte	%10000001
		.byte	%00000000

QBALL:	.byte	$3C, $7E, $FF, $FF, $FF, $FF, $7E, $3C
QBALL2:	.byte	$7C, $3E, $1F, $0F, $0F, $1F, $3E, $7C

QUIKMAN:
		.byte	%00000111
		.byte	%00011111
		.byte	%00111111
		.byte	%01111111
		.byte	%01111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111110
		;
		.byte	%11111110
		.byte	%11111111
		.byte	%11111111
		.byte	%01111111
		.byte	%01111111
		.byte	%00111111
		.byte	%00011111
		.byte	%00000111
		;
		.byte	%11100000
		.byte	%11111000
		.byte	%11110000
		.byte	%11100000
		.byte	%11000000
		.byte	%10000000
		.byte	%00000000
		.byte	%00000000
		;
		.byte	%00000000
		.byte	%00000000
		.byte	%10000000
		.byte	%11000000
		.byte	%11100000
		.byte	%11110000
		.byte	%11111000
		.byte	%11100000
		; QUICKMAN2
		.byte	%00000111
		.byte	%00011111
		.byte	%00111111
		.byte	%01111111
		.byte	%01111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		;
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%01111111
		.byte	%01111111
		.byte	%00111111
		.byte	%00011111
		.byte	%00000111
		;
		.byte	%11100000
		.byte	%11111000
		.byte	%11111100
		.byte	%11111110
		.byte	%11111100
		.byte	%11110000
		.byte	%11000000
		.byte	%00000000
		;
		.byte	%00000000
		.byte	%11000000
		.byte	%11110000
		.byte	%11111100
		.byte	%11111110
		.byte	%11111100
		.byte	%11111000
		.byte	%11100000
		; QUICKMAN3
		.byte	%00000111
		.byte	%00011111
		.byte	%00111111
		.byte	%01111111
		.byte	%01111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		;
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%01111111
		.byte	%01111111
		.byte	%00111111
		.byte	%00011111
		.byte	%00000111
		;
		.byte	%11100000
		.byte	%11111000
		.byte	%11111100
		.byte	%11111110
		.byte	%11111110
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		;
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111110
		.byte	%11111110
		.byte	%11111100
		.byte	%11111000
		.byte	%11100000
		; QUICKMAN4
		.byte	%00000111
		.byte	%00011111
		.byte	%00111111
		.byte	%01111111
		.byte	%01111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		;
		.byte	%11111111
		.byte	%11111111
		.byte	%11111111
		.byte	%01111111
		.byte	%01111111
		.byte	%00111111
		.byte	%00011111
		.byte	%00000111
		;
		.byte	%11100000
		.byte	%11111000
		.byte	%11111100
		.byte	%11111110
		.byte	%11111100
		.byte	%11110000
		.byte	%11000000
		.byte	%00000000
		;
		.byte	%00000000
		.byte	%11000000
		.byte	%11110000
		.byte	%11111100
		.byte	%11111110
		.byte	%11111100
		.byte	%11111000
		.byte	%11100000

