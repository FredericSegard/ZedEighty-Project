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
; CODE
; ---------------------------------------------------------------------------------------------------------------------

; ************************************************************
; *** COLD BOOT: CODE WILL NOT BE REUSED AFTER SHADOW COPY ***
; ************************************************************

	.org	$0000				; Coldboot reset vector

ColdBootInit:					
	di							; Disable interrupts, as to not disrupt the transfer of data (just in case)
	ld      SP,$0000			; Set stack pointer

FillBanks:
	ld		A,$0E				; Starting bank number, and fill byte to clear the RAM with
FillBanksLoop:					; Loop entry point
	out		(BankSelect),A		; Sets bank number to value in accumulator
	ld      HL,$0000			; Set start at address $0000
	ld      (HL),A				; Write contents of accumulator to address $0000
	ld      DE,$0001			; Set destination address
	ld      bc,$7FFF			; Set counter to 32K
	ldir						; Copy, paste, and repeat, until the end of BC has been reached
	dec		A					; Decrement accumulator to move on to next bank
	cp		$FF					; Has accumulator reached the end of the loop?
	jr		NZ,FillBanksLoop	; If not, then continue the loop. If finished, bank is at 0

ShadowCopy:						; *** COPY THE ROM TO RAM
    ld      HL,$8000			; Source address
    ld      DE,$8000			; Destination address
    ld      BC,$7FFF			; Counter set to end of ROM (High portion)
    ldir						; Copy, paste, and repeat, until the end of ROM code has been reached

ColdBootEnd:
	jp		BiosStart			; Jump to code that is in the high bank of memory
	ds		$8000-$,$FF			; Fill unused bytes with $FF to optimize write speeds with the programmer
	

; ************************************
; *** START OF BIOS IN HIGH MEMORY ***
; ************************************

	.org	$8000				; Start of BIOS at beginning of high memory

BiosStart:						
	out		(RomDisable),A		; Disable ROM once everything has been copied to RAM (RAM IS NOW ACTIVE, ROM IS NOT)
	
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