@ audio.S
@ audio library for the BBC micro:bit v2
@ By Benjamin Gray, 2021
@ Australian National University
.syntax unified

.global audio_init
.type audio_init, %function
audio_init:
  @ Set P0.00 (speaker) to output mode
  ldr r0, =GPIO_P0
  mov r1, 0b11
  str r1, [r0, GPIO_PX_PIN_CNF0]

  @ Configure PWM on the speaker
  ldr r0, =PWM0

  @ Up-counting only
  mov r1, 0
  str r1, [r0, PWMX_MODE]

  @ Perpetual playback bouncing between the two sequences
  ldr r1, =(0b1 << 2)
  str r1, [r0, PWMX_SHORTS]

  @ Enable interrupt on sequence start (either sequence)
  mov r1, (0b11 << 2)
  str r1, [r0, PWMX_INTEN]

  @ Set PWM period = 256 PWM_CLK cycles (62.5 kHz)
  mov r1, 255
  str r1, [r0, PWMX_COUNTERTOP]

  @ Set 16 MHz PWM clock
  mov r1, 0
  str r1, [r0, PWMX_PRESCALER]

  @ Set common layout & advance to next sample in sequence
  @ automatically based on SEQX.REFRESH
  mov r1, 0
  str r1, [r0, PWMX_DECODER]

  @ Loop the sequences
  ldr r1, =0xFFFF
  str r1, [r0, PWMX_LOOP]

  @ Set up sequence locations to first two buffers
  ldr r1, =buffers
  str r1, [r0, PWMX_SEQ0PTR]
  str r1, [r0, PWMX_SEQ1PTR]

  mov r1, BUFFER_ELEMENTS
  str r1, [r0, PWMX_SEQ0CNT]
  str r1, [r0, PWMX_SEQ1CNT]

  @ Set each sample to run for 2 PWM periods (31.25 kHz sample rate)
  ldr r1, =1
  str r1, [r0, PWMX_SEQ0REFRESH]
  str r1, [r0, PWMX_SEQ1REFRESH]

  @ Set no delay after the end of a sequence
  mov r1, 0
  str r1, [r0, PWMX_SEQ0ENDDELAY]
  str r1, [r0, PWMX_SEQ1ENDDELAY]

  @ Enable PWM0 on P0.00 (speaker)
  mov r1, 0
  str r1, [r0, PWMX_PSELOUT0]

  @ Disable PWM0 on all other channels
  mov r1, 0xFFFFFFFF
  str r1, [r0, PWMX_PSELOUT1]
  str r1, [r0, PWMX_PSELOUT2]
  str r1, [r0, PWMX_PSELOUT3]

  @ Enable interrupts
  ldr r0, =NVIC
  ldr r1, [r0, NVIC_ISER0]
  orr r1, (1 << 28)
  str r1, [r0, NVIC_ISER0]

  @ Enable PWM
  ldr r0, =PWM0
  mov r1, 1
  str r1, [r0, PWMX_ENABLE]
  str r1, [r0, PWMX_TASKS_SEQSTART0]

  @ The speaker will start running with sample values of 0
  @ Call `audio_play_sample` to start setting desired sample
  @ values. You must calculate samples at a rate of at least
  @ one sample per 2000 CPU clock cycles to keep the buffers
  @ filled.

  bx lr
.size audio_init, . - audio_init


.global PWM0_IRQHandler
.type PWM0_IRQHandler, %function
PWM0_IRQHandler:
  push {lr}

  ldr r0, =PWM0

  @ Detect which sequence started & clear event
  mov r3, 0
  ldr r1, [r0, PWMX_EVENTS_SEQSTARTED0]
  ldr r2, [r0, PWMX_EVENTS_SEQSTARTED1]
  str r3, [r0, PWMX_EVENTS_SEQSTARTED0]
  str r3, [r0, PWMX_EVENTS_SEQSTARTED1]

  @ Make r0 point directly to the correct sequence (if it wasn't
  @ SEQ0 then we assume is was SEQ1)
  cmp r1, 1
  ite eq
  addeq r0, PWMX_SEQ0PTR
  addne r0, PWMX_SEQ1PTR

  @ Get the handover buffer address
  ldr r1, =handover_buffer
  ldr r2, [r1]

  @ Mark the handover buffer as consumed
  mov r3, 0
  str r3, [r1, 4]

  @ Set the sequence to these buffer details
  str r2, [r0]

  pop {pc}
.size PWM0_IRQHandler, . - PWM0_IRQHandler


.global audio_play_sample
.type audio_play_sample, %function
audio_play_sample:
  push {lr}

  @ Mask the sample to the lowest 8 bits
  and r3, r0, 0xFF

  @ Append sample to the building buffer (always has a free spot)
  ldr r0, =building_buffer
  ldm r0, {r1, r2}
    @ r1 = building buffer address
    @ r2 = building buffer element count
  strh r3, [r1, r2, LSL 1]

  @ If the building buffer is not full, update building buffer size and return early
  add r2, 1
  cmp r2, BUFFER_ELEMENTS
  itt ne
  strne r2, [r0, 4]
  popne {pc}

  @ Set the building buffer as the handover buffer
  ldr r3, =handover_buffer

  @@ Wait for handover buffer to not be primed
  1:
  ldr r2, [r3, 4]
  cmp r2, 1
  beq 1b

  @@ Set handover buffer to current building buffer & primed
  mov r2, 1
  stm r3, {r1, r2}

  @ Set the next buffer as the building buffer
  add r1, BUFFER_SIZE
  ldr r3, =buffers_end
  cmp r1, r3
  it eq
  ldreq r1, =buffers

  @@ Set building buffer as next buffer & 0 size
  mov r2, 0
  stm r0, {r1, r2}

  pop {pc}
.size audio_play_sample, . - audio_play_sample


.data

.set BUFFER_COUNT, 3  @ must be >= 3
.set BUFFER_ELEMENTS, 8
.set BUFFER_SIZE, 2 * BUFFER_ELEMENTS


handover_buffer:
.word buffers  @ buffer address
.word 0  @ 1 if ready for consumption & not yet consumed

building_buffer:
.word (buffers + BUFFER_SIZE)  @ buffer address
.word 0  @ element offset to append to

buffers:
.rept BUFFER_COUNT
.rept BUFFER_ELEMENTS
.hword 0
.endr
.endr
buffers_end:

canary:
.word 0xABAB1234



.set GPIO_P0, 0x50000000
.set GPIO_P1, 0x50000300
  .set GPIO_PX_OUT, 0x504     @ index by pin number
  .set GPIO_PX_OUTSET, 0x508  @ index by pin number
  .set GPIO_PX_OUTCLR, 0x50C  @ index by pin number
  .set GPIO_PX_IN, 0x510      @ index by pin number
  .set GPIO_PX_DIR, 0x514     @ index by pin number
  .set GPIO_PX_DIRSET, 0x518  @ index by pin number
  .set GPIO_PX_DIRCLR, 0x51C  @ index by pin number
  .set GPIO_PX_LATCH, 0x520   @ index by pin number
  .set GPIO_PX_DETECTMODE, 0x524
  .set GPIO_PX_PIN_CNF0, 0x700
  .set GPIO_PX_PIN_CNF1, 0x704
  .set GPIO_PX_PIN_CNF2, 0x708
  .set GPIO_PX_PIN_CNF3, 0x70C
  .set GPIO_PX_PIN_CNF4, 0x710
  .set GPIO_PX_PIN_CNF5, 0x714
  .set GPIO_PX_PIN_CNF6, 0x718
  .set GPIO_PX_PIN_CNF7, 0x71C
  .set GPIO_PX_PIN_CNF8, 0x720
  .set GPIO_PX_PIN_CNF9, 0x724
  .set GPIO_PX_PIN_CNF10, 0x728
  .set GPIO_PX_PIN_CNF11, 0x72C
  .set GPIO_PX_PIN_CNF12, 0x730
  .set GPIO_PX_PIN_CNF13, 0x734
  .set GPIO_PX_PIN_CNF14, 0x738
  .set GPIO_PX_PIN_CNF15, 0x73C
  .set GPIO_PX_PIN_CNF16, 0x740
  .set GPIO_PX_PIN_CNF17, 0x744
  .set GPIO_PX_PIN_CNF18, 0x748
  .set GPIO_PX_PIN_CNF19, 0x74C
  .set GPIO_PX_PIN_CNF20, 0x750
  .set GPIO_PX_PIN_CNF21, 0x754
  .set GPIO_PX_PIN_CNF22, 0x758
  .set GPIO_PX_PIN_CNF23, 0x75C
  .set GPIO_PX_PIN_CNF24, 0x760
  .set GPIO_PX_PIN_CNF25, 0x764
  .set GPIO_PX_PIN_CNF26, 0x768
  .set GPIO_PX_PIN_CNF27, 0x76C
  .set GPIO_PX_PIN_CNF28, 0x770
  .set GPIO_PX_PIN_CNF29, 0x774
  .set GPIO_PX_PIN_CNF30, 0x778
  .set GPIO_PX_PIN_CNF31, 0x77C
    .set GPIO_PX_PIN_CNFX_DIR, 0     @ 0: input, 1: output
    .set GPIO_PX_PIN_CNFX_INPUT, 1   @ 0: connect, 1: disconnect input buffer
    .set GPIO_PX_PIN_CNFX_PULL, 2    @ [2] 0: no pull, 1: pull down, 3: pull up
    .set GPIO_PX_PIN_CNFX_DRIVE, 8   @ [3]
    .set GPIO_PX_PIN_CNFX_SENSE, 16  @ [2]

.set I2S, 0x40025000
  .set I2S_TASKS_START, 0x000
  .set I2S_TASKS_STOP, 0x004
  .set I2S_EVENTS_RXPTRUPD, 0x104
  .set I2S_EVENTS_STOPPED, 0x108
  .set I2S_EVENTS_TXPRRUPD, 0x114
  .set I2S_INTEN, 0x300
    .set I2S_INTEN_RXPTRUPD, 1
    .set I2S_INTEN_STOPPED, 2
    .set I2S_INTEN_TXPTRUPD, 5
  .set I2S_INTENSET, 0x304
    .set I2S_INTENSET_RXPTRUPD, 1
    .set I2S_INTENSET_STOPPED, 2
    .set I2S_INTENSET_TXPTRUPD, 5
  .set I2S_INTENCLR, 0x308
    .set I2S_INTENCLR_RXPTRUPD, 1
    .set I2S_INTENCLR_STOPPED, 2
    .set I2S_INTENCLR_TXPTRUPD, 5
  .set I2S_ENABLE, 0x500
  .set I2S_CONFIG_MODE, 0x504
  .set I2S_CONFIG_RXEN, 0x508
  .set I2S_CONFIG_TXEN, 0x50C
  .set I2S_CONFIG_MCKEN, 0x510
  .set I2S_CONFIG_MCKFREQ, 0x514
    .set I2S_CONFIG_MCKFREQ_32MDIV8, 0x20000000
    .set I2S_CONFIG_MCKFREQ_32MDIV10, 0x18000000
    .set I2S_CONFIG_MCKFREQ_32MDIV11, 0x16000000
    .set I2S_CONFIG_MCKFREQ_32MDIV15, 0x11000000
    .set I2S_CONFIG_MCKFREQ_32MDIV16, 0x10000000
    .set I2S_CONFIG_MCKFREQ_32MDIV21, 0x0C000000
    .set I2S_CONFIG_MCKFREQ_32MDIV23, 0x0B000000
    .set I2S_CONFIG_MCKFREQ_32MDIV30, 0x08800000
    .set I2S_CONFIG_MCKFREQ_32MDIV31, 0x08400000
    .set I2S_CONFIG_MCKFREQ_32MDIV32, 0x08000000
    .set I2S_CONFIG_MCKFREQ_32MDIV42, 0x06000000
    .set I2S_CONFIG_MCKFREQ_32MDIV63, 0x04100000
    .set I2S_CONFIG_MCKFREQ_32MDIV125, 0x020C0000
  .set I2S_CONFIG_RATIO, 0x518
    .set I2S_CONFIG_RATIO_32X, 0
    .set I2S_CONFIG_RATIO_48X, 1
    .set I2S_CONFIG_RATIO_64X, 2
    .set I2S_CONFIG_RATIO_96X, 3
    .set I2S_CONFIG_RATIO_128X, 4
    .set I2S_CONFIG_RATIO_192X, 5
    .set I2S_CONFIG_RATIO_256X, 6
    .set I2S_CONFIG_RATIO_384X, 7
    .set I2S_CONFIG_RATIO_512X, 8
  .set I2S_CONFIG_SWIDTH, 0x51C
    .set I2S_CONFIG_SWIDTH_8BIT, 0
    .set I2S_CONFIG_SWIDTH_16BIT, 1
    .set I2S_CONFIG_SWIDTH_24BIT, 2
  .set I2S_CONFIG_ALIGN, 0x520
  .set I2S_CONFIG_FORMAT, 0x524
  .set I2S_CONFIG_CHANNELS, 0x528
    .set I2S_CONFIG_CHANNELS_STEREO, 0
    .set I2S_CONFIG_CHANNELS_LEFT, 1
    .set I2S_CONFIG_CHANNELS_RIGHT, 2
  .set I2S_RXD_PTR, 0x538
  .set I2S_TXD_PTR, 0x540
  .set I2S_RXTXD_MAXCNT, 0x550
  .set I2S_PSEL_MCK, 0x560
    .set I2S_PSEL_MCK_PIN, 0  @ [5] value: 0..31
    .set I2S_PSEL_MCK_PORT, 5
    .set I2S_PSEL_MCK_CONNECT, 31
  .set I2S_PSEL_SCK, 0x564
    .set I2S_PSEL_SCK_PIN, 0  @ [5] value: 0..31
    .set I2S_PSEL_SCK_PORT, 5
    .set I2S_PSEL_SCK_CONNECT, 31
  .set I2S_PSEL_LRCK, 0x568
    .set I2S_PSEL_LRCK_PIN, 0  @ [5] value: 0..31
    .set I2S_PSEL_LRCK_PORT, 5
    .set I2S_PSEL_LRCK_CONNECT, 31
  .set I2S_PSEL_SDIN, 0x56C
    .set I2S_PSEL_SDIN_PIN, 0  @ [5] value: 0..31
    .set I2S_PSEL_SDIN_PORT, 5
    .set I2S_PSEL_SDIN_CONNECT, 31
  .set I2S_PSEL_SDOUT, 0x570
    .set I2S_PSEL_SDOUT_PIN, 0  @ [5] value: 0..31
    .set I2S_PSEL_SDOUT_PORT, 5
    .set I2S_PSEL_SDOUT_CONNECT, 31

.set RNG, 0x4000D000
  .set RNG_TASKS_START, 0x000
  .set RNG_TASKS_STOP, 0x004
  .set RNG_EVENTS_VALREADY, 0x100
  .set RNG_SHORTS, 0x200
    .set RNG_SHORTS_VALRDY_STOP, 0
  .set RNG_INTENSET, 0x304
    .set RNG_INTENSET_VALRDY, 0
  .set RNG_INTENCLR, 0x308
    .set RNG_INTENCLR_VALRDY, 0
  .set RNG_CONFIG, 0x504
    .set RNG_CONFIG_DERCEN, 0
  .set RNG_VALUE, 0x508

.set TIMER0, 0x40008000
.set TIMER1, 0x40009000
.set TIMER2, 0x4000A000
.set TIMER3, 0x4001A000
.set TIMER4, 0x4001B000
  .set TIMERX_TASKS_START, 0x000
  .set TIMERX_TASKS_STOP, 0x004
  .set TIMERX_TASKS_COUNT, 0x008
  .set TIMERX_TASKS_CLEAR, 0x00C
  .set TIMERX_TASKS_SHUTDOWN, 0x010
  .set TIMERX_TASKS_CAPTURE0, 0x040
  .set TIMERX_TASKS_CAPTURE1, 0x044
  .set TIMERX_TASKS_CAPTURE2, 0x048
  .set TIMERX_TASKS_CAPTURE3, 0x04C
  .set TIMERX_TASKS_CAPTURE4, 0x050
  .set TIMERX_TASKS_CAPTURE5, 0x054
  .set TIMERX_EVENTS_COMPARE0, 0x140
  .set TIMERX_EVENTS_COMPARE1, 0x144
  .set TIMERX_EVENTS_COMPARE2, 0x148
  .set TIMERX_EVENTS_COMPARE3, 0x14C
  .set TIMERX_EVENTS_COMPARE4, 0x150
  .set TIMERX_EVENTS_COMPARE5, 0x154
  .set TIMERX_SHORTS, 0x200
  .set TIMERX_INTENSET, 0x304
    .set TIMERX_INTENSET_COMPARE0, 16
    .set TIMERX_INTENSET_COMPARE1, 17
    .set TIMERX_INTENSET_COMPARE2, 18
    .set TIMERX_INTENSET_COMPARE3, 19
    .set TIMERX_INTENSET_COMPARE4, 20
    .set TIMERX_INTENSET_COMPARE5, 21
  .set TIMERX_INTENCLR, 0x308
  .set TIMERX_MODE, 0x504
  .set TIMERX_BITMODE, 0x508
    .set TIMERX_BITMODE_16BIT, 0
    .set TIMERX_BITMODE_8BIT, 1
    .set TIMERX_BITMODE_24BIT, 2
    .set TIMERX_BITMODE_32BIT, 3
  .set TIMERX_PRESCALER, 0x510
  .set TIMERX_CC0, 0x540
  .set TIMERX_CC1, 0x544
  .set TIMERX_CC2, 0x548
  .set TIMERX_CC3, 0x54C
  .set TIMERX_CC4, 0x550
  .set TIMERX_CC5, 0x554

.set NVIC, 0xE000E100
  .set NVIC_ISER0, 0x000
  .set NVIC_ICER0, 0x080
  .set NVIC_ISPR0, 0x100
  .set NVIC_ICPR0, 0x180
  .set NVIC_IABR0, 0x200
  .set NVIC_IPR0, 0x300

.set PWM0, 0x4001C000
.set PWM1, 0x40021000
.set PWM2, 0x40022000
.set PWM3, 0x4002D000
  .set PWMX_TASKS_STOP, 0x004
  .set PWMX_TASKS_SEQSTART0, 0x008
  .set PWMX_TASKS_SEQSTART1, 0x00C
  .set PWMX_TASKS_NEXTSTEP, 0x010
  .set PWMX_EVENTS_STOPPED, 0x104
  .set PWMX_EVENTS_SEQSTARTED0, 0x108
  .set PWMX_EVENTS_SEQSTARTED1, 0x10C
  .set PWMX_EVENTS_SEQEND0, 0x110
  .set PWMX_EVENTS_SEQEND1, 0x114
  .set PWMX_EVENTS_PWMPERIODEND, 0x118
  .set PWMX_EVENTS_LOOPDONE, 0x11C
  .set PWMX_SHORTS, 0x200
  .set PWMX_INTEN, 0x300
  .set PWMX_INTENSET, 0x304
  .set PWMX_INTENCLR, 0x308
  .set PWMX_ENABLE, 0x500
  .set PWMX_MODE, 0x504
  .set PWMX_COUNTERTOP, 0x508
  .set PWMX_PRESCALER, 0x50C
  .set PWMX_DECODER, 0x510
  .set PWMX_LOOP, 0x514
  .set PWMX_SEQ0PTR, 0x520
  .set PWMX_SEQ0CNT, 0x524
  .set PWMX_SEQ0REFRESH, 0x528
  .set PWMX_SEQ0ENDDELAY, 0x52C
  .set PWMX_SEQ1PTR, 0x540
  .set PWMX_SEQ1CNT, 0x544
  .set PWMX_SEQ1REFRESH, 0x548
  .set PWMX_SEQ1ENDDELAY, 0x54C
  .set PWMX_PSELOUT0, 0x560
  .set PWMX_PSELOUT1, 0x564
  .set PWMX_PSELOUT2, 0x568
  .set PWMX_PSELOUT3, 0x56C