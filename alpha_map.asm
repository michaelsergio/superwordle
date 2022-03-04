.macro alpha_pos px, py
    ldx #$6000 + ((32 * py + px) * 2)
    stx VMADDL  ; destination of vram
.endmacro

; With respect to the guesses
.macro guess_pos row
    ldx #$6000 + ((32 * (row + 3) + 6) * 2)
    stx VMADDL  ; destination of vram
.endmacro

.macro write_str str
.scope
    ldx #$0
    loop_letters:
        lda str, x
        beq @done

        sta VMDATAL ; write char name 
        lda #%00100100 ; high pri | color 2
        sta VMDATAH ; write status data
        inx
    bra loop_letters
    @done:
.endscope
.endmacro


setup_alpha_tilemap:
    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.

    alpha_pos 4, 10
    write_str letters_0

    alpha_pos 4, 11
    write_str letters_1

    alpha_pos 5, 12
    write_str letters_2

    ; alpha_pos 6, 3
    guess_pos 0
    write_str test_word
rts


letters_0: .asciiz "Q W E R T Y U I O P"
letters_1: .asciiz "A S D F G H J K L"
letters_2: .asciiz "Z X C V B N M"
test_word: .asciiz "S U P E R"