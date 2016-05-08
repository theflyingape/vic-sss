		.include "VIC-SSS-MMX.h"

		LDA #6			; fill with blue character color
		STA COLORCODE
		JSR SSSINIT		; initialize software sprite stack
		;
		SEI
		LDX #<SSSIRQ	; allows for tear-free flipping
		LDY #>SSSIRQ
		STX $0314
		STY $0315
		CLI
		;
		LDY #$0A		; row 11
		LDX #$08		; col 9
		JSR SSSPLOT		; cursor moves here
		JSR SSSPRINTS
		.byte $F2		; red text
		.asciiz "HELLO!"
		LDY #$00		; immediate
		JSR SSSFLIP
		;
@init:	LDA #%10001100	; 8x8 sprite floats X-Y
		LDY #8
		JSR SSSCREATE
		LDA #4			; magenta
		LDX #<$8000
		LDY #>$8000
		JSR SSSANIM
		LDA #%10001100	; 8x8 sprite floats X-Y
		LDY #8
		JSR SSSCREATE
		LDA #0			; black
		LDX #<$8000
		LDY #>$8000
		JSR SSSANIM
		;
@loop:	LDY #1			; wait for vertical sync
		JSR SSSFLIP
		LDX #$00
		JSR SSSUSE
		LDA SPRITEY,X
		TAY
		INY
		LDA SPRITEX,X
		TAX
		INX
		JSR SSSMOVEXY
		LDA SPRITEX,X
		BNE @kb
		LDA SPRITEIMGL,X
		CLC
		ADC #$08
		STA SPRITEIMGL,X
@kb:
	lda SPRITEY
	sta SPRITEY+1
	lda SPRITEX
	clc
	adc #$10
	sta SPRITEX+1
	ldx #1
	jsr SSSTOUCH
		JSR STOPKEY
		BNE @loop
@fini:	JMP RESET		; bye-bye!
