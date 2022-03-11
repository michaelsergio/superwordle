.zeropage
wJoyInput: .res 2, $0000
wJoyPressed: .res 2, $0000
mBG1HOFS: .res 1, $00
joy_delay: .tag Delay

answer: .res 5, $00
random_index: .res 2, $0000

guess_row: .res 1, $00
guess_col: .res 1, $00
pressed_queue: .res 1, $00

.code 

VRAM_MAIN_TILES = $0000
VRAM_FONT = $1000 + $100 ; offset by for ascii non-chars

GUESS_STARTING_ROW = $01 ; Should be 0 when I remove the test word
JOY_TIMER_DELAY = $0F
COL_MAX = $05
GAME_KEY_CLEAR = '!'

game_init:
    lda #GUESS_STARTING_ROW
    sta guess_row
    stz guess_col

    stz pressed_queue

    ; Generate random word
    jsr generate_random_index

    stz wJoyInput
    stz wJoyInput + 1
    stz wJoyPressed
    stz wJoyPressed + 1

    delay_set joy_delay, JOY_TIMER_DELAY
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
    ; Update the screen scroll register
    lda mBG1HOFS
    sta BG1HOFS
    stz BG1HOFS     ; Write the position to the BG

    joycon_read wJoyInput

    jsr timer_tick

    ; TODO maybe check if sprite is dirty first
    ;   instead of doing this every frame
    jsr sprite_selector_dma

    jsr pressed_queue_char_to_screen

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
rts

pressed_queue_char_to_screen:
    lda pressed_queue 
    beq @done


    @skip_bounds_check_if_clear:
    lda pressed_queue
    cmp #GAME_KEY_CLEAR
    beq @insert_col  

    @bounds_check:
    lda guess_col
    cmp #COL_MAX
    bcs @done       ; branch when > COL_MAX

    @insert_col:
    lda guess_row
    ; clc
    ; adc guess_col
    jsr alpha_map_guess_pos_with_register_a_as_x ; x now has pos
    lda guess_col
    asl         ; mult by 2 for word pos
    @loop:
    beq @store  ; Check for 0 first
        inx     ; increase x by col pos
        dea     ; dec counter
    bra @loop
    @store:
    stx VMADDL  ; store position into vram

    @clear_check:
    lda pressed_queue 
    cmp #GAME_KEY_CLEAR
    bne @is_character
    lda #' '                           ; Use an empty char
    jsr alpha_map_write_char_to_screen ; puts char in A to screen

    lda guess_col
    beq @done                          ; If col = 0, do not decrement
    dec                                ; else decrement
    sta guess_col                      ; and store
    bra @done

    @is_character:
    lda pressed_queue                  ; Use this char
    jsr alpha_map_write_char_to_screen ; puts char in A to screen

    lda guess_col
    inc
    sta guess_col

    @done:
    stz pressed_queue               ; Clear the queue
rts

game_loop:
    @loop:
        ; TODO: Gen data of register to be renewed & mem to change BG & OBJ data
        ; aka Update
        ; react to input
        jsr joy_update

        ; TODO - perhaps dont allow input until after input event is consumed.

        ; Every joy_delay, do a pressed event
        delay_check joy_delay
        beq @wait ; Skip trigger if not 1
        jsr game_joy_pressed_update
        stz wJoyPressed      ; reset the joy buffer
        stz wJoyPressed + 1  ; reset the joy buffer (word sized)
        delay_set joy_delay, JOY_TIMER_DELAY    ; reset the timer

        jsr sprite_selector_update_pos

        @wait:
        wai ; Wait for NMI
    bra @loop ; Loop forever
rts

game_joy_pressed_update:
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
        beq check_a                 ; if not set (is zero) we skip 
    check_a:
        lda wJoyPressed                
        bit #<KEY_A                 ; check for key
        beq check_b                 ; if not set (is zero) we skip 
        jsr on_clear
    ; Check for keys in the high byte
    
    check_b:
        lda wJoyPressed + 1               
        bit #>KEY_B                 ; check for key
        beq check_left              ; if not set (is zero) we skip 
        jsr on_kb_click
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