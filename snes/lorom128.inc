; Sets up processor basics and ROM headers/vectors

.p816   ; 65816 processor
.i16    ; X/Y are 16 bits
.a8     ; A is 8 bits

.segment "HEADER"     ; +$7FE0 in file
    .byte ROM_NAME

.segment "ROMINFO"    ; +$7FD5 in file
    .byte $30         ; LoROM, fast-capable
    .byte 0           ; no battery RAM
    .byte $07         ; 128K ROM size
    .byte 0,0,0,0     ; 0 SRAM, 0 devid, ???, 0 version number
    .word $AAAA,$5555 ; dummy checksum and complement
                      ; The devid ??? might be country nad license code
                      ; Country might be 01 for us and 00 for japan.

; +$FE00 in file???
; Each vector is 2 byte in size in little endian
; x means unused
		; Program Begins in emulation mode at reset vector at $xFFC-D
.segment "VECTORS"
    ; Native Vector
		;     x, x, cop, brk, abort,       nmi,   x, irq
    .word 0, 0,    0,   0,     0,   VBlank,   0,   0

		; Emulation mode Vectors
		;     x, x, cop,  x, abort, nmi,   reset, irq
    .word 0, 0,    0, 0,     0,   0,   Reset,   0
.code


