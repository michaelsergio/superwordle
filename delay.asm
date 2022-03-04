.struct Delay
    timer .byte
    trigger .byte
.endstruct

.macro delay_set delay, time
    lda #time
    sta delay + Delay::timer
    stz delay + Delay::trigger
.endmacro

.macro delay_tick delay
.scope
    lda delay + Delay::timer
    beq @done
    dec
    sta delay + Delay::timer
    bne @done ; if zero: set trigger
    lda #$1
    sta delay + Delay::trigger
    @done:
.endscope
.endmacro

; A=0 if off
; A=1 if trigger
.macro delay_check delay
    lda delay + Delay::trigger
.endmacro

