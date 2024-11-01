%define OS_READ   0
%define OS_WRITE  1
%define OS_OPEN   2
%define OS_MMAP   9
%define OS_MUNMAP 11
%define OS_EXIT   60

%define O_RDONLY      0b000
%define O_WRONLY      0b001
%define O_RDWR        0b010
; there's more opts for dir, create, excl, noctty, nofollow...

%define PROT_NONE     0b000
%define PROT_READ     0b001
%define PROT_WRITE    0b010
%define PROT_EXEC     0b100

%define MAP_PRIVATE   0b10
; also more opts ig

%define FD_STDIN  0
%define FD_STDOUT 1

;%define NUM_PI  3.141592653578
;%define NUM_PI2 6.283185307156

section .bss
    bodies: resq 256 ; [body*]
    qword_tmp: resq 1

section .rodata
    ONE: dq 1
    TWO: dd 2
    HALF: dd __float32__(0.5)
    UNIT: db "##"
%define UNIT_SIZE 2
    NEWLINE: db 10
    SPACE: db " "
    SEMICOLON: db ";"
    LETTER_UP_H: db "H"
    LETTER_DOWN_M: db "m"
    zero_dev: db "/dev/zero", 0
    uerr: db 0x1b, "[1;31m", "ERR: Unknown error!", 0x1b, "[0m", 10
    uerrl: equ $ - uerr
    pre_seq: db 0x1b, "[?1049h"
    pre_seql: equ $ - pre_seq
    post_seq: db 0x1b, "[?1049l"
    post_seql: equ $ - post_seq
    frame_seq: db 0x1b, "[2J"
    frame_seql: equ $ - frame_seq
    seq_def: db 0x1b, "["
    seq_defl: equ $ - seq_def

section .data
    blue_ansi_color: db 0x1b, "[1;34m"
    yellow_ansi_color: db 0x1b, "[1;33m"
    earth_body:
        dd 20.0, 20.0, 10.0, 10.0
        db 3, 10
        dq blue_ansi_color
        db 7
    sun_body:
        dd 10.0, 10.0, 0.0, 0.0
        db 7, 100
        dq yellow_ansi_color
        db 7

section .text
    global _start

_start:
    ;call pre_run

    ;movzx rax, byte [sun_body+17]
    ;mov rdi, 10
    ;call itos
    ;push rsi ; malloc'd mem ptr
    ;call print_last_itos
    ;pop rdi
    ;mov rsi, 64
    ;call free_rdi_rsi

    mov rax, sun_body
    call print_body
    mov rax, earth_body
    call print_body

    ;call post_run

    mov rax, OS_EXIT
    mov rdi, 0
    syscall

pre_run:
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, pre_seq
    mov rdx, pre_seql
    syscall
    ret

post_run:
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, post_seq
    mov rdx, post_seql
    syscall
    ret

%include "lib.asm"
