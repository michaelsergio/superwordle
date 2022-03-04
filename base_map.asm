
.macro put_grid_row_at base_loc, row, offset
    ldx #base_loc + ((row * 16) * 2) + offset
    stx VMADDL 
    jsr put_grid_row
.endmacro

setup_base_tilemap:
    ; We assume the base tilemap has zeros everywhere first

    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.
    ldx #$7C00
    stx VMADDL ; destination of vram

    ; Leave row 0 blank
    ldx #$10
    @first_row:
        ldy #$00
        sty VMDATAL
        dex
    bne @first_row

    ; Row 1 offset 5 - SUPER WORDLE
    ldx #$7C00 + ((1 * 16) * 2) + 5 ;*2 to turn addr to word
    stx VMADDL 

    ldx #$08
    ldy #$20    ; Location of SU
    @second_row:
        sty VMDATAL
        iny
        iny
        dex
    bne @second_row

    ; Row 2 offset 3 - SUPER WORDLE

    put_grid_row_at $7C00, 3, 6
    put_grid_row_at $7C00, 4, 6
    put_grid_row_at $7C00, 5, 6
    put_grid_row_at $7C00, 6, 6
    put_grid_row_at $7C00, 7, 6
    put_grid_row_at $7C00, 8, 6

    ; Row 10 offset 4
    ldx #$7C00 + ((10 * 16) * 2) + 4
    stx VMADDL 

    ; KB Row 1
    ldx #$A
    @kb_1:
        ldy #$0A
        sty VMDATAL
        dex
    bne @kb_1

    ; Row 11 offset 4
    ldx #$7C00 + ((11 * 16) * 2) + 4
    stx VMADDL 

    ; KB Row 2
    ldx #$9
    @kb_2:
        ldy #$0A
        sty VMDATAL
        dex
    bne @kb_2
    
    ; Row 12 offset 3
    ldx #$7C00 + ((12 * 16) * 2) + 3
    stx VMADDL 

    ; Enter 
    ldy #$40
    sty VMDATAL
    ldy #$42
    sty VMDATAL
    ; KB Row 3
    ldx #$07
    @kb_3:
        ldy #$0A
        sty VMDATAL
        dex
    bne @kb_3
    ; Backspace 
    ldy #$44
    sty VMDATAL
    ldy #$46
    sty VMDATAL
rts

put_grid_row:
    ldx #$05
    @guess_row:
        ldy #$02
        sty VMDATAL
        dex
    bne @guess_row
rts
