; nasm ...
; ld ...

;:set tabstop=2
;:set shiftwidth=2

%define OS_READ   0
%define OS_WRITE  1
%define OS_OPEN   2
%define OS_MMAP   9
%define OS_EXIT   60

%define FD_STDIN  0
%define FD_STDOUT 1

;%define NUM_PI  3.141592653578
;%define NUM_PI2 6.283185307156

section .bss
    bodies: resq 256 ; [body*]
    qword_tmp: resq 1

section .rodata
    ONE: dq 1
    UNIT: db ".."
%define UNIT_SIZE 2
    NEWLINE: db 10
    SPACE: db " "

section .data
    example_body_color: db 0x1b, "[1;35m"
    example_body: db 59, 0, 0, 0, 0, 100
    dq example_body_color
    db 7

section .text
    global _start

_start:
    mov rax, example_body
    call print_body

    mov rax, OS_EXIT
    mov rdi, 0
    syscall

%include "lib.asm"