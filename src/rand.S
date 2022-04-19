@ rand.S
@ function library for generating a random number in a given range
@ Written by Yuxuan Lin, 2022
.syntax unified 

// ------------------------ Module Interface -----------------------------
.global microbit_random, rng, prng, mod, delay                                                          

// ------------------------ Implementation -------------------------------
/*
  This function first produces a random seed value by nRF52833 in-built random number generator (RNG), 
  then uses the seed to generate a random number within the given range by our pseudo-random number generator (PRNG).
  
  Parameters
  ----------
    r3 : The upper range to generate a random number for. Non-negative.
  
  Returns
  -------
    r0 : The random number.
 */
.type microbit_random, %function
microbit_random:
  push {lr}
  bl rng
  bl prng
  pop {lr}
  bx lr
.size microbit_random, .-microbit_random

/*
  This function uses nRF52833 in-built RNG to generate a random seed value.
  
  Parameters
  ----------
    None

  Returns
  -------
    r0 : The seed value.
 */
.type rng, %function
rng:
  push {r3, lr}
  ldr r0, =DELAY_RNG
  ldr r1, =RNG
  mov r2, 0
  mov r3, 1
  str r3, [r1, TASKS_START]
  bl delay
  ldr r0, [r1, VALUE]
  str r2, [r1, TASKS_STOP]
  pop {r3, lr}
  bx lr
.size rng, .-rng

/*
  This function uses the input seed value to produce a random number in the range of 0 to upper range.
  The pseudo-random number generator algorithm used here is linear congruential generator (LCG).

  value = (a * seed + c) % m 
  Let a = 75, c = 74, m = 2 ^ 16 + 1 = 65537
  
  Parameters
  ----------
    r0 : The seed value.
    r3 : The upper range for generating a number.
  
  Returns
  -------
    r0 : The random number.
 */
.type prng, %function
prng:
  push {r4-r5, lr}
  ldr r4, =LCG_a
  ldr r5, =LCG_c
  mla r1, r0, r4, r5
  ldr r2, =LCG_m
  bl mod
  ldr r1, =RAND_MAX
  mul r0, r1
  udiv r1, r0, r2
  mov r2, r3
  bl mod
  pop {r4-r5, lr}
  bx lr
.size prng, .-prng

/*
  This function calculates the remainder after division.
  
  Parameters
  ----------
    r1 : The dividend.
    r2 : The divisor.
  
  Returns
  -------
    r0 : The remainder.
 */
.type mod, %function
mod:
  push {lr}
  udiv r0, r1, r2
  mls r0, r0, r2, r1
  pop {lr}
  bx lr
.size mod, .-mod

/*
  This function sets a delay.
  
  Parameters
  ----------
    r0 : The delay index.
  
  Returns
  -------
    None
 */
.type delay, %function
delay:
  push {r0-r11, lr}
delay_loop:
  subs r0, 1
  bne delay_loop
  pop {r0-r11, lr}
  bx lr
.size delay, .-delay

// ------------------------ Constant Definition --------------------------
.data

.set RNG, 0x4000D000
  .set TASKS_START, 0x000
  .set TASKS_STOP, 0x004
  .set VALUE, 0x508
 
.set DELAY_RNG, 0x1024 @ RNG needs time to generate a random number

.set LCG_a, 75
.set LCG_c, 74
.set LCG_m, 65537

.set RAND_MAX, 0x7FFF @ this constant is from Microsoft C runtime library

// ------------------------ The End ! ------------------------------------