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
.include "snes/startup.inc"
.include "snes/graphics.asm"
.include "joycon2.asm"
.include "alpha_map.asm"
.include "kb_selector.asm"
.include "delay.asm"
.include "palette_snes.asm"
.include "input.asm"
.include "scenes/title.asm"
.include "scenes/game.asm"

.code
; Follow set up in chapter 23 of manual
Reset:
    ; Not in manual but part of common cpu setup
    startup_init_cpu
    
    ; Move to force blank and clear all the registers
    startup_clear_registers
	; cleanup a bit of memory
    startup_clear_directpage

    lda #FORCE_BLANK | FULL_BRIGHT  
    sta INIDISP

    jsr reset_sprite_table

    ; Release VBlank
    lda #FULL_BRIGHT  ; Full brightness
    sta INIDISP

    ; Display Period begins now
    lda #(NMI_ON | AUTO_JOY_ON) ; enable NMI Enable and Joycon
    sta NMITIMEN

    scene_title:
        jsr title_init

        lda #FORCE_BLANK | FULL_BRIGHT  
        sta INIDISP
        jsr title_setup_video
        lda #FULL_BRIGHT     ; Full brightness
        sta INIDISP          ; Release VBlank

        jsr title_loop


    scene_game:
        jsr game_init

        lda #FORCE_BLANK | FULL_BRIGHT  
        sta INIDISP
        jsr game_setup_video
        lda #FULL_BRIGHT     ; Full brightness
        sta INIDISP          ; Release VBlank

        jsr game_loop

	; Reset should never return
	error_fell_out_off_loop:
		bra error_fell_out_off_loop
rts 

; joy_update:
;     ; Update pressed 
;     lda wJoyInput
;     beq @joy_update_1   ; skip on no change for easier debugging
;     ora wJoyPressed
;     sta wJoyPressed
;
;     @joy_update_1:
;     lda wJoyInput + 1
;     beq @joy_update_done ; skip on no change for easier debugging
;     ora wJoyPressed + 1
;     sta wJoyPressed + 1
;
;     @joy_update_done:
;     stz wJoyInput
;     stz wJoyInput + 1    ; make sure to reset the wJoyInput buffer as well.
; rts



;; TODO Replace VBlank comparison with explicit VBlank jump table
;; Something like:
;; Scene ID | subroutine
;; Scenes::title (0) | title_vblank
;; Scenes::game  (1) | game_vblank

VBlank:
    ; Push all the registers
    php ; processor status register
    pha
    phx
    phy

    ; Detect Beginning of VBlank (Appendix B-3)        
    lda RDNMI; Read NMI flag
    bpl endvblank ; loop if the MSB is 0 N=0  (positive number)

    ; TODO: set data changed registers and memory
    ; TODO: transfer renewed data via OAM
    ; TODO: change data settings for BG&OAM that renew picture

    lda active_scene
    cmp #Scenes::title
    beq main_title_vblank
    dec 
    beq main_game_vblank
    bra endvblank

    main_title_vblank: 
    jsr title_vblank
    bra endvblank

    main_game_vblank:
    jsr game_vblank

    endvblank: 
    ply
    plx
    pla
    plp
rti 

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

