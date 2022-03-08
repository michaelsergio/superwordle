.macro joycon_read wJoyVar
    lda HVBJOY   ; auto-read joypad status
    and #$01    ; Check low bit to see if ready to be read.
    bne end_joycon_read

    ; read joycon data (registers 4218h ~ 421Fh)
    ldx JOY1L   ; Controller 1 as 16 bit.
    stx wJoyVar

    end_joycon_read:
.endmacro
