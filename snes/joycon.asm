.macro joycon_read wJoyVar
    @joycon_read_in_progress:
    lda HVBJOY   ; auto-read joypad status
    and #$01    ; Check low bit to see if ready to be read.
    
    ; wait for 0 to ready to read data
    bne @joycon_read_in_progress

    ; read joycon data (registers 4218h ~ 421Fh)
    @joycon_ready_to_read:
    ldx JOY1L    ; Controller 1 as 16 bit.
    stx wJoyVar
.endmacro
