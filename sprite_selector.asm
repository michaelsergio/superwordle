.zeropage
sprite_x: .res 1, $00
sprite_y: .res 1, $00
sprite_dirty: .res 1, $00

.bss 
mOamSprites: .res 4 * 2     ; 2 sprites, size 4
mOamSpritesHighTable: .res 1 * 1     ; 4 sprites, size 1 byte

.code

sprite_selector_init_oam:
    ; sprite 0
    stz mOamSprites + 0 ; pos
    stz mOamSprites + 1 ; pos
    stz mOamSprites + 2 ; selector sprite
    stz mOamSprites + 3 ; selector sprite status

    lda #$02         ; Sprite 0 - Size=Large HPosMSB=0
    ; Every other field should be large with HPosMSB set.
    sta mOamSpritesHighTable
rts

sprite_selector_use_large_selector:
    ; TODO: Swap in the large selector
rts
sprite_selector_use_small_selector:
    ; TODO: Swap in the small selector
    ; This just might be the code for sprite_selector_init_oam
rts

sprite_selector_dmi:
    ; TODO: Need a mirror of OAM 0 and 1
    ; mirror mOamSprites
    ; and mOamSpritesHighTable

    ; maybe use two channels for this
rts

sprite_selector_load: 
    stz OAMADDL     
    stz OAMADDH     ; write to oam slot 0000 - will autoinc after L/H write

    lda #$00
    sta OAMDATA     ; position
    lda #$00
    sta OAMDATA     ; position
    lda #$0C
    sta OAMDATA     ; selector sprite
    lda #SPR_PRIOR_2
    sta OAMDATA     ; selector sprite status

    lda #$01
    sta OAMADDH     ; Swith to high table

    lda #$02         ; Sprite 0 - Size=Large HPosMSB=0
    sta OAMDATA
rts

sprite_selector_update_pos:
    ; TODO Check bound conditions for enlarged sprites
    ; normal sprite is addr $180/ $C0w
    ; enlarged sprite is addr $0900 / $480w

    lda sprite_dirty
    beq @skip

    stz OAMADDL     
    stz OAMADDH  ; OAM Sprite pos $0000
    
    lda sprite_y                 ; value should be 0-2
    asl                          ; y*2 for word size: now 0,2,4
    tay                          ; y index is the offset for which table to use 
    ldx kb_selector_pos_table, y ; get table row, relative to table
    stx z:dpTmp0                 ; store table row (word)

    lda sprite_x
    asl                          ; sprite_x * 2 for 2 bytes pos: (x,y)
    tay
    lda (dpTmp0), y
    sta OAMDATA                  ; x position
    iny 
    lda (dpTmp0), y
    sta OAMDATA                  ; y  position

    stz sprite_dirty
    @skip:
rts

X_LIMIT = $9 ; max x-pos before next line
Y_LIMIT = $2 ; 2 

sprite_selector_move_left:
    lda sprite_x
    beq @limit
    dea
    sta sprite_x
    bra @done
    @limit:
    lda #X_LIMIT
    sta sprite_x
    jsr sprite_selector_move_up
    @done:
    lda #$01 
    sta sprite_dirty
rts

sprite_selector_move_right:
    lda sprite_x
    cmp #X_LIMIT
    beq @limit
    ina
    sta sprite_x
    bra @done
    @limit:
    stz sprite_x
    jsr sprite_selector_move_down
    @done:
    lda #$01 
    sta sprite_dirty
rts

sprite_selector_move_up:
    lda sprite_y
    beq @limit
    dea
    sta sprite_y
    bra @done
    @limit:
    lda #Y_LIMIT
    sta sprite_y
    @done:
    lda #$01 
    sta sprite_dirty
rts

sprite_selector_move_down:
    lda sprite_y
    cmp #Y_LIMIT
    beq @limit
    inc
    sta sprite_y
    bra @done
    @limit:
    stz sprite_y
    @done:
    lda #$01 
    sta sprite_dirty
rts