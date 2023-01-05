; *********************************************************************************************************************
; * Z80 Project by Frédéric Segard, a.k.a. MicroHobbyist
; * http://youtube.com/@microhobbyist
; *
; * Copyright (C) 2023 Frédéric Segard
; * This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General
; * Public License as published by the Free Software Foundation. You can use all or part of the code, regardless of
; * the version. But there is no warrenty of any kind. 
; *
; * BIOS v0.1
; *********************************************************************************************************************

; ---------------------------------------------------------------------------------------------------------------------
; CONSTANTS
; ---------------------------------------------------------------------------------------------------------------------

; I/O ADDRESSES
ClockSelect		= $28			; Clock speed selection address (values $00 to $03)
BankSelect		= $30			; RAM bank select address (values ($00 to $0E)
RomDisable		= $38			; ROM dissable address (any value)

; ---------------------------------------------------------------------------------------------------------------------
; VECTORS
; ---------------------------------------------------------------------------------------------------------------------

	.org	$0000
RESET:							; Reset vector 0 (8-bytes long)
	di							; Disable interrupts as to not disrupt the transfer of data	
	jp		ResetInit			; Jump to code that is in the high bank memory
	ds		RST1-$,$00			; Fill unused bytes with $00

	.org	$0008
RST1:							; Reset Vector 1 (8-bytes long)
	di							; Disable interrupts
	jp		ResetVector1		; Jump to code that is in the high bank memory
	ds		RST2-$,$00			; Fill unused bytes with $00

	.org	$0010
RST2:							; Reset Vector 2 (8-bytes long)
	di							; Disable interrupts
	jp		ResetVector2		; Jump to code that is in the high bank memory
	ds		RST3-$,$00			; Fill unused bytes with $00

	.org	$0018
RST3:							; Reset Vector 3 (8-bytes long)
	di							; Disable interrupts
	jp		ResetVector3		; Jump to code that is in the high bank memory
	ds		RST4-$,$00			; Fill unused bytes with $00

	.org	$0020
RST4:							; Reset Vector 4 (8-bytes long)
	di							; Disable interrupts
	jp		ResetVector4		; Jump to code that is in the high bank memory
	ds		RST5-$,$00			; Fill unused bytes with $00

	.org	$0028
RST5:							; Reset Vector 5 (8-bytes long)
	di							; Disable interrupts
	jp		ResetVector5		; Jump to code that is in the high bank memory
	ds		RST6-$,$00			; Fill unused bytes with $00

	.org	$0030
RST6:							; Reset Vector 6 (8-bytes long)
	di							; Disable interrupts
	jp		ResetVector6		; Jump to code that is in the high bank memory
	ds		RST7INT-$,$00		; Fill unused bytes with $00

	.org	$0038
RST7:							; Reset vector 7 - Interrupt Mode 1 (8-bytes long)
	di							; Disable interrupts
	jp		ResetVector7		; Jump to code that is in the high bank memory
	ds		EndOfVectors-$,$00	; Fill unused bytes with $00

	.org	$0040
EndOfVectors:					; Non-maskable Interrupt vector (not used in CP/M, so it won't be processed)
	ds		$8000-$,$FF			; Fill unused bytes with $FF to optimize write speeds with the programmer


	.org	$8000				; Start of code at beginning of high memory

ResetInit:						; *** COPY PAGE 1 ON ALL BASIC INITIALIZATION AFTER RESET
	ld		A,$0E				; Starting bank number
VectorsToBanks:					; Loop to copy reset vectors to all banks
	out		(BankSelect),A		; Sets bank number to value in accumulator
	ld      HL,$0000			; Set start at address $0000 (ROM)
	ld      DE,$0000			; Set destination address (RAM)
	ld      bc,$003F			; Set counter to 64-bytes
	ldir						; Copy, paste, and repeat, until the end of BC has been reached
	dec		A					; Decrement accumulator to move on to next bank
	cp		$FF					; Has accumulator reached the end of the loop?
	jr		NZ,VectorsToBanks	; If not then do next bank, else Bank 0 is selected and proceed

ShadowCopy:						; *** COPY THE HIGH MEMORY ROM TO RAM
    ld      HL,$8000			; Source address
    ld      DE,$8000			; Destination address
    ld      BC,$7FFF			; Counter set to end of ROM (High portion)
    ldir						; Copy, paste, and repeat, until the end of ROM code has been reached
	out		(RomDisable),A		; Disable ROM once everything has been copied to RAM (RAM IS NOW ACTIVE, ROM IS NOT)

StackInit:						; *** SET STACK POINTER AND FILL THE STACK WITH $81
	ld      SP,$0000			; Set stack pointer ($0000, which pushes downward to $FFFF when used)
;    ld      HL,$FF00			; Set source to page $FF
;    ld      (HL),$81			; Write $81, a recognizable pattern, to the stack
;    ld      DE,$FF01			; Destination address
;    ld      BC,$FF				; Do this 256 times
;    ldir						; Copy $81 in all of page $FF

FillAllBanks:					; *** FILL MEMORY OF LOWER RAM BANKS TO REFLECT RAM BANK NUMBER
	ld		A,$0E				; Starting bank number and fill byte is $0E
FillAllBanksLoop:				; Loop entry point
	out		(BankSelect),A		; Sets bank number to value in accumulator
	ld      HL,$0100			; Set start at address $0000
	ld      (HL),A				; Write contents of accumulator to address $0000
	ld      DE,$0101			; Set destination address
	ld      bc,$7FFF			; Set counter to 32K
	ldir						; Copy, paste, and repeat, until the end of BC has been reached
	dec		A					; Decrement accumulator to move on to next bank
	cp		$FF					; Has accumulator reached the end of the loop?
	jr		NZ,FillAllBanksLoop	; If not, then continue the loop, else Bank 0 is selected

ResetVector1:
ResetVector2:
ResetVector3:
ResetVector4:
ResetVector5:
ResetVector6:
ResetVector7:

HaltLoop:						; *** HALT
	halt						; Halt the CPU
    jr      HaltLoop			; Make sure the CPU stays halted


; ---------------------------------------------------------------------------------------------------------------------
; SUBROUTINES
; ---------------------------------------------------------------------------------------------------------------------



; End of code (Will be shadow copied, where $FF represents page 15's empty high memory, and $00 is the cleared stack)
; -------------------------------------------------------------------------------------------------------------------
CodeEnd:	ds	$FF00-$,$FF		; Fill remaining area with $FF to optimize speed when programming FLASH/EEPROM
StackEnd:	ds	$FFFF-$+1,$00	; Zero-out the stack at page $FF