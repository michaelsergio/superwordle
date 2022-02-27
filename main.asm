.define ROM_NAME "SUPER WORDLE"

.include "snes/snes_registers.asm"
.include "snes/lorom128.inc"
.include "snes/register_clear.inc"
.include "snes/graphics.asm"
.include "snes/joycon.asm"
.include "base_map.asm"


.zeropage
dpTmp0: .res 1, $00
dpTmp1: .res 1, $00
dpTmp2: .res 1, $00
dpTmp3: .res 1, $00
dpTmp4: .res 1, $00
dpTmp5: .res 1, $00
wJoyInput: .res 2, $0000
mBG1HOFS: .res 1, $00
sprite_x: .res 1 
sprite_y: .res 1 

SPRITE_X_INIT = $40
SPRITE_Y_INIT = $A0
SPRITE_X_MOVE = $10
SPRITE_Y_MOVE = $10

.code
; Follow set up in chapter 23 of manual
Reset:
    ; Not in manual but part of common cpu setup
    init_cpu
    
    ; Move to force blank and clear all the registers
    register_clear

    jsr setup_video

    ; Release VBlank
    lda #FULL_BRIGHT  ; Full brightness
    sta INIDISP

    ; Display Period begins now
    lda #(NMI_ON | AUTO_JOY_ON) ; enable NMI Enable and Joycon
    sta NMITIMEN

    ; init sprite
    lda #SPRITE_X_INIT
    sta sprite_x
    lda #SPRITE_Y_INIT
    sta sprite_y

    game_loop:
        ; TODO: Gen data of register to be renewed & mem to change BG & OBJ data
        ; aka Update
        ; react to input
        jsr joy_update
        wai ; Wait for NMI
jmp game_loop

joy_update:
    check_x:
        lda wJoyInput
        bit #<KEY_X
        beq check_L
        ; jsr mercilak_flip_v
    check_L:
        lda wJoyInput
        bit #<KEY_L
        beq check_R                 ; if not set (is zero) we skip 
        ; jsr scroll_the_screen_left
    check_R:
        lda wJoyInput
        bit #<KEY_R
        beq check_left              ; if not set (is zero) we skip 
        ; jsr scroll_the_screen_right

    ; Check for keys in the high byte
    check_left:
        lda wJoyInput + 1               
        bit #>KEY_LEFT              ; check for key
        beq check_up                ; if not set (is zero) we skip 
        jsr move_sprite_left
    check_up:
        lda wJoyInput + 1               
        bit #>KEY_UP
        beq check_down
        jsr move_sprite_up
    check_down:
        lda wJoyInput + 1               
        bit #>KEY_DOWN
        beq check_right
        jsr move_sprite_down
    check_right:
        lda wJoyInput + 1               
        bit #>KEY_RIGHT
        beq endjoycheck
        jsr move_sprite_right
    endjoycheck:
rts

move_sprite_left:
lda sprite_x
sec
sbc #$10
sta sprite_x
rts
move_sprite_right:
lda sprite_x
clc
adc #$10
sta sprite_x
rts
move_sprite_up:
lda sprite_y
sec
sbc #$10
sta sprite_y
rts
move_sprite_down:
lda sprite_y
clc
adc #$10
sta sprite_y
rts

VBlank:
    ; Detect Beginning of VBlank (Appendix B-3)        
    lda RDNMI; Read NMI flag
    bpl endvblank ; loop if the MSB is 0 N=0  (positive number)

    ; TODO: set data changed registers and memory
    ; TODO: transfer renewed data via OAM
    ; TODO: change data settings for BG&OAM that renew picture

    ; Constant Screen Scrolling
    ;jsr scroll_the_screen_left

    ; Update the screen scroll register
    lda mBG1HOFS
    sta BG1HOFS
    stz BG1HOFS     ; Write the position to the BG

    joycon_read wJoyInput

    jsr update_sprite_pos

    endvblank: 
rti 

setup_video:
    ; Main register settings
    ; Mode 0 is OK for now

    ; Set OAM, CGRAM Settings
    ; We're going to DMA the graphics instead of using 2121/2122
    load_palette main_screen_palette, $00, $06
    ; Have the same palette be shared with the OBJ in Mode 1
    load_palette main_screen_palette, $80, $06

    ; force Black BG by setting first color in first palette to black
    force_black_bg:
        stz CGADD
        stz CGDATA
        stz CGDATA

    ; force_white_bg:
    ;     stz CGADD
    ;     lda #$FF
    ;     sta CGDATA
    ;     sta CGDATA

    ; Make sure hscroll is 0
    stz mBG1HOFS

    ; Set VRAM Settings
    ; Transfer VRAM Data via DMA

    ; Load tile data to VRAM
    ;jsr reset_tiles

    lda #V_INC_1
    sta VMAIN ; VRAM mode word access, inc 1.
    ldx #0000
    stx VMADDL ; destination of vram

    ; Make call to load_vram
    load_the_main_graphic:
    ;load_block_to_vram main_tiles, $0000, (main_tiles_end - main_tiles)
    load_block_to_vram main_tiles, $0000, 32 * 16 * 16 * 4 / 8;  tiles * 4bpp * 16x16 / 8
		
    ;load_block_to_vram main_screen_graphic, $0000, (main_screen_graphic_end - main_screen_graphic)
    ;load_block_to_vram test_font_a_obj, $0000, $0020 ; 2 tiles, 2bpp * 8x8 / 8bits = 32 bytes
    ;load_block_to_vram font_charset, $0100, 640 ; 40 tiles, 2bpp * 8x8 / 8 bits= 
    ; load_tiles_basic_set:
    ; load_block_to_vram tiles_basic_set, $0280, 128 ; 8 tiles, 2bpp * 8x8 / 8 bits = 128
    ; load_tiles_hangman:
    ; load_block_to_vram tiles_hangman, $1000, 256 ; 2 tiles, 4bpp * 16x16 / 8 bits = 256 bytes
    ; load_tiles_cave:
    ; load_block_to_vram cave_tiles, $1100, (16 * 2 * 8 * 8 / 8) ; 16 tiles, 2bpp * 8x8 / 8 bits = 256 bytes
    ; Unsafe zone is 0800-0ff0  (Word $0400~0748)
    ; This takes up 2k of space ($400 bytes or 200 words)
    ; This is where my Tilemap is located.
    ; This is 32*28 8*8 chars or ~$400 bytes 
    ; load_tiles_font_sloppy:
    ; load_block_to_vram tiles_font_sloppy, $0A00, (64 * 2 * 8 * 8 / 8) ; 40 tiles, 2bpp * 8x8 / 8 bits= 
    ; load_tile_mercilak:
    ; load_block_to_vram tiles_sprite_mercilak, $0E00, (8 * 4 * 8 * 8 / 8) 

    ; BG2 blocks
    ; BG2_VRAM_TILE_START = $2000
    ; load_block_to_vram tiles_basic_set, BG2_VRAM_TILE_START, (8*2*8) ; num * bpp * size
    ; Load font starting at space $20
    ; load_block_to_vram tiles_font_sloppy, BG2_VRAM_TILE_START + $0100, (64*2*8) ; num * bpp * size


    ; TODO: Loop VRAM until OBJ, BG CHR, BG SC Data has been transfered

    ; TODO: Transfer OAM, CGRAM Data via DMA (2 channels)
    jsr reset_sprite_table
    jsr setup_base_tilemap
    jsr load_sprite_selector
    ; jsr oam_load_man_with_pants
    ; jsr moam_load_mercilak
    ; jsr dma_sprite_mercilak
    ; jsr dma_sprite_mercilak_high_table

    ; Register initial screen settings
    jsr register_screen_settings
rts

load_sprite_selector: 
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

update_sprite_pos:
    stz OAMADDL     
    stz OAMADDH 
    lda sprite_x
    sta OAMDATA     ; position
    lda sprite_y
    sta OAMDATA     ; position
rts

register_screen_settings:
    lda #$01 | BG1_16x16
    sta BGMODE  ; mode 1

    lda #$7C    ; Tile Map Location - set BG1 tile offset to $7C00 (Word addr) 
    sta BG1SC   ; BG1SC 

    lda #$00
    sta BG12NBA ; BG1 name base address to $0000 (word addr) (Tiles offset)

    lda #(BG1_ON | SPR_ON) ; Enable BG1 and Sprites as main screen.
    ;lda #SPR_ON ; Enable Sprites on The Main screen.
    sta TM

    lda #$FF    ; Scroll down 1 pixel (FF really 03FF 63) (add -1 in 2s complement)
    sta BG1VOFS
    sta BG1VOFS ; Set V offset Low, High, to FFFF for BG1
rts


.segment "RODATA"
main_screen_palette:
.incbin "assets/wordle.clr"
main_tiles:
.incbin "assets/wordle.pic"
main_tiles_end:

