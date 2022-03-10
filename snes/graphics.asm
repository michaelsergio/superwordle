; Simplfies loading vram to copy data
; src_addr: 24 bit addr of src data
; dest: VRAM addr to write to (WORD address!)
; size: number of Bytes to copy
; modifies a, x, y
.macro load_block_to_vram src_addr, dest, size
    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.
    ldx #dest
    stx VMADDL ; destination of vram

    ; Make call to load_vram
    lda #^src_addr  ; Gets the bank of the src_addr
    ldx #src_addr   ; get the src addr
    ldy #size       ; size 
    jsr load_vram
.endmacro

.macro clear_tilemap dst_addr, size
    ; need to clear to every byte
    ; src address is in tilemap bytes not vram word

    stz dpTmp0          ; source to write all zeros

    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.
    ldx #dst_addr
    stx VMADDL ; destination of vram

    lda #$08|$01        ; Fixed Address to clear vram, write 2-address LH
    sta CH0 + DMAPx
    lda #$18            ; DMA destination register 2118 (VRAM data write)
    sta CH0 + BBADx

    ldx #dpTmp0
    lda #^dpTmp0
    ldy #size
    stx CH0 + A1TxL     ; DMA dst addr
    sta CH0 + A1Bx      ; DMA dst bank
    sty CH0 + DASxL     ; DMA size

    lda #$01     ; DMA channel 0
    sta MDMAEN  ; Initiate transfer
.endmacro


; Load Palette with DMA
; In A:X - points to the data (bank and address)
; Y - size of data
load_vram:
    phb  ; store bank
    php  ; store processor status registers

    stx CH0 + A1TxL   ; DMA data offset
    sta CH0 + A1Bx    ; DMA data bank
    sty CH0 + DASxL   ; DMA size

    lda #$01            ; DMA mode WORD (for VRAM 2-addr L,H)
    sta CH0 + DMAPx
    lda #$18            ; DMA destination register 2118 (VRAM data write)
    sta CH0 + BBADx

    lda #$01     ; DMA channel 0
    sta MDMAEN  ; Initiate transfer

    plp
    plb
rts

; src_addr: 24 bit addr of src data
; start: color to start on in CG Ram
; size: # of colors to copy
; modifies a, x, y
.macro load_palette src_addr, start, size
    lda #start
    sta $2121       ; start address for CG RAM

    lda #^src_addr  ; Gets the bank of the src_addr
    ldx #src_addr   ; get the src addr
    ldy #(size * 2) ; bytes for each color (16 bit value)
    jsr dma_palette
.endmacro

; Load Palette with DMA
; In A:X - points to the data (bank and address)
; Y - size of data
dma_palette:
    phb  ; store bank
    php  ; store processor status registers

    stx CH0 + A1TxL   ; DMA data offset
    sta CH0 + A1Bx    ; DMA data bank
    sty CH0 + DASxL   ; DMA size

    stz CH0 + DMAPx

    lda #$22            ; DMA dest register - $2122
    sta CH0 + BBADx

    lda #$01            ; DMA Channel 0
    sta MDMAEN          ; Initiate!

    plp
    plb
rts

; Zeros all the sprites. 
; Sets all the sprites offscreen.
; Note: Instead of this, should probably DMA from an OAM mirror in WRAM
reset_sprite_table:

    lda #%00000000  ;sssnnbbb b=base_sel_bits n=name_selection s=size_from_table
    sta OBSEL

    ; Sprite Table 1 at OAM $00
    stz OAMADDL     
    stz OAMADDH     ; write to oam slot 0000 - will autoinc after L/H write

    ldx #$80         ; Loop over all 127 sprite objects
    lda #$E0         ; 224 ; set the position of every sprite to (-32, 224) 
    @loop_write_pos_name:
        sta OAMDATA     ; x pos: 32 is -224 so set 9th bit in the 2nd table
        sta OAMDATA     ; y pos: 224 is one below the visible screen
        stz OAMDATA     ; Name: Doesnt matter 
        stz OAMDATA     ; HBFlip/Pri/ColorPalette/9name
        dex
    bne @loop_write_pos_name    ; do writes until 0

    ; Write all the negative positions in Table 2
    stz OAMADDL
    lda #$01     
    sta OAMADDH ; Sprite Table 2 at OAM $0100 - will autoinc after L/H write
    
    lda #$55     ; set the 9th bit (h-pos) bit for each spot in the OAM table
    ldx #$000F   ; Do this 15 times. From 100..10F
    @write_next_sprite_pos:
        sta OAMDATA
        sta OAMDATA
        dex
    bne @write_next_sprite_pos  ; do writes until 0
rts

load_custom_palette:
    ; force a palette here
    lda #$80        ; according to A-17 in OBJ palettes in mode 0
    sta CGADD

    lda #$FF       ; White
    sta CGDATA
    sta CGDATA

    lda #%00000000 ; Blue
    sta CGDATA
    lda #%01111100
    sta CGDATA

    lda #%11100000
    sta CGDATA
    lda #%00000011 ; Green
    sta CGDATA

    lda #%00011111
    sta CGDATA
    lda #%00000000 ; Red
    sta CGDATA

    stz CGDATA
    stz CGDATA
    stz CGDATA
    stz CGDATA
    stz CGDATA
    stz CGDATA
    stz CGDATA
    stz CGDATA
rts
