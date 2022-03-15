# Give a file name
#awk '{printf ".asciiz \"%s\"\n", toupper($1)}' common5_shuf_478.txt
awk '{printf ".asciiz \"%s\"\n", toupper($1)}' $1
