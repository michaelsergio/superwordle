.zeropage
mMosaic: .res 1, $00
mosaic_value: .res 1, $00 ; Value is 0-F


.code

mosaic_init:
  stz mMosaic
  stz mosaic_value
rts

; Inc 0-15
mosaic_inc:
    lda mosaic_value

    cmp #$0e ; if > e, dont inc
    beq @done

    inc
    sta mosaic_value
    jsr set_mosaic_value
    @done:
rts

; Dec 0-15
mosaic_dec:
    lda mosaic_value
    beq @done      ; Do nothing when 0

    dec
    sta mosaic_value
    jsr set_mosaic_value
    @done:
rts
    

; Set the mosaic_value as the top bits of mMosaic
; leaving the mosaic_enable (bottom bits) unchanged
set_mosaic_value:
    lda mMosaic  
    and #$0f        ; clear_top_bits
    sta mMosaic

    lda mosaic_value
    asl
    asl
    asl
    asl
    ora mMosaic
    sta mMosaic
rts

.macro mosaic_set_enable bg
    lda mMosaic
    and #$f0 ; clear MOSAIC enable
    ora #bg  ; set MOSAIC enable
    sta mMosaic
.endmacro

mosaic_draw:
    lda mMosaic
    sta MOSAIC
rts
