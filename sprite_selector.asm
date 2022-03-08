.zeropage
sprite_x: .res 1, $00
sprite_y: .res 1, $00
sprite_dirty: .res 1, $00

.bss 
SPRITE_SELECTOR_OAM_SIZE = 4 * 2 ; 2 sprites, each size 4
mOamSprites: .res SPRITE_SELECTOR_OAM_SIZE
mOamSpritesHighTable: .res 1 * 1     ; 4 sprites, size 1 byte

.code

SMALL_SELECTOR_NAME = $0C

sprite_selector_init_oam:
    ; init sprite sel position
    stz sprite_x
    stz sprite_y

    ; sprite 0
    stz mOamSprites + 0 ; pos
    stz mOamSprites + 1 ; pos
    lda #SMALL_SELECTOR_NAME
    sta mOamSprites + 2 ; selector sprite
    lda #SPR_PRIOR_2
    sta mOamSprites + 3 ; selector sprite status

    lda #(SPR_SIZE_LG | SPR_POS_X) << 0   ; Sprite 0 - Size=Large HPosMSB=0
    sta mOamSpritesHighTable        ; Every other field should be large with HPosMSB set.

    ; Set the sprites position 
    lda #$01 
    sta sprite_dirty ; set initial sprite as dirty so we can set position
    jsr sprite_selector_update_pos

    ; sprite 1
    stz mOamSprites + 4 * 1 + 0
    stz mOamSprites + 4 * 1 + 1
    stz mOamSprites + 4 * 1 + 2
    stz mOamSprites + 4 * 1 + 3
rts

sprite_selector_use_large_selector:
    ; TODO: Swap in the large selector
rts
sprite_selector_use_small_selector:
    ; TODO: Swap in the small selector
    ; This just might be the code for sprite_selector_init_oam
rts

sprite_selector_dma:
    ; TODO: Need a mirror of OAM 0 and 1
    ; mirror mOamSprites
    ; and mOamSpritesHighTable

    lda sprite_dirty
    beq not_dirty

    stz OAMADDL     
    stz OAMADDH  ; OAM Sprite pos $0000

    ldx #mOamSprites  ; load label address for ram
    lda #^mOamSprites ; and bank
    stx CH0 + A1TxL   ; DMA data offset
    sta CH0 + A1Bx    ; DMA data bank
    ldy #SPRITE_SELECTOR_OAM_SIZE
    sty CH0 + DASxL   ; DMA size

    lda #$00            ; DMA mode single byte
    sta CH0 + DMAPx
    lda #$04            ; DMA destination register 2104 (OAM data write high)
    sta CH0 + BBADx

    lda #$01     ; DMA channel 0
    sta MDMAEN  ; Initiate transfer

    ; Switch to high table and do it manually
    lda #$01
    sta OAMADDH     

    lda mOamSpritesHighTable
    sta OAMDATA

    not_dirty:
    stz sprite_dirty
rts


sprite_selector_update_pos:
    ; TODO Check bound conditions for enlarged sprites
    ; normal sprite is addr $180/ $C0w
    ; enlarged sprite is addr $0900 / $480w

    lda sprite_dirty
    beq @not_dirty
    lda #$00

    lda sprite_y                 ; value should be 0-2
    asl                          ; y*2 for word size: now 0,2,4
    tay                          ; y index is the offset for which table to use 
    ldx kb_selector_pos_table, y ; get table row, relative to table
    stx z:dpTmp0                 ; store table row (word)

    lda sprite_x
    asl                          ; sprite_x * 2 for 2 bytes pos: (x,y)
    tay
    lda (dpTmp0), y
    sta mOamSprites + 0          ; x position
    iny 
    lda (dpTmp0), y
    sta mOamSprites + 1          ; y  position

    @not_dirty:
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