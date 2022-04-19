@ music.S
@ function library for different kinds of music
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global music_note, bytebeat                                              

// ------------------------ Implementation -------------------------------
/*
  This function plays a single note of music.
  
  Parameters
  ----------
    r0 : The number of dots per period.
    r1 : The total number of dots for the current note.
  
  Returns
  -------
    None
 */
.type music_note, %function
music_note:
  push {r0-r11, lr}

  @ r6 : number of dots per half-period
  @ r7 : total number of dots for the current note
  @ r8 : counter for total dots which have been played in the note
  mov r2, 2
  udiv r6, r0, r2 
  mov r7, r1
  mov r8, 0

period_loop:
  mov r1, 0 @ counter for positive_amplitude dots in a period
  mov r2, 0 @ counter for negative_amplitude dots in a period

positive_amplitude_loop:
  ldr r0, =UPPER_AMPLITUDE

  push {r1-r2, lr}
  bl audio_play_sample
  pop {r1-r2, lr}

  @ when all the dots in a note are played, proceed to the next note
  add r8, 1
  cmp r8, r7
  bge end_music_note

  @ repeat to generate positive_amplitude square wave, 
  @ until all dots for first half of a period have been played
  add r1, 1
  cmp r1, r6
  blt positive_amplitude_loop

negative_amplitude_loop:
  ldr r0, =LOWER_AMPLITUDE

  push {r1-r2, lr}
  bl audio_play_sample
  pop {r1-r2, lr}

  @ when all the dots in a note are played, proceed to the next note
  add r8, 1
  cmp r8, r7
  bge end_music_note

  @ repeat to generate negative_amplitude square wave, 
  @ until all dots for second half of a period have been played
  add r2, 1
  cmp r2, r6
  blt negative_amplitude_loop
  
  @ loop sound periods
  b period_loop

end_music_note:
  pop {r0-r11, lr}
  bx lr
.size music_note, .-music_note

/*
  This function uses the following expression to produce a loop of bytebeat music sound.
  
  t >> 8 & t * 50 | t >> 4
  
  Parameters
  ----------
    r8 : The counter for bytebeat music loops.
  
  Returns
  -------
    None
 */
.type bytebeat, %function
bytebeat:
  push {r0-r3, lr}
  add r8, 1
  mov r1, 8
  lsr r1, r8, r1
  mov r2, 50
  mul r2, r8
  mov r3, 4
  lsr r3, r8, r3
  and r0, r1, r2
  orr r0, r0, r3
  bl audio_play_sample
  pop {r0-r3, lr}     
  bx lr
.size bytebeat, .-bytebeat

// ------------------------ Constant Definition --------------------------
.data

.set UPPER_AMPLITUDE, 0x7FFF @ sound upper amplitude
.set LOWER_AMPLITUDE, 0x8000 @ sound lower amplitude

// ------------------------ The End ! ------------------------------------