MAP_ALPHA = $6000
HIGH_PRI_COLOR_2 = %00100100 

.macro alpha_pos px, py
    ldx #MAP_ALPHA + ((32 * py + px) * 2)
    stx VMADDL  ; destination of vram
.endmacro

; A: py - row 0-2
; X: px - col 0-5
alpha_pos_ax:
    clc
    adc #$03
    tay

    .a16
    rep #$30 ; 16-bit aaccumulator/index
    tya

    asl
    asl
    asl
    asl
    asl


    tay
    txa
    beq @loop_done
    tya
    @loop_add:
        ina
        dex
    bne @loop_add

    @loop_done:

    asl
    tax

    lda #$0
    rep #$10
    sep #$20
    .a8
    
    stx VMADDL  ; store position into vram
rts

.macro load_row_x row
    ldx #MAP_ALPHA + ((32 * (row + 3) + 6) * 2)
.endmacro

; A less efficient version of guess_pos
; Maybe better just to CMP row and  hardcode guess_pos
; A: holds row
alpha_map_guess_pos_with_register_a_as_x:
    ; branch table for jumps
    beq @case_0
    dec
    beq @case_1
    dec
    beq @case_2
    dec
    beq @case_3
    dec
    beq @case_3
    dec
    beq @case_5
    @default: ; default case - fall through to case_0

    @case_0:
    load_row_x 0
    bra @done

    @case_1:
    load_row_x 1
    bra @done

    @case_2:
    load_row_x 2
    bra @done

    @case_3:
    load_row_x 3
    bra @done

    @case_4:
    load_row_x 4
    bra @done

    @case_5:
    load_row_x 5
    bra @done

    @done:
rts

.macro write_str_with_space str
.scope
    ldx #$0
    loop_letters:
        lda str, x
        beq @done

        sta VMDATAL     ; write char name 
        lda #HIGH_PRI_COLOR_2
        sta VMDATAH     ; write status data
        lda #' '        ; hex 20
        sta VMDATAL     ; write char name 
        lda #HIGH_PRI_COLOR_2
        sta VMDATAH     ; write status data
        inx
    bra loop_letters
    @done:
.endscope
.endmacro

.macro write_str str
.scope
    ldx #$0000
    loop_letters:
        lda str, x
        beq @done

        sta VMDATAL     ; write char name 
        lda #HIGH_PRI_COLOR_2
        sta VMDATAH     ; write status data
        inx
    bra loop_letters
    @done:
.endscope
.endmacro


; Writes a character to the next spot in the map
; A: the character to write
alpha_map_write_char_to_screen:
    beq @done
    ; TODO ; I Should probably DMA this instead
    sta VMDATAL     ; write char name 
    lda #HIGH_PRI_COLOR_2
    sta VMDATAH     ; write status data
    lda #' '        ; hex 20
    sta VMDATAL     ; write char name 
    lda #HIGH_PRI_COLOR_2
    sta VMDATAH     ; write status data
    @done:
rts 


alpha_map_setup_tiles:
    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.

    alpha_pos 4, 10
    write_str_with_space letters_0

    alpha_pos 4, 11
    write_str_with_space letters_1

    alpha_pos 5, 12
    write_str_with_space letters_2

    ; alpha_pos 6, 3
    load_row_x 0
    stx VMADDL
    write_str_with_space test_word
rts


letters_0: .asciiz "QWERTYUIOP"
letters_1: .asciiz "ASDFGHJKL"
letters_2: .asciiz "ZXCVBNM"
LETTER_0_COUNT = .sizeof(letters_0) - 1     ; remove null term
LETTER_1_COUNT = .sizeof(letters_1) - 1
LETTER_2_COUNT = .sizeof(letters_2) - 1
test_word: .asciiz "SUPER"