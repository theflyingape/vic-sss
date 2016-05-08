;*********************************************************************
; YOUR PROJECT INFORMATION GOES HERE
; and then save file as: yourgame.s
;
		.fileopt author,	"your name"
        .fileopt comment,	"your comments"
        .fileopt compiler,	"VIC 20 ASSEMBLER"

;*********************************************************************
; VIC 20 ROM autostart game cartridge
; written by Robert Hurst <robert@hurst-ri.us>
; updated version: 19-Apr-2010
;
; ca65.exe --cpu 6502 --listing --include-dir . yourgame.s
;
; - for 8K GAME CARTRIDGE ROM games:
; ld65.exe -C GAME.cfg -o yourgame.a0 yourgame.o VIC-SSS-MMX.o
;
		.include "VIC-SSS-MMX.h"

;*********************************************************************
; Commodore ROM cartridge boot sequence
; load address of startup & restore key:
;
		.segment "BOOT"

		.word	MAIN
		.word	NMI
		; power-up signature
A0CBM:	.byte	$41, $30, $C3, $C2, $CD

;*********************************************************************
; Starting entry point for this program
;
		.segment "STARTUP"

MAIN:
		; initialize VIC Kernal
		JSR $FD8D		; ramtas	Initialise System Constants (memory pointers)
		JSR $FD52		; restor	Restore Kernal vectors (at 0314)
		JSR $FDF9		; ioinit	Initialise I/O (timers are enabled)
		JSR $E518		; cint1		Initialize I/O (VIC reset, must follow ramtas)
		LDA SCRNPAGE
		STA ACTUAL
	;	LDA #$7F
	;	STA $911E		; disable NMIs (Restore key)
  		;
		; initialize VIC BASIC
		JSR $E45B		; initv		Initialize vectors
		JSR $E3A4		; initcz	Initialize BASIC RAM
		JSR $E404		; initms	Output power-up message
		;
		LDA MACHINE
		CMP #$05
		BEQ NTSC
		CMP #$0C
		BEQ PAL
		JMP READY		; not a VIC?
		;
		; NTSC setup
NTSC:	LDX #<@NTSC		; load the timer low-byte latches
		STX $9126
		LDX #>@NTSC
		LDA #$75		; raster line 234/235
		BNE IRQSYNC
@NTSC = $4243			; (261 * 65 - 2)
		;
		; PAL setup
PAL:	LDX #<@PAL		; load the timer low-byte latches
		STX $9126
		LDX #>@PAL
		LDA #$82		; raster line 260/261
		BNE IRQSYNC
@PAL = $5686			; (312 * 71 - 2)
		;
IRQSYNC:
		CMP VIC+$04
		BNE IRQSYNC
		STX $9125		; load T1 latch high, and transfer both bytes to T1 counter
		JMP RESTART

;*********************************************************************
; enter VIC BASIC mode
;
READY:
		LDA ACTUAL
		STA SCRNPAGE	; restore video page back to VIC startup value
		JSR $E518		; cint1		Initialize I/O (VIC reset, must follow ramtas)
		JSR $E45B		; initv		Initialize vectors
		JSR $E3A4		; initcz	Initialize BASIC RAM
		LDA #$01		; just to have some fun:
		STA RVSFLAG		; - character reverse flag
		LDA #$03		; - set color to CYAN
		STA COLORCODE
		JSR $E404		; initms	Output power-up message
		LDA #$06		; set color back to BLUE
		STA COLORCODE	; because we're used to it
		JMP $E467		; bassft	BASIC Warm Start

;*********************************************************************
; RESTORE key was pressed
NMI:
	;	JMP $FEC7		; continue
		CLD
		PLA				; restore Y register
		TAY
		PLA				; restore X register
		TAX
		PLA				; restore Accumulator
	;	RTI				; continue
		PLA
		PLA
		LDA #$FF		; acknowledge and clear
		STA $9122		; interrupts
		LDY $9111
		JMP RESTART


;*********************************************************************
; Your main program code starts here
;
		.segment "CODE"

RESTART:
		.global RESTART
		LDA #$00
		TAX
		LDY #$18
		STX $FD
		STY $FE
		TAY
@loop:	STA ($FD),Y
		INY
		BNE @loop
		INC $FE
		LDX $FE
		CPX #$1C
		BNE @loop

