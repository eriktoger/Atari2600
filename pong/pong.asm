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
BallXPos        byte         ; ball x-position
BallYPos        byte         ; ball y-position
BallMovement    byte         ; ball movement pattern
Temp            byte         ; debugging tool



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
    lda #95
    sta P1YPos              ; P1YPos  = 50
    lda #10
    sta BallYPos            ; BallYPos = 45
    lda #80
    sta BallXPos            ; BallXPos = 45
    lda #%00000001
    sta BallMovement       ; BallMovement = 0
    ; first bit is left or right  with zero being left
    ; second bit is up or down with zero being up
    ; rest of the bits show if the y change is 0,1,2,3

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
    REPEAT 32
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed during the VBLANK section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$C2
    sta COLUBK
    lda #$1C ; light green
    sta COLUPF

    ldx #5      ; placing p0 to the left
    sta WSYNC
Loop1:
    dex
    bne Loop1 
    sta RESP0 

    sta WSYNC
    ldx #12     ; placing p1 to the right
Loop2:
    dex
    bne Loop2
    dex
    sta RESP1 
    sta WSYNC

    lda BallXPos
    sec
Div15Loop
    sbc #15                 ; subtract 15 from accumulator
    bcs Div15Loop           ; loop until carry-flag is clear
    eor #7                  ; handle offset range from -8 to 7
    asl
    asl
    asl
    asl                    ; four shift lefts to get only the top 4 bits
    sta HMBL               ; store the fine offset to the correct HMxx
    sta RESBL

    sta WSYNC
    sta HMOVE
    sta WSYNC
    lda #0
    sta VBLANK     ; turn VBLANK off
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$8E
                       ; reset TIA registers before displaying the score
    sta COLUPF
    lda #%11111111
    sta PF0
    sta PF1
    sta PF2

    ; 6 scanlines for upper border
    sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    
    lda #$C2
    sta COLUBK
    ldx #95 ; (192 - 12)/2 = 90 scanlines
    lda #0
    sta PF0
    sta PF1
    sta PF2

    lda #$1C ; light green
    sta COLUPF

GameLineLoop:
    sta WSYNC 
    txa
    cmp P0YPos      ; check if we should display p0 paddle
    bpl noP0Display ; if we are above the Y, we dont display
    clc
    adc #10
    cmp P0YPos      ; if we are 10 steps below we dont display
    bmi noP0Display
    lda #$98
    sta COLUP0
    lda #%00011000
    sta GRP0

    jmp displayBall
noP0Display:
    lda #%00000000
    sta GRP0
    lda #0
    sta COLUP0

displayBall:
    txa
    cmp BallYPos
    bne noBall
    lda #2
    sta ENABL  ; enable the ball!
    jmp displayP1
noBall:
    lda #0    ;zero disables the ball
    sta ENABL  ;disable the ball

displayP1:
    txa
    cmp P1YPos           ; check if we should display p1 paddle
    bpl noP1Display      ; if we are above the Y, we dont display
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

; Draw lower border
    lda #$8E
    sta COLUPF
    lda #%11111111
    sta PF0
    sta PF1
    sta PF2

    sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    ;sta WSYNC
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK     ; enable VBLANK back again
    REPEAT 30
       sta WSYNC   ; output the 30 recommended overscan lines
    REPEND
    lda #0
    sta VBLANK               ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process joystick input for player 0/1 up/down
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    lda #%00010000           ; joystick up for player 0
    bit SWCHA
    bne CheckP0Down
    lda P0YPos
    cmp #94                  ; if (player0 Y position > 90)
    bpl CheckP0Down          ;    then: skip increment
P0UpPressed:                 ;    else:
    inc P0YPos               ;        increment Y position

CheckP0Down:
    lda #%00100000           ; joystick down for player 0
    bit SWCHA
    bne CheckP1Up
    lda P0YPos
    cmp #13                  ; if (player0 Y position < 15)
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
;; Check collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Collision:    
    lda #%01000000
    bit CXP0FB
    beq P1Collision
    lda BallMovement
    eor #%10000000
    sta BallMovement
    jmp BallPFCollision

P1Collision:
    lda #%01000000
    bit CXP1FB
    beq BallPFCollision
    lda BallMovement
    eor #%10000000
    sta BallMovement

BallPFCollision:
    lda BallYPos
    and #%11111111
    bne BallUpper ; if zero
    lda BallMovement
    eor #%01000000
    sta BallMovement
    jmp UpdateBall
BallUpper:
    lda BallYPos
    eor #97
    bne UpdateBall
    lda BallMovement
    eor #%01000000
    sta BallMovement
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lpdate ball position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateBall:
    lda BallMovement
    and #%10000000
    cmp #%00000000
    bne BallGoLeft
    dec BallXPos
    dec BallXPos
    jmp UpOrDown
BallGoLeft:
    inc BallXPos
    inc BallXPos
UpOrDown:    
    lda BallMovement
    and #%01000000
    cmp #%00000000
    bne BallGoDown
BallGoUp:
    lda BallMovement
    and #%00000011
    tay
RaiseBall:
    beq NextFrame
    inc BallYPos
    dey
    jmp RaiseBall 

BallGoDown:
    lda BallMovement
    and #%00000011
    tay
LowerBall:
    beq NextFrame
    dec BallYPos
    dey
    jmp LowerBall 

; UpdateBall:
;     lda BallMovement
;     and #%10000000
;     cmp #%00000000
;     bne BallGoLeft
;     dec BallXPos
;     dec BallXPos
;     jmp BallGoUp
; BallGoLeft:
;     inc BallXPos
;     inc BallXPos

;     lda BallMovement
;     and #%01000000
;     bne BallGoDown
; BallGoUp:
;     lda BallMovement
;     and #%00000011
;     tay
; RaiseBall:
;     inc BallYPos
;     dey
;     bne RaiseBall
;     jmp NextFrame 

; BallGoDown:
;     lda BallMovement
;     and #%00000011
;     tay
; LowerBall:
;     dec BallYPos
;     dey
;     bne LowerBall
;     jmp NextFrame    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NextFrame:
    lda #0
    sta CXCLR
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                ; move to position $FFFC
    word Reset               ; write 2 bytes with the program reset address
    word Reset               ; write 2 bytes with the interruption vector
