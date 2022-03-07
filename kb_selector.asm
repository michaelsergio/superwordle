.include "sprite_selector.asm"

SPT_X = $40
SPT_Y = $A0
SPT_W = $10
SPT_H = $10
SPT_ENTRIES = $1C ; 28 entries
SPT_Y_OFFSET_SCALE = 9


kb_selector_pos_table:
.word kb_selector_pos_table_0
.word kb_selector_pos_table_1
.word kb_selector_pos_table_2

kb_selector_pos_table_0:
.byte SPT_X + SPT_W * 0 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 1 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 2 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 3 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 4 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 5 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 6 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 7 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 8 , SPT_Y + SPT_H * 0
.byte SPT_X + SPT_W * 9 , SPT_Y + SPT_H * 0
kb_selector_pos_table_1:
.byte SPT_X + SPT_W * 0 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 1 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 2 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 3 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 4 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 5 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 6 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 7 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 8 , SPT_Y + SPT_H * 1
.byte SPT_X + SPT_W * 9 , SPT_Y + SPT_H * 1
kb_selector_pos_table_2:
.byte SPT_X + SPT_W * 0 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 1 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 2 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 3 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 4 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 5 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 6 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 7 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 8 , SPT_Y + SPT_H * 2
.byte SPT_X + SPT_W * 9 , SPT_Y + SPT_H * 2

