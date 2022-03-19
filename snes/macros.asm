
; Sets the data bank register
; Must have a8
.macro setdbr bank
    lda #bank
    pha       ; push bank in A to stack
    plb       ; pull into bank
.endmacro

; 16 bit accumulator & memory
.macro a16
    .a16
    rep $20
.endmacro


;16 bit all registers
.macro a16i16
    .a16
    .i16
    rep $30
.endmacro

;16 bit index registers
.macro i16
    .i16
    rep $10
.endmacro

;8 bit accumulator & memory
.macro a8
    .a8
    sep $20
.endmacro

;8 bit index registers
.macro i16
    .i16
    sep $10
.endmacro

;8 bit all registers
.macro a8i8
    .a8
    .i8
    sep $30
.endmacro

;8 bit index registers
.macro i8
    .i8
    sep $10
.endmacro

; I took from .macpack generic    
; Didnt want add sub bze bnz
.macro  bge     Arg     ; branch on greater-than or equal
    bcs     Arg
.endmacro

.macro  blt     Arg     ; branch on less-than
    bcc     Arg
.endmacro

.macro  bgt     Arg     ; branch on greater-than
    .local  L
    beq     L
    bcs     Arg
    L:
.endmacro

.macro  ble     Arg     ; branch on less-than or equal
    beq     Arg
    bcc     Arg
.endmacro
