@ main.S
@ main program for implementing an integrated light show
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global main                                                                

// ------------------------ Implementation -------------------------------
/*
  The main function first initialise the micro:bit audio function, 
  then plays Pt.1 and Pt.2 of the light show in sequence.

  Pt.1 plays for only once according to the syllabus.
  Pt.2 plays forever (generative art).
 */
.type main, %function
main:
  bl audio_init
  bl Pt_1
  bl Pt_2
.size main, .-main

// ------------------------ The End ! ------------------------------------