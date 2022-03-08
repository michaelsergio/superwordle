MAP_ALPHA = $6000

.macro alpha_pos px, py
    ldx #MAP_ALPHA + ((32 * py + px) * 2)
    stx VMADDL  ; destination of vram
.endmacro

.macro load_row_x row
    ldx #MAP_ALPHA + ((32 * (row + 3) + 6) * 2)
.endmacro

; A less efficient version of guess_pos
; Maybe better just to CMP row and  hardcode guess_pos
; A: holds row
alpha_map_guess_pos_with_register_a:
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
    @default: ; default case fall through to case_0

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
    stx VMADDL  ; store position into vram
rts

.macro write_str_with_space str
.scope
    ldx #$0
    loop_letters:
        lda str, x
        beq @done

        sta VMDATAL     ; write char name 
        lda #%00100100  ; high pri | color 2
        sta VMDATAH     ; write status data
        lda #' '        ; hex 20
        sta VMDATAL     ; write char name 
        lda #%00100100  ; high pri | color 2
        sta VMDATAH     ; write status data
        inx
    bra loop_letters
    @done:
.endscope
.endmacro


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
test_word: .asciiz "SUPER"