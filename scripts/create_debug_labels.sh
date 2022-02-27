#!/bin/sh
ARGC=$#
LABELS_FILE=$1
# label file should be something like program.lbl

if [ $ARGC -ne 1 ]; then
  echo "Usage: $0 program.lbl"
  exit 1
fi

echo '#SNES65816\n\n'
echo '[SYMBOL]'
awk '{print tolower(substr($2, 0, 2)) ":" tolower(substr($2, 3)), $3, "ANY",
1}' $LABELS_FILE
echo '\n[COMMENT]'
echo '\n[COMMAND]'
