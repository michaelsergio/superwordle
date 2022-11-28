.macro _input_on_key input, action, key, high
  .local done	    ; Use done as a local symbol
  lda input + high
  bit #key
  beq done    ; skip if key not set
  jsr action
  done:
.endmacro

.macro input_on_b input, action
  _input_on_key input, action, >KEY_B, 1
.endmacro

.macro input_on_y input, action
  _input_on_key input, action, >KEY_Y, 1
.endmacro

.macro input_on_select input, action
  _input_on_key input, action, >KEY_SELECT, 1
.endmacro

.macro input_on_start input, action
  _input_on_key input, action, >KEY_START, 1
.endmacro
.macro input_on_up input, action
  _input_on_key input, action, >KEY_UP, 1
.endmacro

.macro input_on_down input, action
  _input_on_key input, action, >KEY_DOWN, 1
.endmacro

.macro input_on_left input, action
  _input_on_key input, action, >KEY_LEFT, 1
.endmacro

.macro input_on_right input, action
  _input_on_key input, action, >KEY_RIGHT, 1
.endmacro

.macro input_on_a input, action
  _input_on_key input, action, <KEY_A, 0
.endmacro

.macro input_on_x input, action
  _input_on_key input, action, <KEY_X, 0
.endmacro

.macro input_on_l input, action
  _input_on_key input, action, <KEY_L, 0
.endmacro

.macro input_on_r input, action
  _input_on_key input, action, <KEY_R, 0
.endmacro
