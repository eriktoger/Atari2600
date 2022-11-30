    processor 6502

    seg code
    org $F000

Start:
    sei         ; Disable disrubts
    cld         ; Disable decimal math mode
    ldx #$FF    ; Load the value FF to X
    txs         ; Transfer X register to the Stack pointer


; Clear page zero 00-FF, the entire ram and tia registers
    lda #0      ; A=0
    ldx #$FF    ; X=FF

MemLoop:
    sta $0,X    ; Store the value of A in $0 + X
    dex         ; X--
    bne MemLoop ; go to MemLoop if the zero flag is not set
    
    sta $0      ; Since we exit the loop before setting 00
; Fill the ROM size to exactly 4KB
    org $FFFC
    .word Start ;Reset vector at $FFFC
    .word Start ; Interrupt vector $FFFE