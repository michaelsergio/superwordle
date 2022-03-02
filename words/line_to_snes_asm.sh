# Give a file name
#awk '{printf ".asciiz \"%s\"\n", $1}' common5_shuf_478.txt
awk '{printf ".asciiz \"%s\"\n", $1}' $1
