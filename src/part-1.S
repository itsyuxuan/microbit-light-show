@ part-1.S
@ function library for Pt.1 light show (sound included)
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global Pt_1, frame_n_music, set_bit, clear_bit, set_DIR_row
.global set_DIR_col, set_OUT_row, clear_DIR_col, clear_OUT_row                                                  

// ------------------------ Implementation -------------------------------
/*
  This function shows sound and light effects of Pt.1 light show.
 */
.type Pt_1, %function
Pt_1:
  push {lr}
  ldr r6, =LED_Pt1 
  ldr r7, =MUSIC_Pt1
Pt_1_loop:
  bl frame_n_music  
  add r6, 100 @ a frame of LED data takes 25 * 4 = 100 bytes
  add r7, 8 @ a note of sound data takes 2 * 4 = 8 bytes
  ldr r0, [r7]
  cmp r0, 2 @ we put a word of 2 at the end of array
  beq end_Pt_1 @ end of Pt.1 light show
  b Pt_1_loop @ proceed to the next frame
end_Pt_1:
  pop {lr}
  bx lr
.size Pt_1, .-Pt_1

/*
  This function enlightens a frame of image and plays a note of music 
  using LEDs and speaker on micro:bit.
  
  Parameters
  ----------
    r6 : The LED on/off status array for the current frame. 
    r7 : The frequency-duration array for the current music note. 
  
  Returns
  -------
    None
 */
.type frame_n_music, %function
frame_n_music:
  push {lr}

init_row: 
  ldr r1, =PORT_0 @ all rows are in P0
  bl set_DIR_row @ set DIR for all the rows
  mov r4, 0 @ counter for init_col

init_col:
  @ adjust LED frame duration according to music note duration
  add r4, 1
  ldr r0, =DELAY_INDEX
  ldr r1, [r7, 4]
  mul r0, r1
  mov r1, 1000
  mul r2, r4, r1
  cmp r2, r0
  bgt end_frame

  mov r5, 1 @ counter for col_loop

col_loop:
  ldr r1, =PORT_0 @ col 1,2,3,5 are in P0
  bl set_DIR_col @ set DIR for the current col
  bl set_OUT_row @ set OUT for rows within the current col.
  bl clear_DIR_col @ clear DIR for the current col
  bl clear_OUT_row @ clear OUT for rows within the current col.

  @ loop until all the cols have been passed, and repeat the whole process continuously
  add r5, 1
  cmp r5, 6
  beq init_col 
  b col_loop 

end_frame:
  ldr r0, [r7] @ note frequency * 1000
  ldr r1, [r7, 4] @ note duration * 1000
  ldr r2, =SAMPLE_RATE @ audio sample rate
  mul r1, r2 @ note duration * 1000 * audio sample rate
  mov r3, 1000
  mul r2, r3 @ audio sample rate * 1000
  udiv r0, r2, r0 @ number of dots per period
  udiv r1, r1, r3 @ total number of dots for the current note
  bl music_note
  pop {lr}
  bx lr
.size frame_n_music, .-frame_n_music

/*
  This function sets a specific bit at an offset from a base address.
  
  Parameters
  ----------
    r1 : The base address.
    r2 : The offset.
    r3 : The bit index.
  
  Returns
  -------
    None
 */
.type set_bit, %function
set_bit:
  push {r0-r4, lr}
  mov r4, 0b1
  ldr r0, [r1, r2]
  lsl r3, r4, r3
  orr r0, r3
  str r0, [r1, r2]
  pop {r0-r4, lr}
  bx lr
.size set_bit, .-set_bit

/*
  This function clears a specific bit at an offset from a base address.
  
  Parameters
  ----------
    r1 : The base address.
    r2 : The offset.
    r3 : The bit index.
  
  Returns
  -------
    None
 */
.type clear_bit, %function
clear_bit:
  push {r0-r4, lr}
  mov r4, 0b1
  ldr r0, [r1, r2]
  lsl r3, r4, r3
  bic r0, r3
  str r0, [r1, r2]
  pop {r0-r4, lr}
  bx lr
 .size clear_bit, .-clear_bit

/*
  This function sets DIR for all the rows.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
  
  Returns
  -------
    None
 */
.type set_DIR_row, %function
set_DIR_row:
  push {r4-r5, lr}

  ldr r2, =DIR
  mov r4, 0 @ counter for set_DIR_row_loop

set_DIR_row_loop:
  mov r0, 4
  mul r0, r4
  ldr r5, =rows
  ldr r3, [r5, r0]
  bl set_bit

  add r4, 1
  cmp r4, 5
  blt set_DIR_row_loop

  pop {r4-r5, lr}
  bx lr
.size set_DIR_row, .-set_DIR_row

/*
  This function sets DIR for the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
  
  Returns
  -------
    None
 */
.type set_DIR_col, %function
set_DIR_col:
  push {r1, lr}

  @ col 4 is in P1
  cmp r5, 4
  it eq
  ldreq r1, =PORT_1 
  
  @ set DIR for the current col
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =cols
  ldr r3, [r2, r0]
  ldr r2, =DIR
  bl set_bit 

  pop {r1, lr}
  bx lr
.size set_DIR_col, .-set_DIR_col

/*
  This function clears DIR for the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
  
  Returns
  -------
    None
 */
.type clear_DIR_col, %function
clear_DIR_col:
  push {r1, lr}

  @ col 4 is in P1
  cmp r5, 4
  it eq
  ldreq r1, =PORT_1 
  
  @ set DIR for the current col
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =cols
  ldr r3, [r2, r0]
  ldr r2, =DIR
  bl clear_bit 

  pop {r1, lr}
  bx lr
.size clear_DIR_col, .-clear_DIR_col

/*
  This function sets OUT for rows within the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
    r6 : The LED on/off status array for the current frame. 
  
  Returns
  -------
    None
 */
.type set_OUT_row, %function
set_OUT_row:
  push {r4-r8, lr}
  
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =OUT

  mov r4, 0 @ counter for set_OUT_row_loop

set_OUT_row_loop:
  mov r5, 20
  mla r8, r4, r5, r0
  
  ldr r5, =rows
  mov r7, 4
  mul r7, r4
  ldr r3, [r6, r8]
  cmp r3, 1
  itt eq
  ldreq r3, [r5, r7]
  bleq set_bit

  add r4, 1
  cmp r4, 5
  blt set_OUT_row_loop

  pop {r4-r8, lr}
  bx lr
.size set_OUT_row, .-set_OUT_row

/*
  This function clears OUT for rows within the current col.
  
  Parameters
  ----------
    r1 : Port number (P0 by default).
    r5 : The counter for col_loop.
    r6 : The LED on/off status array for the current frame. 
  
  Returns
  -------
    None
 */
.type clear_OUT_row, %function
clear_OUT_row:
  push {r4-r8, lr}
  
  sub r0, r5, 1
  mov r2, 4
  mul r0, r2
  ldr r2, =OUT

  mov r4, 0 @ counter for clear_OUT_row_loop

clear_OUT_row_loop:
  mov r5, 20
  mla r8, r4, r5, r0
  
  ldr r5, =rows
  mov r7, 4
  mul r7, r4
  ldr r3, [r6, r8]
  cmp r3, 1
  itt eq
  ldreq r3, [r5, r7]
  bleq clear_bit

  add r4, 1
  cmp r4, 5
  blt clear_OUT_row_loop

  pop {r4-r8, lr}
  bx lr
.size clear_OUT_row, .-clear_OUT_row

// ------------------------ Constant & Variable --------------------------
.data                                                                 

.set PORT_0, 0x50000000
  .set ROW_1, 21
  .set ROW_2, 22
  .set ROW_3, 15
  .set ROW_4, 24
  .set ROW_5, 19
  .set COL_1, 28
  .set COL_2, 11
  .set COL_3, 31
  .set COL_5, 30

.set PORT_1, 0x50000300
  .set COL_4, 5

.set DIR, 0x514 
.set OUT, 0x504    

.set DELAY_INDEX, 0x4399 @ this constant keeps a frame as roughly 1 second 

.set SAMPLE_RATE, 48000 @ audio sample rate

cols:
  .word COL_1, COL_2, COL_3, COL_4, COL_5

rows:
  .word ROW_1, ROW_2, ROW_3, ROW_4, ROW_5

@ frequency * 1000 / duration * 1000
MUSIC_Pt1:
  .word 246940, 400
  .word 261630, 400
  .word 277180, 400
  .word 261630, 400
  .word 246940, 400
  .word 261630, 400
  .word 277180, 400
  .word 261630, 400
  .word 000000, 100
  .word 698460, 200
  .word 783990, 200
  .word 783990, 200
  .word 783990, 200
  .word 196000, 200
  .word 698460, 200
  .word 698460, 200
  .word 698460, 200
  .word 698460, 200
  .word 830610, 200
  .word 830610, 200
  .word 830610, 200
  .word 196000, 200
  .word 783990, 200
  .word 783990, 200
  .word 783990, 200
  .word 000000, 100
  .word 659250, 200
  .word 783990, 200
  .word 932330, 200
  .word 880000, 300	
  .word 783990, 200
  .word 932330, 200
  .word 987770, 200
  .word 000000, 600
  .word 783990, 200
  .word 880000, 200
  .word 783990, 200
  .word 739990, 300
  .word 493880, 200
  .word 659250, 200
  .word 554370, 300
  .word 000000, 600
  
  .word 2 @ end of array

@ 0 stands for LED off, 1 stands for LED on 
LED_Pt1:
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 1, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 1, 1, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 1, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 1, 1, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 1, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 1, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 1, 1
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 1, 0, 0, 0
  .word 1, 0, 1, 0, 0
  .word 0, 1, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 1, 0, 0, 0
  .word 1, 0, 1, 0, 0
  .word 0, 1, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 1, 0
  .word 0, 0, 1, 0, 1
  .word 0, 0, 0, 1, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 1, 0
  .word 0, 0, 1, 0, 1
  .word 0, 0, 0, 1, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 1, 0
  .word 0, 0, 1, 0, 1
  .word 0, 0, 0, 1, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 1, 0, 0, 0
  .word 1, 0, 1, 0, 0
  .word 0, 1, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 1, 0, 0, 0
  .word 1, 0, 1, 0, 0
  .word 0, 1, 0, 0, 0
  .word 0, 0, 0, 0, 0
  
  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 1, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0
  .word 1, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0
  .word 1, 1, 0, 1, 1
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0
  .word 1, 1, 0, 1, 1
  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0

  .word 0, 0, 1, 0, 0
  .word 0, 1, 1, 1, 0
  .word 1, 1, 0, 1, 1
  .word 0, 1, 1, 1, 0
  .word 0, 0, 1, 0, 0

  .word 1, 0, 1, 0, 1
  .word 0, 1, 1, 1, 0
  .word 1, 1, 0, 1, 1
  .word 0, 1, 1, 1, 0
  .word 1, 0, 1, 0, 1

  .word 1, 1, 1, 1, 1
  .word 1, 1, 1, 1, 1
  .word 1, 1, 0, 1, 1
  .word 1, 1, 1, 1, 1
  .word 1, 1, 1, 1, 1

  .word 0, 0, 0, 0, 0
  .word 0, 1, 1, 1, 0
  .word 0, 1, 0, 1, 0
  .word 0, 1, 1, 1, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0
  .word 1, 1, 0, 1, 1
  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0

  .word 0, 0, 0, 1, 0
  .word 1, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 1
  .word 0, 1, 0, 0, 0

  .word 1, 0, 0, 0, 1
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 1, 0, 0, 0, 1

  .word 0, 1, 0, 0, 0
  .word 0, 0, 1, 0, 1
  .word 0, 1, 0, 1, 0
  .word 1, 0, 1, 0, 0
  .word 0, 0, 0, 1, 0

  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0
  .word 1, 1, 0, 1, 1
  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0

  .word 0, 1, 0, 0, 0
  .word 0, 0, 1, 0, 1
  .word 0, 1, 0, 1, 0
  .word 1, 0, 1, 0, 0
  .word 0, 0, 0, 1, 0

  .word 1, 0, 0, 0, 1
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 1, 0, 0, 0, 1

  .word 0, 0, 0, 1, 0
  .word 1, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 1
  .word 0, 1, 0, 0, 0

  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0
  .word 1, 1, 0, 1, 1
  .word 0, 0, 1, 0, 0
  .word 0, 0, 1, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 0, 0, 0, 0
  .word 0, 1, 0, 1, 0
  .word 0, 1, 1, 1, 0
  .word 0, 0, 1, 0, 0
  .word 0, 0, 0, 0, 0

  .word 0, 1, 0, 1, 0
  .word 1, 1, 1, 1, 1
  .word 1, 1, 1, 1, 1
  .word 0, 1, 1, 1, 0
  .word 0, 0, 1, 0, 0
  
  .word 2 @ end of array

// ------------------------ The End ! ------------------------------------