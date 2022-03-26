.zeropage
GRID_SIZE = 6 * 5
GRID_LEN = GRID_SIZE * 2
mGridColors: .res GRID_LEN, $00 ; word size in memory

.code 
MAP_BASE = $7C00

; Colors
; EMPTY = $00
GUESS_NO_FILL = $02     ; hasn't guessed yet    ; maps to tilemap $04
GUESS_GREEN = $04       ; correct guess         ; maps to tilemap $08 
GUESS_YELLOW = $06      ; letter in word
GUESS_DARK_GRAY = $08   ; wrong guess
; LIGHT_GRAY = $0A  ; keyboard color

; Zero the grid
mGrid_init:
    ldy #GUESS_GREEN
    ldx #GRID_LEN - 1
    @loop:
    sty mGridColors, x
    dex
    dex
    bpl @loop
rts

.macro base_dma_grid_row row
    ; TODO fill this in.
    ; Turn row into mirror offset index
    ; do for row length 5 words or $A bytes
    col .set 0
    offset .set (((row + 3) * 16) * 2) + 6 + col
    len .set 5 * 2

    ; TODO: SOmething wrong here i think
    load_block_to_vram mGridColors + offset, MAP_BASE + offset, len

    ; base_guess_pos_x mGridColors, row, 0  ; get index as X
    ; I assume the length is 5 to DMA


    ; TODO replace @base_test_color below with this call
.endmacro

; Sets X to an offset from base in (row, col)
.macro base_guess_pos_x base, row, col
    ldx #base + (((row + 3) * 16) * 2) + 6 + col
.endmacro


; Stores base position to VM Address
.macro base_guess_pos base, row, col
    base_guess_pos_x base, row, col
    stx VMADDL 
.endmacro

.macro base_kb_pos base, row, col
    ldx #base + (((row + 10) * 16) * 2) + 4 + col
    stx VMADDL 
.endmacro

.macro put_grid_row_at base_loc, row, offset
    ldx #base_loc + ((row * 16) * 2) + offset
    stx VMADDL 
    jsr put_grid_row
.endmacro

put_grid_row:
    ldx #$05
    @guess_row:
        ldy #GUESS_NO_FILL
        sty VMDATAL
        dex
    bne @guess_row
rts

setup_base_tilemap:
    ; We assume the base tilemap has zeros everywhere first

    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.
    ldx #MAP_BASE
    stx VMADDL ; destination of vram

    ; Leave row 0 blank
    ldx #$10
    @first_row:
        ldy #$00
        sty VMDATAL
        dex
    bne @first_row

    ; Row 1 offset 5 - SUPER WORDLE
    ldx #MAP_BASE + ((1 * 16) * 2) + 5 ;*2 to turn addr to word
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

    put_grid_row_at MAP_BASE, 3, 6
    put_grid_row_at MAP_BASE, 4, 6
    put_grid_row_at MAP_BASE, 5, 6
    put_grid_row_at MAP_BASE, 6, 6
    put_grid_row_at MAP_BASE, 7, 6
    put_grid_row_at MAP_BASE, 8, 6

    ; Row 10 offset 4
    ldx #MAP_BASE + ((10 * 16) * 2) + 4
    stx VMADDL 

    ; KB Row 1
    ldx #$A
    @kb_1:
        ldy #$0A
        sty VMDATAL
        dex
    bne @kb_1

    ; Row 11 offset 4
    ldx #MAP_BASE + ((11 * 16) * 2) + 4
    stx VMADDL 

    ; KB Row 2
    ldx #$9
    @kb_2:
        ldy #$0A
        sty VMDATAL
        dex
    bne @kb_2
    
    ; Row 12 offset 3
    ldx #MAP_BASE + ((12 * 16) * 2) + 3
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

    @base_test_color:

    base_guess_pos MAP_BASE, 0, 0
    ldy #GUESS_GREEN
    sty VMDATAL
    base_guess_pos MAP_BASE, 0, 1
    ldy #GUESS_YELLOW
    sty VMDATAL
    base_guess_pos MAP_BASE, 0, 2
    ldy #GUESS_DARK_GRAY
    sty VMDATAL
    base_guess_pos MAP_BASE, 0, 3
    ldy #GUESS_DARK_GRAY
    sty VMDATAL
    base_guess_pos MAP_BASE, 0, 4
    ldy #GUESS_DARK_GRAY
    sty VMDATAL

    @base_test_kb_color:
    base_kb_pos MAP_BASE, 1, 1
    ldy #GUESS_GREEN
    sty VMDATAL
    base_kb_pos MAP_BASE, 0, 6
    ldy #GUESS_YELLOW
    sty VMDATAL
    base_kb_pos MAP_BASE, 0, 9
    ldy #GUESS_DARK_GRAY
    sty VMDATAL
    base_kb_pos MAP_BASE, 0, 2
    ldy #GUESS_DARK_GRAY
    sty VMDATAL
    base_kb_pos MAP_BASE, 0, 3
    ldy #GUESS_DARK_GRAY
    sty VMDATAL
    
rts
