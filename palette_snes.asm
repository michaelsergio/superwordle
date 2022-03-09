SNES_PALETTE_ADDR = $10
; SNES_PALETTE_ADDR = $0 ; Use the palette

SNES_COLOR_RED        = $7D0C   ; A Button: #eb1a1d 
SNES_COLOR_YELLOW     = $3F0B   ; B Button: #fece15 
SNES_COLOR_BLUE       = $2059   ; X Button: #0749b4
SNES_COLOR_GREEN      = $2022   ; Y Button: #008d45
SNES_COLOR_DARK_GRAY  = $CE3D   ; Button Ring: #717679 
SNES_COLOR_LIGHT_GRAY = $B556   ; Main controller: #a8aaaa 
SNES_COLOR_BLACK      = $C718   ; D-Pad: #3c3331

.macro snes_color_cg_write color
    lda #>color
    sta CGDATA
    lda #<color
    sta CGDATA
.endmacro

; This is a more classic SNES color palette based on the original controller
; src - https://www.reddit.com/r/emulation/comments/2wnzus/hex_colours_for_snes_controller/
palette_snes_colors_load_test:
    ; use default color map, replacing only colors we need
    load_palette main_screen_palette, SNES_PALETTE_ADDR, $06

    ; skip the first entry
    lda #SNES_PALETTE_ADDR + 1
    sta CGADD

    snes_color_cg_write SNES_COLOR_DARK_GRAY
    snes_color_cg_write SNES_COLOR_GREEN
    snes_color_cg_write SNES_COLOR_LIGHT_GRAY
    snes_color_cg_write SNES_COLOR_YELLOW

    lda #SNES_PALETTE_ADDR + 6
    sta CGADD

    snes_color_cg_write SNES_COLOR_RED
    snes_color_cg_write SNES_COLOR_BLUE
rts