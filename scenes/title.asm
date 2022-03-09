.include "scenes.asm"

.zeropage
active_scene: .res 1, $00
title_counter: .res 2, $0000 ; A counter used for RNG

TITLE_MAP_BASE = $7C00
TITLE_WORDLE_CHARS = 8
TITLE_WORDLE_VRAM = $20

; Char Positions
TITLE_WORDLE_X = 5
TITLE_WORDLE_Y = 2

TITLE_MODE_X = 6
TITLE_MODE_Y = 8
TITLE_MODE_Y1 = 9

TITLE_START_X = 3
TITLE_START_Y = 12


.code 

title_init:
    lda #Scenes::title
    ; lda #Scenes::game
    sta active_scene

    ldx #$0000
    stx title_counter
rts

title_setup_video:
    load_palette main_screen_palette, $00, $06

    load_block_to_vram main_tiles, VRAM_MAIN_TILES, main_tiles_end - main_tiles
    load_block_to_vram font_sloppy_transparent, VRAM_FONT, font_sloppy_transparent_end - font_sloppy_transparent
    jsr title_setup_tilemap
    jsr title_register_screen_settings
rts

title_register_screen_settings:
    lda #$01 | BG1_16x16 | BG3_TOP
    sta BGMODE  ; mode 1

    ;addr f800 in tv
    lda #$7C    ; Tile Map Location - set BG1 tile offset to $7C00 >> 8 (Word addr) 
    sta BG1SC   ; BG1SC 

    ;addr c000 in tv
    lda #$60    ; Tile Map Location - set BG3 tile offset to $6000 (Word addr) 
    sta BG3SC   ; BG3SC  aaaaaass bottom two are size

    lda #$00
    sta BG12NBA ; BG1 name base address to $0000 (word addr) (Tiles offset)

    lda #$01    ; 4k-word 1 or $1000 (word address)
    sta BG34NBA ; BG3 name base address to (Tiles offset)

    lda #(BG1_ON | BG3_ON | SPR_ON) ; Enable BG1 and Sprites as main screen.
    sta TM

    ; lda #$FF    ; Scroll down 1 pixel (FF really 03FF 63) (add -1 in 2s complement)
    ; sta BG1VOFS
    ; sta BG1VOFS ; Set V offset Low, High, to FFFF for BG1

    ; lda #$FB    ; -5
    ; sta BG3VOFS
    ; stz BG3VOFS ; 

    ; lda #$FC    ; -4
    ; sta BG3HOFS
    ; stz BG3HOFS ; 
rts

title_setup_tilemap:
    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.
    ldx #MAP_BASE
    stx VMADDL ; destination of vram

    ; Row 1 offset 5 - SUPER WORDLE
    ldx #MAP_BASE + ((TITLE_WORDLE_Y * 16) * 2) + TITLE_WORDLE_X ; *2 to turn addr to word
    stx VMADDL 

    ldx #TITLE_WORDLE_CHARS     ; 8 characters to place
    ldy #TITLE_WORDLE_VRAM      ; Location of SU
    @super_wordle:
        sty VMDATAL             ; Output rest of wordle
        iny
        iny                     ; skip two since 16bit char
        dex
    bne @super_wordle

    @difficulies:
    alpha_pos TITLE_MODE_X, TITLE_MODE_Y
    write_str text_easy
    alpha_pos TITLE_MODE_X, TITLE_MODE_Y1
    write_str text_hard

    @press_start:
    alpha_pos TITLE_START_X, TITLE_START_Y
    write_str text_press_start
rts


tile_joy_pressed_update:
    ;upon start change scene
rts

title_loop:
    @title_loop_top:
        ldx title_counter
        inx
        stx title_counter   ; increment this forever

        lda active_scene
        cmp #Scenes::title
    beq @title_loop_top
rts 

title_vblank:
rts

text_press_start: .asciiz "PRESS START TO PLAY"
text_easy: .asciiz "EASY MODE"
text_hard: .asciiz "HARD MODE"