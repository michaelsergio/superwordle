; Inits the CPU to non-emulation mode (16 bit mode)
; With the accumulator (M) as 8 bit
; and the X/Y register (X) as 16 bit
.macro init_cpu
    clc
    xce
    rep #$10        ; X/Y 16-bit (reset P with mask)
    sep #$20        ; A 8-bit    (set P with mask)
.endmacro


; Initial Settings as described in Chapter 26 of SNES Manual
; Results in forced blank state with all registers cleared
.macro register_clear

; PPU Registers

lda #$8F  ; Forced Blank - max brightness
sta $2100

stz $2101
stz $2102
stz $2103

; 2104h gets OAM Data
; refer to page A-3 and 2-26-2

stz $2105 ; 8x8 mode 0. pg A-5
stz $2106 ; mosaic off

; BG SC base addr and size 
stz $2107
stz $2108
stz $2109
stz $210A

; Set BG char data name base addr 
stz $210B ; BG1|2
stz $210C ; BG3|4

; Must write in low high order
stz $210D
stz $210D
stz $210E
stz $210E
stz $210F
stz $210F
stz $2110
stz $2110
stz $2111
stz $2111
stz $2112
stz $2112
stz $2113
stz $2113
stz $2114
stz $2114

; Single writes

lda #$80  ; inc addr after w/r from 2119h/213Ah (the second VRAM byte)-1x1 inc
sta $2115
stz $2116
stz $2117

; 2118h VRAM Data
; 2119h VRAM Data

stz $211A

; Double writes again in low high order
stz $211B
lda #$01  ; mode7 param A: identity matrix 1 
sta $211B

stz $211C
stz $211C

stz $211D
stz $211D

stz $211E
lda #$01  ; mode7 param D: identity matrix 1 
stz $211E

stz $211F
stz $211F

stz $2120
stz $2120

; single write 
stz $2121 ; CG Addr set to 0

; 2122 IS for CG Data.

stz $2123
stz $2124
stz $2125
stz $2126
stz $2127
stz $2128
stz $2129
stz $212A
stz $212B
stz $212C
stz $212D
stz $212E
; No F in the documentation?

lda #$30  ; Color window off 
sta $2130

stz $2131

lda #$E0 ; BLACK for fixed color addition
;lda #$FF ; WHITE for fixed color addition
sta $2132

stz $2133

; CPU registers 

stz $4200 ; NMI-VBlank-flag / V/H Blank / Controller - all disabled

lda #$FF  ; Write IO set to output all FFs
sta $4201

stz $4202
stz $4203
stz $4204
stz $4205
stz $4206
stz $4207
stz $4208
stz $4209
stz $420A
stz $420B
stz $420C
stz $420D

.endmacro