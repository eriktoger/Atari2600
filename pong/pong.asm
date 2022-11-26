    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with VCS register memory mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare the variables starting from memory address $80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

P0YPos          byte         ; player 0 y-position
P1YPos          byte         ; player 1 y-position


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code at memory address $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START              ; call macro to reset memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize RAM variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #50
    sta P0YPos              ; P0YPos  = 50
    sta P1YPos              ; P1YPos  = 50

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
    lda #02
    sta VBLANK     ; turn VBLANK on
    sta VSYNC      ; turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the three lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        sta WSYNC  ; three VSYNC scanlines
    REPEND

    lda #0
    sta VSYNC      ; turn VSYNC off


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the 37 recommended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 35
        sta WSYNC
    REPEND



    lda #0
    sta VBLANK     ; turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed during the VBLANK section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #3
    sta WSYNC
Loop1:
    dex
    bne Loop1 
    sta RESP0 
    ldx #13 
    sta WSYNC 
Loop2:
    dex
    bne Loop2
    dex
    dex
    sta RESP1 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192/2 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #96
GameLineLoop:
    sta WSYNC 
    txa 
    cmp P0YPos      ; check if we should display p0 paddle
    bpl noP0Display ; if we are above the Y, we dont display
    clc
    adc #10
    cmp P0YPos      ; if we are 10 steps below we dont display
    bmi noP0Display

    lda #%00011000
    sta GRP0
    lda #$98
    sta COLUP0
    jmp displayP1    
noP0Display:
    lda #%00000000
    sta GRP0
    lda #0
    sta COLUP0

displayP1:
    txa 
    cmp P1YPos           ; check if we should display p1 paddle
    bpl noP1Display      ; if we are above the Y, we dont display
    clc
    adc #10
    cmp P1YPos
    bmi noP1Display     ; if we are 10 steps below we dont display
    lda #%00011000
    sta GRP1
    lda #$34
    sta COLUP1
    jmp endOfLine  
noP1Display:
    lda #%00000000
    sta GRP1
    lda #0
    sta COLUP1
    
endOfLine:
    sta WSYNC           ; wait for a scanline
    dex                 ;
    bne GameLineLoop 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK     ; enable VBLANK back again
    REPEAT 30
       sta WSYNC   ; output the 30 recommended overscan lines
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process joystick input for player 0/1 up/down
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    lda #%00010000           ; joystick up for player 0
    bit SWCHA
    bne CheckP0Down
    lda P0YPos
    cmp #90                  ; if (player0 Y position > 90)
    bpl CheckP0Down          ;    then: skip increment
P0UpPressed:                 ;    else:
    inc P0YPos               ;        increment Y position

CheckP0Down:
    lda #%00100000           ; joystick down for player 0
    bit SWCHA
    bne CheckP1Up
    lda P0YPos
    cmp #15                  ; if (player0 Y position < 15)
    bmi CheckP1Up            ;    then: skip decrement
P0DownPressed:               ;    else:
    dec P0YPos               ;        decrement Y position

CheckP1Up:
    lda #%00000001           ; joystick up for player 1
    bit SWCHA
    bne CheckP1Down
    lda P1YPos
    cmp #90                  ; if (player1 Y position > 90)
    bpl CheckP1Down          ;    then: skip increment
P1UpPressed:                 ;    else:
    inc P1YPos               ;        increment Y position

CheckP1Down:
    lda #%00000010           ; joystick down for player 1
    bit SWCHA
    bne EndInputCheck
    lda P1YPos
    cmp #15                   ; if (player1 Y position < 15)
    bmi EndInputCheck         ;    then: skip decrement
P1DownPressed:                ;    else:
    dec P1YPos                ;        decrement Y position

EndInputCheck:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                ; move to position $FFFC
    word Reset               ; write 2 bytes with the program reset address
    word Reset               ; write 2 bytes with the interruption vector
