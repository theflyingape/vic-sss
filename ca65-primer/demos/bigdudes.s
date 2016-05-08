;*********************************************************************
; DEMO featuring VIC Software Sprite Stack
; written by Robert Hurst <robert@hurst-ri.us>
; updated version: 5-May-2009
;*********************************************************************
;
; See each .bat file for compile, link, and go instructions.
;
		.include "VIC-SSS-MMX.h"
		.segment "CODE"

CTRLKEYS = $028D
;
		JSR SSSINIT		; must occur BEFORE re-directing IRQ
;
; implement my interrupt vector
		SEI
		LDX #<SSSIRQ
		LDY #>SSSIRQ
		STX $0314
		STY $0315
		CLI
		;
		LDA #$1B
		STA VIC+$0F
		LDA #$06
		STA COLORCODE
		JSR ALERT
		LDY #$01
		JSR SSSFLIP
		;
		LDA #%10001111	; 16x16 sprite floats X-Y
		LDY #$10		; height
		JSR SSSCREATE
		LDA #$02		; red
		LDX #<BIGRED
		LDY #>BIGRED
		JSR SSSANIM
		;
		LDA #%10001111	; 16x16 sprite floats X-Y
		LDY #$10		; height
		JSR SSSCREATE
		LDA #$05		; green
		LDX #<BIGDUDE
		LDY #>BIGDUDE
		JSR SSSANIM
		;
		LDX #$00
		JSR SSSUSE
		LDA PLAYCOLS
		ASL
		TAX
		LDA PLAYROWS
		ASL
		TAY
		JSR SSSMOVEXY
		;
		LDX #$01
		JSR SSSUSE
		LDX #$10
		LDY #$10
		JSR SSSMOVEXY
		;
		LDA #$00
		STA R0
		STA R1
		;
@loop:
		LDX #$00
		JSR SSSUSE
		LDA SPRITEY,X
		TAY
		LDA SPRITEX,X
		AND #$07
		BNE @redx
		INY
@redx:	LDA SPRITEX,X
		TAX
		INX
		JSR SSSMOVEXY
		;
@green:
		LDX #$01
		JSR SSSUSE
		LDA SPRITEX,X
		STA XCOPY
		LDA SPRITEY,X
		STA YCOPY
		LDA R0
		BNE @s2
		LDA SPRITEX,X
		CLC
		ADC #$10
		CMP SSSCLIPX
		BCS @x2
		INC XCOPY
		BNE @gogreen
@x2:	LDA SPRITEY,X
		CLC
		ADC #$18
		CMP SSSCLIPY
		BCS @y2
		INC YCOPY
		BNE @gogreen
@y2:	INC R0
@s2:	LDA SPRITEX,X
		CMP #$11
		BCC @x0
		DEC XCOPY
		BNE @gogreen
@x0:	LDA SPRITEY,X
		CMP #$11
		BCC @y0
		DEC YCOPY
		BNE @gogreen
@y0:	DEC R0
		BEQ @green
@gogreen:
		LDX XCOPY
		LDY YCOPY
		JSR SSSMOVEXY
		;
@flip:	LDY #$02		; keeps a fair consistent pace, without tearing
		JSR SSSFFLIP
		;
@user:	LDA CTRLKEYS
		AND #$02		; holding C= key down, bypass cartridge
		BNE END
		JMP @loop

;*********************************************************************
; That's all folks
;
END:
		JMP RESET

ALERT:
		LDY PLAYROWS
		DEY
		TYA
		LDX #<PAUSE
		LDY #>PAUSE
		JSR STATUS
		LDX #$00
		LDY PLAYROWS
		DEY
		DEY
		JSR SSSPLOT
@line:	LDA #$D2
		JSR SSSPRINT	; render a line
		LDY CRSRCOL		; above the message
		BNE @line
		LDY #$01
		JSR SSSFLIP
		RTS

NOSTATUS:
		LDY PLAYROWS
		DEY
		LDX #<ERASE
		LDY #>ERASE
STATUS:
		STX VECTORBG
		STY VECTORBG+1
		LDX #$00
		TAY
		JSR SSSPLOT
		;
		LDY #$00
@loop:	LDA (VECTORBG),Y
		BNE @print
		INC CRSRCOL
		BNE @next
@print:	JSR SSSPRINT
@next:	LDY CRSRCOL
		BNE @loop
		RTS

;*********************************************************************
		.segment "RODATA"
;
ERASE:	.byte	$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
;				 PRESS C= KEY TO CONT
PAUSE:	.byte	$00,$90,$92,$85,$93,$93,$A0,$83,$BD,$A0,$8B,$85,$99,$A0,$94,$8F,$A0,$83,$8F,$8E,$94,$00

;*********************************************************************
; SPRITE DATA
;
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
BIGDUDE:
		.byte	%00001111
		.byte	%00111111
		.byte	%11111111
		.byte	%11111111
		.byte	%11000011
		.byte	%11000011
		.byte	%11000011
		.byte	%11111111

		.byte	%11111111
		.byte	%11111111
		.byte	%11001111
		.byte	%11110000
		.byte	%11111111
		.byte	%11111111
		.byte	%11001100
		.byte	%10001000

		.byte	%11110000
		.byte	%11111100
		.byte	%11111111
		.byte	%11111111
		.byte	%11000011
		.byte	%11000011
		.byte	%11000011
		.byte	%11111111

		.byte	%11111111
		.byte	%11111111
		.byte	%11110011
		.byte	%00001111
		.byte	%11111111
		.byte	%11111111
		.byte	%00110011
		.byte	%00010001
