.struct CountdownTimer
    timer .byte
.endstruct

; Starts finished. 
; Must call countdown_reset to start it 
.macro countdown_init self 
    stz self + CountdownTimer::timer
.endmacro

.macro countdown_reset self, value
    lda #value
    sta self + CountdownTimer::timer
.endmacro

.macro countdown_tick self
    .scope
    lda self + CountdownTimer::timer
    beq @countdown_timer_tick_done
    dec
    sta self + CountdownTimer::timer
    @countdown_timer_tick_done:
    .endscope
.endmacro

; This means we are ready for input and not counting down.
; 0 is set when done counting
; Other when counting down
.macro countdown_finished self
    lda self + CountdownTimer::timer
.endmacro
