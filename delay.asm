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
.proc
    lda delay + Delay::timer
    beq @done
    dec
    sta delay + Delay::timer
    bne @done ; if zero: set trigger
    lda #$1
    sta delay + Delay::trigger
    @done:
.endproc
.endmacro

; A=0 if off
; A=1 if trigger
.macro delay_check delay
    lda delay + Delay::trigger
.endmacro


.struct DelaySecondsCall
    frame_timer .byte
    seconds .byte
    func .word
.endstruct

FPS_30 = $1E 

.macro delay_seconds_call_set_seconds delay, seconds, func
    lda #FPS_30 ; 30 frames per second
    sta delay + DelaySecondsCall::frame_time
    lda #seconds
    sta delay + DelaySecondsCall::seconds
    ldx #addr
    stx delay + DelaySecondsCall::func
.endmacro

.macro delay_seconds_call_set_frames delay, frames, func
    lda #frames     ; This can be more than 30. Thats ok.
    sta delay + DelaySecondsCall::frame_time
    lda #1          ; This only fires once
    sta delay + DelaySecondsCall::seconds
    ldx #addr
    stx delay + DelaySecondsCall::func
.endmacro

; Inputs: X as delay ptr *delay
delay_seconds_call_tick:
    lda DelaySecondsCall::frame_timer, x
    dec
    sta DelaySecondsCall::frame_timer, x
    bne @done

    @frames_0:
    lda DelaySecondsCall::seconds, x
    dec
    sta DelaySecondsCall::seconds, x ; decrement the second count
    beq @seconds_0

    @reset_frames_for_next_second:
    lda #FPS_30
    sta DelaySecondsCall::frame_timer, x
    bra @done

    @seconds_0:
    jsr (DelaySecondsCall::func, x)

    @done:
rts