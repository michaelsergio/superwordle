# Makefile reminders 
# $< First Dependecy
# $@ Target Name

TOOLS:=~/code/snes/tools
PCX2SNES:=pcx2snes/pcx2snes
SNES=$(TOOLS)/bsnes-plus/bsnes+.app/Contents/MacOS/bsnes

PROGRAM:=wordle
SOURCES:=main.asm
MORE_SOURCES:=$(wildcard **/*.asm)
LD_CONFIGS:= snes/lorom128.cfg
BIN_DIR:=bin

OUTPUTS := $(SOURCES:.asm=.o)
OUTPUTS_BIN := $(OUTPUTS:%=bin/%)

EXECUTABLE := $(BIN_DIR)/$(PROGRAM).smc

all: build $(EXECUTABLE) debuglabels

build: 
	@mkdir -p $(BIN_DIR)
	touch $(BIN_DIR)

$(EXECUTABLE): $(OUTPUTS_BIN)
	ld65 -Ln $(BIN_DIR)/$(PROGRAM).lbl -m $(BIN_DIR)/$(PROGRAM).map -C $(LD_CONFIGS) -o $@ $^

$(BIN_DIR)/%.o: $(SOURCES) $(MORE_SOURCES)
	ca65 -g $< -o $@

# Just the code output cleanup
.PHONY: clean
clean: 
	rm -rf *.smc *.o *.lbl *.map *.sym $(BIN_DIR)

.PHONY: run
run: 
	$(SNES) $(EXECUTABLE)

debuglabels: $(BIN_DIR)/$(PROGRAM).lbl
	$(shell scripts/create_debug_labels.sh $< > $(BIN_DIR)/$(PROGRAM).cpu.sym)
