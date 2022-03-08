.define ROM_NAME "SUPER WORDLE"

.zeropage
dpTmp0: .res 1, $00
dpTmp1: .res 1, $00
dpTmp2: .res 1, $00
dpTmp3: .res 1, $00
dpTmp4: .res 1, $00
dpTmp5: .res 1, $00

.code 
.include "snes/lorom128.inc"
.include "snes/snes_registers.asm"
.include "snes/register_clear.inc"
.include "snes/graphics.asm"
.include "snes/joycon.asm"
.include "base_map.asm"
.include "alpha_map.asm"
.include "kb_selector.asm"
.include "delay.asm"

.zeropage
wJoyInput: .res 2, $0000
wJoyPressed: .res 2, $0000
mBG1HOFS: .res 1, $00
joy_delay: .tag Delay

answer: .res 5, $00
random_index: .res 2, $0000


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


    ; Generate random word
    ; jsr generate_random_index


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

        ; TODO - perhaps dont allow input until after input event is consumed.

        ; Every joy_delay, do a pressed event
        delay_check joy_delay
        beq @wait ; Skip trigger if not 1
        jsr joy_pressed_update
        stz wJoyPressed      ; reset the joy buffer
        stz wJoyPressed + 1  ; reset the joy buffer (word sized)
        delay_set joy_delay, JOY_TIMER_DELAY    ; reset the timer

        jsr sprite_selector_update_pos

        @wait:
        wai ; Wait for NMI
    jmp game_loop ; Loop forever
rts 

; Ticks on frame
timer_tick:
    ; every second check inputs
    delay_tick joy_delay
rts

joy_update:
    ; Update pressed 
    lda wJoyInput
    beq @joy_update_1   ; skip on no change for easier debugging
    ora wJoyPressed
    sta wJoyPressed

    @joy_update_1:
    lda wJoyInput + 1
    beq @joy_update_done ; skip on no change for easier debugging
    ora wJoyPressed + 1
    sta wJoyPressed + 1

    @joy_update_done:
    stz wJoyInput
    stz wJoyInput + 1    ; make sure to reset the wJoyInput buffer as well.
rts

joy_pressed_update:
    check_x:
        lda wJoyPressed
        bit #<KEY_X
        beq check_L
    check_L:
        lda wJoyPressed
        bit #<KEY_L
        beq check_R                 ; if not set (is zero) we skip 
    check_R:
        lda wJoyPressed
        bit #<KEY_R
        beq check_left              ; if not set (is zero) we skip 
    ; Check for keys in the high byte
    check_left:
        lda wJoyPressed + 1               
        bit #>KEY_LEFT              ; check for key
        beq check_up                ; if not set (is zero) we skip 
        jsr sprite_selector_move_left
    check_up:
        lda wJoyPressed + 1               
        bit #>KEY_UP
        beq check_down
        jsr sprite_selector_move_up
    check_down:
        lda wJoyPressed + 1               
        bit #>KEY_DOWN
        beq check_right
        jsr sprite_selector_move_down
    check_right:
        lda wJoyPressed + 1               
        bit #>KEY_RIGHT
        beq endjoycheck
        jsr sprite_selector_move_right
    endjoycheck:
rts


; Modifies variable: random_index
; generate_random_index:
; 		; Turn index into address
; 		; multiply by 5 to get index
; 		; Go be 16 bit
; 		.a16
; 		.i16
; 		rep #$30 ; 16-bit aaccumulator/index

; 		lda #$00 ; random number from 0-477 TODO
; 		sta random_index ; store so we can do 2n + n for 5n


; 		lda random_index 
; 		asl              ; double the index
; 		clc
; 		adc random_index ; add N for 5N

; 		sta random_index ; store back to random index

; 		rep #$10
; 		sep #$20
; 		.i16
; 		.a8
; rts

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

    jsr timer_tick

    ; TODO maybe check if sprite is dirty first
    ;   instead of doing this every frame
    jsr sprite_selector_dma

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
		

    VRAM_FONT = $1000 + $100 ; offset by for ascii non-chars
    load_block_to_vram font_sloppy_transparent, VRAM_FONT, font_sloppy_transparent_end - font_sloppy_transparent

    jsr reset_sprite_table
    jsr setup_base_tilemap
    jsr setup_alpha_tilemap
    jsr sprite_selector_load
    jsr sprite_selector_init_oam ; this replaces sprite_selector_load with dma

    ; Register initial screen settings
    jsr register_screen_settings
rts


register_screen_settings:
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

    lda #$FF    ; Scroll down 1 pixel (FF really 03FF 63) (add -1 in 2s complement)
    sta BG1VOFS
    sta BG1VOFS ; Set V offset Low, High, to FFFF for BG1

    lda #$FB    ; -5
    sta BG3VOFS
    stz BG3VOFS ; 

    lda #$FC    ; -4
    sta BG3HOFS
    stz BG3HOFS ; 
rts


.segment "RODATA"
main_screen_palette:
.incbin "assets/wordle.clr"
main_tiles:
.incbin "assets/wordle.pic"
main_tiles_end:
font_sloppy_transparent:
.incbin "assets/font_sloppy_transparent.pic"
font_sloppy_transparent_end:

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

