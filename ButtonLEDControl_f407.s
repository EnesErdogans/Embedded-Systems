        ;==============================================================
        ; STM32F407G-DISC1 (Cortex-M4, ARM/Thumb, Keil armasm)
        ; Button: PA0 (active-high, pull-down)
        ; LEDs  : PD12..PD15
        ; Short press  -> toggle all LEDs
        ; Long  press  -> blink once (all LEDs)
        ;==============================================================
        PRESERVE8
        THUMB

        EXPORT  __main

;-------------------------------
; Base addresses (F4)
;-------------------------------
RCC_BASE        EQU     0x40023800
RCC_AHB1ENR     EQU     (RCC_BASE + 0x30)

GPIOA_BASE      EQU     0x40020000
GPIOA_MODER     EQU     (GPIOA_BASE + 0x00)
GPIOA_PUPDR     EQU     (GPIOA_BASE + 0x0C)
GPIOA_IDR       EQU     (GPIOA_BASE + 0x10)

GPIOD_BASE      EQU     0x40020C00
GPIOD_MODER     EQU     (GPIOD_BASE + 0x00)
GPIOD_ODR       EQU     (GPIOD_BASE + 0x14)
GPIOD_BSRR      EQU     (GPIOD_BASE + 0x18)

; RCC AHB1 enable bits
GPIOAEN_BIT     EQU     (1 << 0)
GPIODEN_BIT     EQU     (1 << 3)

; Pins / masks
PIN_BTN_PA0     EQU     (1 << 0)                  ; PA0
LEDS_MASK_PD    EQU     ((1<<12)|(1<<13)|(1<<14)|(1<<15)) ; PD12..15

; Timing constants (gözle ayarla)
DEBOUNCE_LOOPS  EQU     60000          ; ~30 ms
BLINK_DELAY     EQU     300000         ; ~150 ms
LONG_PRESS_THR  EQU     1200000        ; ~600 ms

        AREA    |.text|, CODE, READONLY

;---------------------------------------------------
; __main: giris noktasi (Reset_Handler buraya dallanacak)
;   - RCC saatlerini aç
;   - GPIO konfigürasyonu yap
;   - Döngü: kisa/uzun basis algila, LED kontrol
;---------------------------------------------------
__main          PROC
        PUSH    {LR}

        ; ---- Clocks: GPIOA & GPIOD enable ----
        LDR     R0, =RCC_AHB1ENR
        LDR     R1, [R0]
        LDR     R2, =GPIOAEN_BIT
        ORR     R1, R1, R2
        LDR     R2, =GPIODEN_BIT
        ORR     R1, R1, R2
        STR     R1, [R0]

        ; ---- PA0 input + pull-down ----
        ; MODER: pin0 = 00
        LDR     R0, =GPIOA_MODER
        LDR     R1, [R0]
        BIC     R1, R1, #(0x3)                ; clear [1:0]
        STR     R1, [R0]
        ; PUPDR: pin0 = 10 (pull-down)
        LDR     R0, =GPIOA_PUPDR
        LDR     R1, [R0]
        BIC     R1, R1, #(0x3)
        ORR     R1, R1, #(0x2)
        STR     R1, [R0]

        ; ---- PD12..PD15 output (01) ----
        LDR     R0, =GPIOD_MODER
        LDR     R1, [R0]
        LDR     R2, =0xFF000000              ; clear bits 24..31
        BIC     R1, R1, R2
        ORR     R1, R1, #(1 << 24)           ; PD12 -> 01
        ORR     R1, R1, #(1 << 26)           ; PD13 -> 01
        ORR     R1, R1, #(1 << 28)           ; PD14 -> 01
        ORR     R1, R1, #(1 << 30)           ; PD15 -> 01
        STR     R1, [R0]

        ; LEDs OFF
        BL      leds_off

main_loop
        ; read PA0
        LDR     R0, =GPIOA_IDR
        LDR     R1, [R0]
        TST     R1, #PIN_BTN_PA0
        BEQ     main_loop                    ; basili degil

        ; debounce + dogrula
        BL      debounce
        LDR     R1, [R0]
        TST     R1, #PIN_BTN_PA0
        BEQ     main_loop

        ; hold süresini say
        MOVS    R2, #0
hold_loop
        LDR     R1, [R0]
        TST     R1, #PIN_BTN_PA0
        BEQ     decide_action
        ADDS    R2, R2, #1
        ; küçük bekleme (ölçekleme)
        MOVS    R3, #200
pace:   SUBS    R3, R3, #1
        BNE     pace
        B       hold_loop

decide_action
        LDR     R3, =LONG_PRESS_THR
        CMP     R2, R3
        BHS     long_press

        ; short press -> toggle
        BL      toggle_leds
        B       wait_release

long_press
        ; long press -> blink once
        BL      blink_once

wait_release
        ; tam birakilana dek bekle
        LDR     R0, =GPIOA_IDR
rel:    LDR     R1, [R0]
        TST     R1, #PIN_BTN_PA0
        BNE     rel
        B       main_loop
        POP     {LR}
        BX      LR
        ENDP

;---------------------------------------------------
; Yardimcilar
;---------------------------------------------------
delay_loops     PROC        ; R0 = loop
        PUSH    {R1,LR}
1       SUBS    R0, R0, #1
        BNE     1b
        POP     {R1,LR}
        BX      LR
        ENDP

debounce        PROC
        PUSH    {LR}
        LDR     R0, =DEBOUNCE_LOOPS
        BL      delay_loops
        POP     {LR}
        BX      LR
        ENDP

delay_ms_like   PROC
        PUSH    {LR}
        LDR     R0, =BLINK_DELAY
        BL      delay_loops
        POP     {LR}
        BX      LR
        ENDP

leds_on         PROC
        PUSH    {R0-R1,LR}
        LDR     R0, =GPIOD_BSRR
        LDR     R1, =LEDS_MASK_PD            ; set
        STR     R1, [R0]
        POP     {R0-R1,LR}
        BX      LR
        ENDP

leds_off        PROC
        PUSH    {R0-R1,LR}
        LDR     R0, =GPIOD_BSRR
        LDR     R1, =LEDS_MASK_PD
        LSL     R1, R1, #16                  ; reset
        STR     R1, [R0]
        POP     {R0-R1,LR}
        BX      LR
        ENDP

toggle_leds     PROC
        PUSH    {R0-R2,LR}
        LDR     R0, =GPIOD_ODR
        LDR     R1, [R0]
        LDR     R2, =LEDS_MASK_PD
        EOR     R1, R1, R2
        STR     R1, [R0]
        POP     {R0-R2,LR}
        BX      LR
        ENDP

blink_once      PROC
        PUSH    {LR}
        BL      leds_on
        BL      delay_ms_like
        BL      leds_off
        BL      delay_ms_like
        POP     {LR}
        BX      LR
        ENDP

        END
