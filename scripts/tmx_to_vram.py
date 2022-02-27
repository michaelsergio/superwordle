#!/usr/local/bin/python3
import sys

def to_line(num, hflip, vflip):
    status = (vflip << 7) | (hflip << 6)
    return ".byte ${:02X}, ${:02X}".format(status, num)

file_structure_help = """
; list of flips
; Each entry
; tile_num - byte index
; vflip, hflip, pri - OR the top three bits with tile map data

; first high byte is status
; second low byte is tile number
"""

arg1 = sys.argv[1]
filename = arg1
fp = open(filename, 'r')
lines = fp.readlines()
print(f"; Generated from {filename}")
print(file_structure_help)
for line in lines:
    print("") # Newline per each 32
    entries = line.split(',')
    for entry in entries:
        val = int(entry)
        status = val >> 28
        hflip = (status & 0x08) >> 3
        vflip = (status & 0x04) >> 2
        num = val & 0x0FFFFFFF
        #print(f"Num: {num} HFlip: {hflip} VFlip: {vflip}")
        print(to_line(num, hflip, vflip))
