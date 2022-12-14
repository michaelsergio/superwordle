.include "countdown_timer.asm"
.include "base_map.asm"

.zeropage
wJoyInput: .res 2, $0000
; wJoyPressed: .res 2, $0000
debounce: .tag CountdownTimer

answer: .res 5, $00
active_guess: .res 5, $00
random_index: .res 2, $0000

guess_row: .res 1, $00
guess_col: .res 1, $00
pressed_queue: .res 1, $00

.code 

VRAM_MAIN_TILES = $0000
VRAM_FONT = $1000 + $100 ; offset by for ascii non-chars

GUESS_STARTING_ROW = $01 ; TODO: Should be 0 when I remove the test word
JOY_TIMER_DELAY = $08    ; 33 ms per frame, so 33 * 8 = 264ms
COL_MAX = $04
ROW_MAX = $05   ; 0-5 is 6 rows


GAME_KEY_CLEAR = '!'


game_init:
    lda #GUESS_STARTING_ROW
    sta guess_row
    stz guess_col

    stz pressed_queue

    joycon_read_joy1_init wJoyInput

    jsr mGrid_init

    jsr init_active_guess

    ; Generate random word
    jsr generate_random_index
    jsr set_answer


    countdown_init debounce
rts

init_active_guess:
    ldy #$05                ; Loop counter
    ldx #$00
    @loop:
        lda #' '
        sta active_guess, x
        inx
        dey
    bne @loop   ; Finish loop when y==0
rts

set_answer: 
    phb                 ; push old bank

    ; use the first index.
    ; TODO use the random index.
    ldx #$00                ; This is the index to use
    stx dpTmp0              ; TODO: store to mul by 6 for each word offset 5+null


    lda #^common_words   ; Switch DBR to ^common_words data bank
    pha                 ; push databank
    plb                 ; pull databank

    ldy #$05            ; Loop counter
    @loop:
        lda common_words, x
        sta answer, x
        inx
        dey
    bne @loop   ; Finish loop when y==0

    plb                 ; restore old data bank

rts

game_setup_video:
    ; Main register settings
    ; Mode 0 is OK for now
    
    ; Addresses are in words 
    clear_tilemap $6000, $800   ; tilemap for bg3
    clear_tilemap $7C00, $800   ; tilemap for bg1

    ; Set OAM, CGRAM Settings
    ; We're going to DMA the graphics instead of using 2121/2122
    load_palette main_screen_palette, $00, $06
    ; Have the same palette be shared with the OBJ in Mode 1
    load_palette main_screen_palette, $80, $06

    jsr palette_snes_colors_load_test

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
    load_block_to_vram main_tiles, VRAM_MAIN_TILES, 32 * 16 * 16 * 4 / 8;  tiles * 4bpp * 16x16 / 8
    load_block_to_vram font_sloppy_transparent, VRAM_FONT, font_sloppy_transparent_end - font_sloppy_transparent

    jsr setup_base_tilemap
    jsr alpha_map_setup_tiles
    jsr sprite_selector_init_oam ; this replaces sprite_selector_load with dma
    jsr sprite_selector_dma

    ; Register initial screen settings
    jsr game_register_screen_settings
rts


game_register_screen_settings:
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

game_vblank:
    countdown_tick debounce         ; tick the debounce

    ; joycon_read wJoyInput           ; Store joy update in input buffer
    joycon_read_joy1_blocking wJoyInput ; Store joy update in input buffer

    ; TODO: maybe check if sprite is dirty first instead of doing this every frame
    jsr sprite_selector_dma

    jsr write_active_guess_to_row   ; blit guess row to screen

    @base_dma_grid_row:
    base_dma_grid_row 0
rts

on_kb_click:
    ; Do a reverse lookup for char
    lda sprite_x    
    tax              ; use x as pos offset
    lda sprite_y
    beq @row_0
    dec 
    beq @row_1
    dec 
    beq @row_2
    bra @done        ; wtf?

    @row_0:
    cmp #LETTER_0_COUNT     
    bcs @done            ; >= CNT
    lda letters_0, x
    bra @store
    @row_1:
    cmp #LETTER_1_COUNT     
    bcs @done            ; >= CNT
    lda letters_1, x
    bra @store
    @row_2:
    lda sprite_x
    beq @enter           ; If 0, do enter
    dea
    tax                  ; Otherwise, normalize to str range
    cmp #LETTER_2_COUNT     
    bcs @do_backspace    ; >= CNT, its a backspace
    lda letters_2, x
    bra @store

    @do_backspace:
    lda #GAME_KEY_CLEAR  ; Set the backspace char
    bra @store           ; then do normal store logic

    @enter:
    jsr commit_word
    bra @done

    @store:
    sta pressed_queue     ; store the char that will eventually be drawn to screen

    @done:
rts

on_clear:
    lda #GAME_KEY_CLEAR           ; Use ! as a fake clear
    sta pressed_queue
rts


commit_word:
    jsr validate_word
    lda guess_row
    cmp #ROW_MAX
    beq @bad_commit
    @good_commit:
    inc             ; go to the next guess_row
    sta guess_row
    stz guess_col   ; reset the col back to the start

    jsr clear_guess   ; clear guess to prevent trash from being DMA'ed

    bra @done
    @bad_commit:
    @done:
rts

clear_guess:
    stz active_guess + 0
    stz active_guess + 1
    stz active_guess + 2
    stz active_guess + 3
    stz active_guess + 4
rts


validate_word:
    ; TODO fill in
rts

.macro set_vm_address_for_row
    lda guess_row
    jsr alpha_map_guess_pos_with_register_a_as_x ; x now has pos
    stx VMADDL  ; store position into vram
.endmacro


; TODO: put guessed word into memory
;       update the tilemap (DMA?) the whole column at a time
pressed_queue_char_to_screen:
    lda pressed_queue 
    beq @done


    @skip_bounds_check_if_clear:
    lda pressed_queue
    cmp #GAME_KEY_CLEAR
    beq @check_clear_key

    @bounds_check:
    lda guess_col
    cmp #COL_MAX + 1
    beq @done
    ; bcs @done       ; branch when > COL_MAX


    @check_clear_key:
    lda pressed_queue 
    cmp #GAME_KEY_CLEAR     ; Check if its the clear key
    bne @is_character       ; If not, go do char key stuff

    @check_if_col_clear:
    lda guess_col           ; Get current letter with the col
    tax                     ; Use col as index
    lda active_guess, x     ; Get the letter

    cmp #' '                ; If current letter is blank,
    bne @clear_current      ; step back first, else clear current

    @step_back:
    lda guess_col
    beq @clear_current      ; If col = 0, do not decrement
    dec                     ; else decrement
    sta guess_col           ; and store

    @clear_current:
    lda guess_col           
    tax                     ; use guess col as index for active_guess write
    lda #' '                ; Blank
    sta active_guess, x     ; Clear out current active guess character
    bra @done


    @is_character:
    lda guess_col           
    tax                     ; use guess col as index for active_guess write
    lda pressed_queue       ; Use this char
    sta active_guess, x     ; set active guess char

    lda guess_col
    inc
    sta guess_col

    @done:
    countdown_reset debounce, JOY_TIMER_DELAY  ; When an event is consumed
                                               ; disallow more input
    stz pressed_queue                          ; Clear the input queue
rts

write_active_guess_to_row:
    set_vm_address_for_row
    lda active_guess + 0
    jsr alpha_map_write_char_to_screen ; puts char in A to screen
    lda active_guess + 1
    jsr alpha_map_write_char_to_screen 
    lda active_guess + 2
    jsr alpha_map_write_char_to_screen 
    lda active_guess + 3
    jsr alpha_map_write_char_to_screen 
    lda active_guess + 4
    jsr alpha_map_write_char_to_screen 
rts

game_loop:
    @loop:
        countdown_finished debounce ; Check to see if we are accepting input 
        bne @skip_joy_check         ; If we are counting, skip the joy checks

        ;jsr joy_update

        jsr game_joy_pressed_update
        ; stz wJoyPressed      ; reset the joy buffer
        ; stz wJoyPressed + 1  ; reset the joy buffer (word sized)

        jsr pressed_queue_char_to_screen
        jsr sprite_selector_update_pos

        @skip_joy_check:

        @wait:
        wai ; Wait for NMI
    bra @loop ; Loop forever
rts

game_joy_pressed_update:
    input_on_left wJoyInput, sprite_selector_move_left
    input_on_right wJoyInput, sprite_selector_move_right
    input_on_up wJoyInput, sprite_selector_move_up
    input_on_down wJoyInput, sprite_selector_move_down
    input_on_a wJoyInput, on_clear
    input_on_b wJoyInput, on_kb_click
    ; input_on_x wJoyInput, move_sprite_right

    ; clear the input after consuming
    joycon_read_joy1_init z:wJoyInput 
rts

; Modifies variable: random_index
generate_random_index:
		; Turn index into address
		; multiply by 5 to get index
		; Go be 16 bit
		.a16
		rep #$30 ; 16-bit aaccumulator/index

		lda #$00 ; random number from 0-477 TODO HARDCODED as 0 right now
		sta random_index ; store so we can do 2n + n for 5n

		lda random_index 
		asl              ; double the index
		clc
		adc random_index ; add N for 5N

		sta random_index ; store back to random index

        lda #$00    ; clean the 16 bit A register
		rep #$10
		sep #$20
		.a8
rts
