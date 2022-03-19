.enum ctrlbit
  ctrlbit_t0 = 0 
  ctrlbit_t1
  ctrlbit_t2
  ctrlbit_unused
  ctrlbit_port01
  ctrlbit_port23
  ctrlbit_unused2
  ctrlbit_ramrom
.endenum

.enum ports
  control  = $f1 ; TIMER CONTROL, SNES REG CLEAR
  dspaddr	
  dspdata 
  ;;;;;;;;;;;;;; $f4
  spcport0
  spcport1
  spcport2
  spcport3
.endenum

.enum apu_timer
  t0div = $fa
  t1div
  t2div

  t0out
  t1out
  t2out
.endenum

; =DSP=
; index into any voice dsp reg
.enum dsp
  vol_l = 0 
  vol_r
  plo
  phi 
  srcn 
  adsr1
  adsr2
  gain 
  envx 
  outx 
.ende

.enum voice
  voice0_vol_l = 0
  voice0_vol_r
  voice0_pitch_lo
  voice0_pitch_hi
  voice0_srcn
  voice0_adsr1
  voice0_adsr2
  voice0_gain
  voice0_envx
  voice0_outx
  ; a b c d e f
  voice0_pad_a
  voice0_pad_b
  voice0_pad_c
  voice0_pad_d
  voice0_pad_e
  voice0_pad_f

  voice1_vol_l
  voice1_vol_r
  voice1_pitch_lo
  voice1_pitch_hi
  voice1_srcn
  voice1_adsr1
  voice1_adsr2
  voice1_gain 
  voice1_envx 
  voice1_outx
  ; a b c d e f
  voice1_pad_a
  voice1_pad_b
  voice1_pad_c
  voice1_pad_d
  voice1_pad_e
  voice1_pad_f

  voice2_vol_l
  voice2_vol_r
  voice2_pitch_lo
  voice2_pitch_hi
  voice2_srcn
  voice2_adsr1
  voice2_adsr2
  voice2_gain
  voice2_envx
  voice2_outx
  ; a b c d e f
  voice2_pad_a
  voice2_pad_b
  voice2_pad_c
  voice2_pad_d
  voice2_pad_e
  voice2_pad_f


  voice3_vol_l
  voice3_vol_r
  voice3_pitch_lo
  voice3_pitch_hi
  voice3_srcn
  voice3_adsr1
  voice3_adsr2
  voice3_gain
  voice3_envx
  voice3_outx
  voice3_pad_a
  voice3_pad_b
  voice3_pad_c
  voice3_pad_d
  voice3_pad_e
  voice3_pad_f

  voice4_vol_l
  voice4_vol_r
  voice4_pitch_lo
  voice4_pitch_hi
  voice4_srcn
  voice4_adsr1
  voice4_adsr2
  voice4_gain
  voice4_envx
  voice4_outx
  voice4_pad_a
  voice4_pad_b
  voice4_pad_c
  voice4_pad_d
  voice4_pad_e
  voice4_pad_f

  voice5_vol_l
  voice5_vol_r
  voice5_pitch_lo
  voice5_pitch_hi
  voice5_srcn
  voice5_adsr1
  voice5_adsr2
  voice5_gain
  voice5_envx
  voice5_outx
  voice5_pad_a
  voice5_pad_b
  voice5_pad_c
  voice5_pad_d
  voice5_pad_e
  voice5_pad_f

  voice6_vol_l
  voice6_vol_r
  voice6_pitch_lo
  voice6_pitch_hi
  voice6_srcn
  voice6_adsr1
  voice6_adsr2
  voice6_gain
  voice6_envx
  voice6_outx
  voice6_pad_a
  voice6_pad_b
  voice6_pad_c
  voice6_pad_d
  voice6_pad_e
  voice6_pad_f

  voice7_vol_l
  voice7_vol_r
  voice7_pitch_lo
  voice7_pitch_hi
  voice7_srcn
  voice7_adsr1
  voice7_adsr2
  voice7_gain
  voice7_envx
  voice7_outx
  voice7_pad_a
  voice7_pad_b
  voice7_pad_c
  voice7_pad_d
  voice7_pad_e
  voice7_pad_f
.endenum

mvol_l = $0c
mvol_r = $1c
evol_l = $2c
evol_r = $3c
kon  = $4c
koff = $5c
flg  = $6c
endx = $7c

efb = $0d

pmon = $2d
non = $3d
eon = $4d
dir = $5d
esa = $6d
edl = $7d

c0 = $0f
c1 = $1f
c2 = $2f
c3 = $3f
c4 = $4f
c5 = $5f
c6 = $6f
c7 = $7f
