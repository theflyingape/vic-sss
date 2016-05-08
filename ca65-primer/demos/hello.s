;*********************************************************************
; Simple HELLO demo
; using the VIC Software Sprite Stack
; last updated: 5-May-2009
;
		.include "VIC-SSS-MMX.h"
		.segment "CODE"

		JSR SSSINIT

		SEI
		LDX #<SSSIRQ
		LDY #>SSSIRQ
		STX $0314
		STY $0315
		CLI

		LDA #$02
		STA COLORCODE
		LDA #$B1
		LDX #$00
		LDY #$00
		JSR SSSCELL
		LDY #$00
		JSR SSSFLIP

		LDA #$06
		STA COLORCODE
		LDA #$B2
		LDX #$01
		LDY #$00
		JSR SSSCELL
		LDY #$00
		JSR SSSFLIP

		LDX #$07
		LDY #$01
		JSR SSSPLOT
		LDA #$98
		JSR SSSPOKE

		LDX #$08
		LDY #$02
		JSR SSSPLOT
		LDA #$99
		JSR SSSPOKE

		LDX #$09
		LDY #$03
		JSR SSSPLOT
		LDA #$9A
		JSR SSSPOKE

@init:
		LDA #%10001100	; 8x8 floating sprite
		LDY #$08		; all 8 pixels high
		JSR SSSCREATE
		LDA #$02		; red
		LDX #$40		; points to
		LDY #$80		; ROM "H" character
		JSR SSSANIM

		LDA #%10001100	; 8x8 floating sprite
		LDY #$08		; all 8 pixels high
		JSR SSSCREATE
		LDA #$05		; green
		LDX #$28		; points to
		LDY #$80		; ROM "E" character
		JSR SSSANIM

		LDA #%10001100	; 8x8 floating sprite
		LDY #$08		; all 8 pixels high
		JSR SSSCREATE
		LDA #$06		; blue
		LDX #$60		; points to
		LDY #$80		; ROM "L" character
		JSR SSSANIM

		LDA #%10001100	; 8x8 floating sprite
		LDY #$08		; all 8 pixels high
		JSR SSSCREATE
		LDA #$06		; blue
		LDX #$60		; points to
		LDY #$80		; ROM "L" character
		JSR SSSANIM

		LDA #%10001100	; 8x8 floating sprite
		LDY #$08		; all 8 pixels high
		JSR SSSCREATE
		LDA #$04		; magenta
		LDX #$78		; points to
		LDY #$80		; ROM "O" character
		JSR SSSANIM

		LDY #$01
		JSR SSSFLIP
@pos:
		LDX #$30
		LDY #$20
		STX R0
		STY R1

		LDX #$00
		JSR SSSUSE
		LDX R0
		LDY R1
		JSR SSSMOVEXY

		LDX #$01
		JSR SSSUSE
		LDA R0
		CLC
		ADC #$10
		TAX
		LDY R1
		JSR SSSMOVEXY

		LDX #$02
		JSR SSSUSE
		LDA R0
		CLC
		ADC #$20
		TAX
		LDY R1
		JSR SSSMOVEXY

		LDX #$03
		JSR SSSUSE
		LDA R0
		CLC
		ADC #$30
		TAX
		LDY R1
		JSR SSSMOVEXY

		LDX #$04
		JSR SSSUSE
		LDA R0
		CLC
		ADC #$40
		TAX
		LDY R1
		JSR SSSMOVEXY

		LDY #$01
		JSR SSSFLIP
		LDY #$03
		STY R1

@loop:
		LDX #$00
		STX R0
		;
@dy:	JSR SSSUSE
		LDA SPRITEY,X
		BNE @ff
		DEC R1
		LDY R1
		CPY #$04
		BCC @ff
		LDY #$03
		STY R1		
@ff:	TAY
		INY
		LDA SPRITEX,X
		TAX
		;INX
		JSR SSSMOVEXY
		INC R0
		LDX R0
		CPX #$05
		BNE @dy

		;LDY R1
		;JSR SSSFFLIP
		LDY #$00
		JSR SSSFLIP
		JSR GETIN
		CMP #$85		; got F1?
		BEQ @fini
		JMP @loop
@fini:
		JMP RESET
