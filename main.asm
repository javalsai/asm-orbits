%define OS_READ          0
%define OS_WRITE         1
%define OS_OPEN          2
%define OS_MMAP          9
%define OS_MUNMAP        11
%define OS_RT_SIGACTION  13
%define OS_SCHED_YIELD   24
%define OS_PAUSE         34
%define OS_EXIT          60

%define SIG_SIGINT       2
%define SIG_SIGSEGV      11
%define SIG_SIGTERM      15

%define SA_RESETHAND       0x80000000
%define SA_RESTORER        0x04000000

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

struc kernel_sigaction
    .k_sa_handler    resq 1
    .sa_flags        resb 8
    .sa_restorer     resq 1
    .sa_mask         resb 128 ; should be shorter but idk exactly, just null it out
endstruc

section .bss
    bodies: resb body_size * 256 ; [body]
    ksigact: resb kernel_sigaction_size

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

    ;ansi_erase_in_display: db 0x1b, "[2J"
    ansi_erase_in_display: db 0x1b, "c"
    ansi_erase_in_displayl: equ $ - ansi_erase_in_display
    ; begin synchronized update
    ansi_bsu: db 0x9b, "?2026h"
    ansi_bsul: equ $ - ansi_bsu
    ; end synchronized update
    ansi_esu: db 0x9b, "?2026l"
    ansi_esul: equ $ - ansi_esu
    ansi_home: db 0x1b, "[H"
    ansi_homel: equ $ - ansi_home

section .data
    white_ansi_color: db 0x1b, "[1;39m"
    blue_ansi_color: db 0x1b, "[1;34m"
    yellow_ansi_color: db 0x1b, "[1;33m"
    moon_body:
        dd 20.0, 20.0, 10.0, 10.0
        db 2, 10
        dq white_ansi_color
        db 7
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

mmove:
    mov r10, [rcx+rax]
    mov [rbx+rax], r10
    inc rax
    cmp rax, rdx
    jne mmove
    ret


_start:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    ; [rbp-8]:  body ptr
    ; [rbp-16]: frame delta t

    ;call pre_run

    ;movzx rax, byte [sun_body+17]
    ;mov rdi, 10
    ;call itos
    ;push rsi ; malloc'd mem ptr
    ;call print_last_itos
    ;pop rdi
    ;mov rsi, 64
    ;call free_rdi_rsi

    lea rax, [sa_handler]
    mov qword [ksigact+kernel_sigaction.k_sa_handler], rax
    lea rax, [sa_restorer]
    mov qword [ksigact+kernel_sigaction.sa_restorer], rax
    mov rax, SA_RESTORER
    or qword [ksigact+kernel_sigaction.sa_flags], rax
    ;mov rax, SA_RESETHAND
    ;or qword [ksigact+kernel_sigaction.sa_flags], rax

    ; todo: iter or smth
    mov rax, OS_RT_SIGACTION
    mov rdi, SIG_SIGTERM
    lea rsi, [ksigact]
    mov rdx, 0
    mov r10, 8
    syscall
    mov rax, OS_RT_SIGACTION
    mov rdi, SIG_SIGINT
    lea rsi, [ksigact]
    mov rdx, 0
    mov r10, 8
    syscall
    mov rax, OS_RT_SIGACTION
    mov rdi, SIG_SIGSEGV
    lea rsi, [ksigact]
    mov rdx, 0
    mov r10, 8
    syscall

    ;mov rax, OS_PAUSE
    ;syscall

    mov rax, 0
    mov rdx, body_size
    lea rbx, [bodies+body_size*0]
    lea rcx, [sun_body]
    call mmove
    mov rax, 0
    mov rdx, body_size
    lea rbx, [bodies+body_size*1]
    lea rcx, [earth_body]
    call mmove
    mov rax, 0
    mov rdx, body_size
    lea rbx, [bodies+body_size*2]
    lea rcx, [moon_body]
    call mmove

    .render_loop_start:
        call render_esu
        mov rax, OS_SCHED_YIELD
        syscall
        call render_bsu
        call render_clear

        lea rax, [bodies]
        mov [rbp-8], rax
    .render_loop:
        mov rax, [rbp-8]
        mov rbx, [rax+body.col]
        test rbx, rbx
        jz .render_loop_start
        call print_body
        add qword [rbp-8], body_size
        jmp .render_loop
    call render_esu

    mov rax, sun_body
    call print_body
    mov rax, earth_body
    call print_body
    mov rax, moon_body
    call print_body

    ;call post_run

    .exit:
    mov rax, OS_EXIT
    mov rdi, 0
    syscall

    mov rsp, rbp
    pop rbp
    ret

; void (*_)(int)
sa_handler:
    ;call render_clear
    ;call render_home
    call render_esu

    mov rax, OS_EXIT
    mov rdi, 0
    syscall
    ret

; void (*_)(void)
; in x86_64 this is more complex
; but idk where
; ```c
; extern void restore_rt (void) asm ("__restore_rt") attribute_hidden;
; ```
; goes, soooo...., plus not linking against glibc which is where that likely links to
sa_restorer:
    ret

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
