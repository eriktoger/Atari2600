	processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include external files containing useful definitions and macros 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	include "vcs.h"
	include "macro.h"

	seg code
	org $F000       ; Define the origin of the ROM at $F000
	
START:
	CLEAN_START     ; Call macro to safely clear the memory
    cld             ; Turn off decmial mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set background luminance color to yellow (NTSC color code $1E)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NEXTFRAME:
    lda #2          ; Second to last bit needs to be on to turn on VBLANK and VSYNC
    sta VBLANK      ; Turn on VBLANK
    sta VSYNC       ; Turn on VSYNC

    ; Genereate the three lines of VSYNC
    sta WSYNC
    sta WSYNC
    sta WSYNC

    lda #0
    sta VSYNC       ; Turn off VSYNC

    ; Generate 37 lines for VBLANK
    ldx #37         ; Set x to 37
LoopVBlank:
    sta WSYNC       ; Hit Wsync and wait for next scan line
    dex             ; X--
    bne LoopVBlank  ; loop while X != 0

    lda #0
    sta VBLANK      ; Turn off VBLANK

    ; Draw 192 visible lines
    ldx #192        ; Counter for the scanlines
LoopVisible:
    stx COLUBK      ; Set the background color
    sta WSYNC       ; wait for the next scanline
    dex             ; X--
    bne LoopVisible ; loop while X != 0

    ; Draw 30 lines for overscan
    lda #2          
    sta VBLANK      ;Turn on VBlank

    ldx #30
LoopOverscan
    sta WSYNC
    dex             ;X--
    bne LoopOverscan    ; Loop while X != 0

    jmp NEXTFRAME; 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC       ; Defines origin to $FFFC
    .word START     ; Reset vector at $FFFC (where program starts)
    .word START     ; Interrupt vector at $FFFE (unused by the VCS)
