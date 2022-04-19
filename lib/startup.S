.syntax unified

/*
  This function serves as the entry point when you turn on or reset your board.
  It will initialise the stack pointer and RAM, and then call your `main` function.
 */
.global Reset_Handler
.type Reset_Handler, %function
Reset_Handler:
    /*
      Constants that start with an underscore are (by convention) defined in the linker script.
      They generally relate to memory locations, which are the linkers job to resolve.

      In this case, the linker defines _stack_end and we use it as the place to start the main stack
     */
    ldr sp, =_stack_end

    @ copy over the .data parts from FLASH to RAM.
    ldr r0, =_data_start_ram     @ where to start copying data to in RAM
    ldr r1, =_data_end_ram       @ where to stop copying data to in RAM
    ldr r2, =_data_start_flash   @ where to start copying data from in FLASH

    cmp r0, r1
    bge CopyDataEnd

    CopyData:
    ldr r3, [r2], 4
    str r3, [r0], 4
    cmp r0, r1
    blt CopyData

    CopyDataEnd:

    @ call the user function entrypoint
    bl main

    /*
      Execution returns here when returning from the `main` function. We use an infinite loop to
      prevent it from trying to run whatever happens to come next in memory!
     */
    ProgramEnd:
    nop
    b ProgramEnd
.size Reset_Handler, . - Reset_Handler

/*
  This function is used as a catch-all exception handler. It is just an infinite loop.
  If your code reaches here, it did something wrong. More information might be found in
  the peripherals section (SCB -> CFSR_UFSR_BFSR_MMFSR)
 */
.global Default_Handler
Default_Handler:
    nop
    b Default_Handler
.size Default_Handler, . - Default_Handler

/*
  The vector table (B1.5.3). It must be placed at the location pointed to by the VTOR (B3.2.5)
  The VTOR defaults to 0, so we configure the linker to put the vector table there
  (via positioning the .rodata.vtable section).
 */
.section .rodata.vtable @ (r)ead-(o)nly(data), the .vtable suffix is just a way to uniquely identify this section in the linker
/* ====================  ARM Cortex-M4 Specific Interrupt Handlers  ===================== */
.word _stack_end
.word Reset_Handler
.word NonMaskableInt_Handler
.word HardFault_Handler
.word MemManage_Handler
.word BusFault_Handler
.word UsageFault_Handler
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word SVC_Handler
.word DebugMon_Handler
.word 0 @ Reserved
.word PendSV_Handler
.word SysTick_Handler
/* ========================  nrf52833 Specific Interrupt Handlers  ======================= */
.word POWER_CLOCK_IRQHandler
.word RADIO_IRQHandler
.word UARTE0_UART0_IRQHandler
.word SPIM0_SPIS0_TWIM0_TWIS0_SPI0_TWI0_IRQHandler
.word SPIM1_SPIS1_TWIM1_TWIS1_SPI1_TWI1_IRQHandler
.word NFCT_IRQHandler
.word GPIOTE_IRQHandler
.word SAADC_IRQHandler
.word TIMER0_IRQHandler
.word TIMER1_IRQHandler
.word TIMER2_IRQHandler
.word RTC0_IRQHandler
.word TEMP_IRQHandler
.word RNG_IRQHandler
.word ECB_IRQHandler
.word CCM_AAR_IRQHandler
.word WDT_IRQHandler
.word RTC1_IRQHandler
.word QDEC_IRQHandler
.word COMP_LPCOMP_IRQHandler
.word SWI0_EGU0_IRQHandler
.word SWI1_EGU1_IRQHandler
.word SWI2_EGU2_IRQHandler
.word SWI3_EGU3_IRQHandler
.word SWI4_EGU4_IRQHandler
.word SWI5_EGU5_IRQHandler
.word TIMER3_IRQHandler
.word TIMER4_IRQHandler
.word PWM0_IRQHandler
.word PDM_IRQHandler
.word 0 @ Reserved
.word 0 @ Reserved
.word MWU_IRQHandler
.word PWM1_IRQHandler
.word PWM2_IRQHandler
.word SPIM2_SPIS2_SPI2_IRQHandler
.word RTC2_IRQHandler
.word I2S_IRQHandler
.word FPU_IRQHandler
.word USBD_IRQHandler
.word UARTE1_IRQHandler
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word PWM3_IRQHandler
.word 0 @ Reserved
.word SPIM3_IRQHandler
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved
.word 0 @ Reserved

/*
  The following sets the above labels to weakly refer to the Default_Handler
  function. Weak means that if you write a function with the same name and marked
  as `.global` then yours will be used instead.
 */
.weak NonMaskableInt_Handler
.thumb_set NonMaskableInt_Handler, Default_Handler

.weak HardFault_Handler
.thumb_set HardFault_Handler, Default_Handler

.weak MemManage_Handler
.thumb_set MemManage_Handler, Default_Handler

.weak BusFault_Handler
.thumb_set BusFault_Handler, Default_Handler

.weak UsageFault_Handler
.thumb_set UsageFault_Handler, Default_Handler

.weak SVC_Handler
.thumb_set SVC_Handler, Default_Handler

.weak DebugMon_Handler
.thumb_set DebugMon_Handler, Default_Handler

.weak PendSV_Handler
.thumb_set PendSV_Handler, Default_Handler

.weak SysTick_Handler
.thumb_set SysTick_Handler, Default_Handler

.weak POWER_CLOCK_IRQHandler
.thumb_set POWER_CLOCK_IRQHandler, Default_Handler

.weak RADIO_IRQHandler
.thumb_set RADIO_IRQHandler, Default_Handler

.weak UARTE0_UART0_IRQHandler
.thumb_set UARTE0_UART0_IRQHandler, Default_Handler

.weak SPIM0_SPIS0_TWIM0_TWIS0_SPI0_TWI0_IRQHandler
.thumb_set SPIM0_SPIS0_TWIM0_TWIS0_SPI0_TWI0_IRQHandler, Default_Handler

.weak SPIM1_SPIS1_TWIM1_TWIS1_SPI1_TWI1_IRQHandler
.thumb_set SPIM1_SPIS1_TWIM1_TWIS1_SPI1_TWI1_IRQHandler, Default_Handler

.weak NFCT_IRQHandler
.thumb_set NFCT_IRQHandler, Default_Handler

.weak GPIOTE_IRQHandler
.thumb_set GPIOTE_IRQHandler, Default_Handler

.weak SAADC_IRQHandler
.thumb_set SAADC_IRQHandler, Default_Handler

.weak TIMER0_IRQHandler
.thumb_set TIMER0_IRQHandler, Default_Handler

.weak TIMER1_IRQHandler
.thumb_set TIMER1_IRQHandler, Default_Handler

.weak TIMER2_IRQHandler
.thumb_set TIMER2_IRQHandler, Default_Handler

.weak RTC0_IRQHandler
.thumb_set RTC0_IRQHandler, Default_Handler

.weak TEMP_IRQHandler
.thumb_set TEMP_IRQHandler, Default_Handler

.weak RNG_IRQHandler
.thumb_set RNG_IRQHandler, Default_Handler

.weak ECB_IRQHandler
.thumb_set ECB_IRQHandler, Default_Handler

.weak CCM_AAR_IRQHandler
.thumb_set CCM_AAR_IRQHandler, Default_Handler

.weak WDT_IRQHandler
.thumb_set WDT_IRQHandler, Default_Handler

.weak RTC1_IRQHandler
.thumb_set RTC1_IRQHandler, Default_Handler

.weak QDEC_IRQHandler
.thumb_set QDEC_IRQHandler, Default_Handler

.weak COMP_LPCOMP_IRQHandler
.thumb_set COMP_LPCOMP_IRQHandler, Default_Handler

.weak SWI0_EGU0_IRQHandler
.thumb_set SWI0_EGU0_IRQHandler, Default_Handler

.weak SWI1_EGU1_IRQHandler
.thumb_set SWI1_EGU1_IRQHandler, Default_Handler

.weak SWI2_EGU2_IRQHandler
.thumb_set SWI2_EGU2_IRQHandler, Default_Handler

.weak SWI3_EGU3_IRQHandler
.thumb_set SWI3_EGU3_IRQHandler, Default_Handler

.weak SWI4_EGU4_IRQHandler
.thumb_set SWI4_EGU4_IRQHandler, Default_Handler

.weak SWI5_EGU5_IRQHandler
.thumb_set SWI5_EGU5_IRQHandler, Default_Handler

.weak TIMER3_IRQHandler
.thumb_set TIMER3_IRQHandler, Default_Handler

.weak TIMER4_IRQHandler
.thumb_set TIMER4_IRQHandler, Default_Handler

.weak PWM0_IRQHandler
.thumb_set PWM0_IRQHandler, Default_Handler

.weak PDM_IRQHandler
.thumb_set PDM_IRQHandler, Default_Handler

.weak MWU_IRQHandler
.thumb_set MWU_IRQHandler, Default_Handler

.weak PWM1_IRQHandler
.thumb_set PWM1_IRQHandler, Default_Handler

.weak PWM2_IRQHandler
.thumb_set PWM2_IRQHandler, Default_Handler

.weak SPIM2_SPIS2_SPI2_IRQHandler
.thumb_set SPIM2_SPIS2_SPI2_IRQHandler, Default_Handler

.weak RTC2_IRQHandler
.thumb_set RTC2_IRQHandler, Default_Handler

.weak I2S_IRQHandler
.thumb_set I2S_IRQHandler, Default_Handler

.weak FPU_IRQHandler
.thumb_set FPU_IRQHandler, Default_Handler

.weak USBD_IRQHandler
.thumb_set USBD_IRQHandler, Default_Handler

.weak UARTE1_IRQHandler
.thumb_set UARTE1_IRQHandler, Default_Handler

.weak PWM3_IRQHandler
.thumb_set PWM3_IRQHandler, Default_Handler

.weak SPIM3_IRQHandler
.thumb_set SPIM3_IRQHandler, Default_Handler
