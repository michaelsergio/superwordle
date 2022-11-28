; To use these macros, make sure joycon auto read is enabled
;   lda #(NMI_ON | AUTO_JOY_ON) ; enable VBlank and Controller read
;   sta NMITIMEN

; Blocks waiting for joypad status to be ready
.macro joycon_read_joy1_blocking wJoyVar
    joycon_wait_for_ready
    joycon_fast_read wJoyVar
.endmacro

.macro joycon_wait_for_ready
    @joycon_read_in_progress:
    lda HVBJOY   ; auto-read joypad status
    and #$01    ; Check low bit to see if ready to be read.
    
    ; wait for 0 to ready to read data
    bne @joycon_read_in_progress
.endmacro

.macro joycon_fast_read wJoyVar
    ; read joycon data (registers 4218h ~ 421Fh)
    ldx JOY1L    ; Controller 1 as 16 bit.
    stx wJoyVar
.endmacro
