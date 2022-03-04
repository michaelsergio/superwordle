.define ROM_NAME "SUPER WORDLE"

.include "snes/snes_registers.asm"
.include "snes/lorom128.inc"
.include "snes/register_clear.inc"
.include "snes/graphics.asm"
.include "snes/joycon.asm"
.include "base_map.asm"
.include "delay.asm"


.zeropage
dpTmp0: .res 1, $00
dpTmp1: .res 1, $00
dpTmp2: .res 1, $00
dpTmp3: .res 1, $00
dpTmp4: .res 1, $00
dpTmp5: .res 1, $00
wJoyInput: .res 2, $0000
wJoyPressed: .res 2, $0000
mBG1HOFS: .res 1, $00
sprite_x: .res 1, $00
sprite_y: .res 1, $00
joy_delay: .tag Delay

answer: .res 5, $00
random_index: .res 2, $0000


SPRITE_X_INIT = $0
SPRITE_Y_INIT = $0
SPRITE_X_MOVE = $0
SPRITE_Y_MOVE = $0

JOY_TIMER_DELAY = $0F

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

    ; Generate random word
    jsr generate_random_index


    stz wJoyInput
    stz wJoyInput + 1
    stz wJoyPressed
    stz wJoyPressed + 1

    delay_set joy_delay, JOY_TIMER_DELAY

    game_loop:
        ; TODO: Gen data of register to be renewed & mem to change BG & OBJ data
        ; aka Update
        ; react to input
        jsr joy_update

        delay_check joy_delay
        beq @wait ; Skip trigger if not 1
        jsr joy_pressed_update
        stz wJoyPressed
        stz wJoyPressed + 1  ; clear the joy buffer after
        delay_set joy_delay, JOY_TIMER_DELAY

        @wait:
        wai ; Wait for NMI
jmp game_loop

; Ticks on frame
timer_tick:
    ; every second check inputs
    delay_tick joy_delay
rts

joy_update:
    ; Update pressed 
    lda wJoyInput
    beq @joy_update_1
    ora wJoyPressed
    sta wJoyPressed

    @joy_update_1:
    lda wJoyInput + 1
    beq @joy_update_done
    ora wJoyPressed + 1
    sta wJoyPressed + 1

    @joy_update_done:
rts

joy_pressed_update:
    check_x:
        lda wJoyPressed
        bit #<KEY_X
        beq check_L
        ; jsr mercilak_flip_v
    check_L:
        lda wJoyPressed
        bit #<KEY_L
        beq check_R                 ; if not set (is zero) we skip 
        ; jsr scroll_the_screen_left
    check_R:
        lda wJoyPressed
        bit #<KEY_R
        beq check_left              ; if not set (is zero) we skip 
        ; jsr scroll_the_screen_right

    ; Check for keys in the high byte
    check_left:
        lda wJoyPressed + 1               
        bit #>KEY_LEFT              ; check for key
        beq check_up                ; if not set (is zero) we skip 
        jsr move_sprite_left
    check_up:
        lda wJoyPressed + 1               
        bit #>KEY_UP
        beq check_down
        jsr move_sprite_up
    check_down:
        lda wJoyPressed + 1               
        bit #>KEY_DOWN
        beq check_right
        jsr move_sprite_down
    check_right:
        lda wJoyPressed + 1               
        bit #>KEY_RIGHT
        beq endjoycheck
        jsr move_sprite_right
    endjoycheck:
rts


; Modifies variable: random_index
generate_random_index:
		; Turn index into address
		; multiply by 5 to get index
		; Go be 16 bit
		.a16
		.i16
		rep #$30 ; 16-bit aaccumulator/index

		lda #$00 ; random number from 0-477 TODO
		sta random_index ; store so we can do 2n + n for 5n


		lda random_index 
		asl              ; double the index
		clc
		adc random_index ; add N for 5N

		sta random_index ; store back to random index

		rep #$10
		sep #$20
		.a8
		.i16
rts

X_LIMIT = $8 ; max x-pos before next line
Y_LIMIT = $2 ; 2 

move_sprite_left:
lda sprite_x
beq @limit
dea
sta sprite_x
bra @done
@limit:
lda #X_LIMIT
sta sprite_x
jsr move_sprite_up
@done:
rts

move_sprite_right:
lda sprite_x
cmp #X_LIMIT
beq @limit
ina
sta sprite_x
bra @done
@limit:
lda #$0
sta sprite_x
jsr move_sprite_down
@done:
rts

move_sprite_up:
lda sprite_y
beq @limit
dea
sta sprite_y
bra @done
@limit:
lda #Y_LIMIT
sta sprite_y
@done:
rts

move_sprite_down:
lda sprite_y
cmp #Y_LIMIT
beq @limit
inc
sta sprite_y
bra @done
@limit:
lda #0
sta sprite_y
@done:
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

    jsr timer_tick

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
    stz OAMADDH  ; OAM $0000
    
    lda sprite_y
    asl                     ; y*2 for word size
    tay                     ; sprite_y is x index register
    ldx screen_pos_table, y ; get table row
    stx dpTmp0              ; store table row (word)

    lda sprite_x
    asl             ; sprite_x * 2 for 2 bytes pos: (x,y)
    tay
    lda (dpTmp0), y
    sta OAMDATA                 ; x position
    iny 
    lda (dpTmp0), y
    sta OAMDATA                 ; y  position
rts

SPT_X = $40
SPT_Y = $A0
SPT_W = $10
SPT_H = $10
SPT_ENTRIES = $1C ; 28 entries
SPT_Y_OFFSET_SCALE = 9


screen_pos_table:
.word screen_pos_table_0
.word screen_pos_table_1
.word screen_pos_table_2

screen_pos_table_0:
.byte SPT_X + SPT_W * 0 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 1 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 2 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 3 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 4 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 5 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 6 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 7 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 8 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 9 , SPT_Y + SPT_H * 0
screen_pos_table_1:
.byte SPT_X + SPT_W * 0 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 1 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 2 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 3 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 4 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 5 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 6 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 7 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 8 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 9 , SPT_Y + SPT_H * 1
screen_pos_table_2:
.byte SPT_X + SPT_W * 0 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 1 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 2 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 3 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 4 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 5 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 6 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 7 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 8 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 9 , SPT_Y + SPT_H * 2


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

.segment "BANK1"
common_words:
.include "words/common5_shuf_478.asm"
common_words_end:
common_word_len: .word (common_words_end - common_words)


; Define the dictionary bank
.segment "BANK2"
dict_a_o:
.include "words/dict5_a-o_5037.asm"

.segment "BANK3"
dict_p_z:
.include "words/dict5_p-z_3460.asm"

