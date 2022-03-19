; Map one of the unused auxiliary IO ports to act as a row reporter
; through the use of libgme_M. First, write the data, then activize it
; with the cmd (love making words up recently).
reportTrackerCmd  = $f8
reportTrackerArg  = $f9

.enum ReportTrackerCmd
	reportTrackerCmd_IncRow     = 0 
	reportTrackerCmd_SetRow
	reportTrackerCmd_SetPattern 
.endenum

; compress bits for patterns
CBIT  = 7
CBIT_NOTE = 0
CBIT_INSTR = 1
CBIT_VOL = 2
CBIT_FX = 3
CBIT_FXPARAM = 4
CBIT_RLE = 5
CBIT_RLE_ONLY1 = 6

; extflags (defined in .s)
.enum ExtFlags
	REPEATPATTERN = 0 
	SKIP_ECHOBUF_CLEAR
	START_FROM_PLAYHEAD
.endenum

; Generate C printouts for the Tracker app
; .PRINT "#define CBIT 0x", HEX CBIT, "\n"
; .PRINT "#define CBIT_NOTE 0x", HEX CBIT_NOTE, "\n"
; .PRINT "#define CBIT_INSTR 0x", HEX CBIT_INSTR, "\n"
; .PRINT "#define CBIT_VOL 0x", HEX CBIT_VOL, "\n"
; .PRINT "#define CBIT_FX 0x", HEX CBIT_FX, "\n"
; .PRINT "#define CBIT_FXPARAM 0x", HEX CBIT_FXPARAM, "\n"
; .PRINT "#define CBIT_RLE 0x", HEX CBIT_RLE, "\n"
; .PRINT "#define CBIT_RLE_ONLY1 0x", HEX CBIT_RLE_ONLY1, "\n"
; .PRINT "\n"
; .PRINT "#define REPORT_TRACKER_INCROW 0x", HEX reportTrackerCmd_IncRow, "\n"
; .PRINT "#define REPORT_TRACKER_SETROW 0x", HEX reportTrackerCmd_SetRow, "\n"
; .PRINT "#define REPORT_TRACKER_SETPATTERN 0x", HEX reportTrackerCmd_SetPattern, "\n"
; .PRINT "\n"
; .PRINT "#define EXTFLAGS_REPEATPATTERN 0x", HEX REPEATPATTERN, "\n"
; .PRINT "#define EXTFLAGS_SKIP_ECHOBUF_CLEAR 0x", HEX SKIP_ECHOBUF_CLEAR, "\n"
; .PRINT "#define EXTFLAGS_START_FROM_PLAYHEAD 0x", HEX START_FROM_PLAYHEAD, "\n"

; .PRINT "\n"

; We can make struct definitions that don't need to be defined in RAM,
; used purely by their definition as a way to informatically load offsets
; from RAM pointers

.struct PatternSequencer
	num_entries   .byte ;length in bytes (same as number of pattern entries)
	sequences     .byte
.endstruct 

; sequences is described to assembler as 1 byte in size but that is just to
; make it addressable. In reality, it's the size specified by num_entries.
; Each entry is just a byte specifying the pattern number 

.struct Instrument
	vol .byte
	finetune .byte
	pan .byte ; TODO
	srcn .byte
	adsr1 .byte
	adsr2 .byte
	flags .byte
	semitone_offset .byte ; TODO
.endstruct


INSTR_FLAG_ECHO = 1


; .PRINT "#define INSTR_FLAG_ECHO 0x", HEX INSTR_FLAG_ECHO, "\n"
