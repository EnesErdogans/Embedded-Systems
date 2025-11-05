        THUMB
        PRESERVE8

        AREA    RESET, CODE, READONLY
        EXPORT  __Vectors
        EXPORT  Reset_Handler

StackTop EQU     0x20001000
__Vectors
        DCD     StackTop
        DCD     Reset_Handler

        AREA    |.text|, CODE, READONLY
Reset_Handler
        IMPORT  __main
        B       __main

        END
