@ part-2.S
@ function library for Pt.2 light show (sound included)
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global Pt_2, generate_next_frame, frame_n_bytebeat

// ------------------------ Implementation -------------------------------
/*
  This function shows sound and light effects of Pt.2 light show.
 */
.type Pt_2, %function
Pt_2:
  push {lr}
  ldr r6, =LED_INIT @ initial LED status data array
  mov r8, 0 @ byte beat parameter
Pt_2_loop:
  bl generate_next_frame 
  bl frame_n_bytebeat  
  b Pt_2_loop 
  pop {lr}
  bx lr
.size Pt_2, .-Pt_2

/*
  This function generates the next frame with randomness.
  
  Parameters
  ----------
    r6 : The previous frame. 
  
  Returns
  -------
    r6 : The next frame to be enlightened.
 */
.type generate_next_frame, %function
generate_next_frame:
  push {lr}
  mov r4, 0 @ counter for cols

shift_down_col_by_col:
  mov r5, 3 @ descending counter for shift_down_loop

shift_down_loop:
  @ start from the last row,
  @ shift the previous row value into the current row 
  mov r0, 20
  mov r1, 4
  mul r2, r0, r5
  mul r3, r1, r4
  add r3, r2
  ldr r0, [r6, r3] 
  add r3, 20
  str r0, [r6, r3]

  cmp r5, 0
  itt ne
  subne r5, 1
  bne shift_down_loop

  @ generate a random number to r0 within the range of 0 ~ 9 (inclusive)
  mov r3, 10 
  bl microbit_random
  
  @ if the random number is within [5, 6, 7, 8, 9] then set r1 value to 0
  @ if the random number is within [0, 1, 2, 3, 4] then set r1 value to 1
  cmp r0, 4
  ite gt
  movgt r1, 0
  movle r1, 1

  @ calculate the offset of 1st row in this col
  mov r0, 4
  mul r3, r0, r4

  @ set the first row of this col to r1 value
  str r1, [r6, r3]

  add r4, 1
  cmp r4, 5
  bne shift_down_col_by_col

  pop {lr}
  bx lr
.size generate_next_frame, .-generate_next_frame

/*
  This function enlightens a frame of image and plays bytebeat music 
  using LEDs and speaker on micro:bit.
  
  Parameters
  ----------
    r6 : The LED on/off status array for the current frame. 
  
  Returns
  -------
    None
 */
.type frame_n_bytebeat, %function
frame_n_bytebeat:
  push {lr}

init_row: 
  ldr r1, =PORT_0 @ all rows are in P0
  bl set_DIR_row @ set DIR for all the rows
  mov r4, 0 @ counter for init_col

init_col:
  @ keep the time of a frame constant
  ldr r2, =DELAY_INDEX
  add r4, 1
  cmp r4, r2
  bgt end_frame

  mov r5, 1 @ counter for col_loop

col_loop:
  ldr r1, =PORT_0 @ col 1,2,3,5 are in P0
  bl set_DIR_col @ set DIR for the current col
  bl set_OUT_row @ set OUT for rows within the current col.
  bl clear_DIR_col @ clear DIR for the current col
  bl clear_OUT_row @ clear OUT for rows within the current col.
  
  bl bytebeat @ play the bytebeat

  @ loop until all the cols have been passed, and repeat the whole process continuously
  add r5, 1
  cmp r5, 6
  beq init_col 
  b col_loop 

end_frame:
  pop {lr}
  bx lr
.size frame_n_bytebeat, .-frame_n_bytebeat

// ------------------------ Constant & Variable --------------------------
.data

.set PORT_0, 0x50000000

.set DELAY_INDEX, 0x1024 @ this constant keeps frame time consistent 

@ initial LED status
LED_INIT:
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0
  .word 0, 0, 0, 0, 0

// ------------------------ The End ! ------------------------------------