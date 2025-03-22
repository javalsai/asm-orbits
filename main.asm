%define OS_READ          0
%define OS_WRITE         1
%define OS_OPEN          2
%define OS_MMAP          9
%define OS_MUNMAP        11
%define OS_RT_SIGACTION  13
%define OS_SCHED_YIELD   24
%define OS_PAUSE         34
%define OS_EXIT          60
%define OS_CLOCK_GETTIME 228

%define SIG_SIGINT       2
%define SIG_SIGSEGV      11
%define SIG_SIGTERM      15

%define SA_RESETHAND       0x80000000
%define SA_RESTORER        0x04000000

%define CLOCK_MONOTONIC  1

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

struc timespec
    .tv_sec  resq 1
    .tv_nsec resq 1
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

    str_fps_head: db 0x1b, "[HFPS: "
    str_fps_headl: equ $ - str_fps_head

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
    %include "cfg-data.asm"
    ; moon_body:
    ;     dd 25.0, 20.0, -1.0, -3.0
    ;     dq white_ansi_color
    ;     db 7
    ;     db 2
    ;     dw 10
    ; earth_body:
    ;     dd 5.0, 5.0, 0.0, 0.0
    ;     dq blue_ansi_color
    ;     db 7
    ;     db 3
    ;     dw 100
    ; sun_body:
    ;     dd 35.0, 25.0, 0.0, 0.0
    ;     dq yellow_ansi_color
    ;     db 7
    ;     db 7
    ;     dw 1000

section .text
    global _start

%include "cfg.asm"

mmove:
    mov sil, [rcx+rdx]
    mov [rbx+rdx], sil
    dec rdx
    test rdx, rdx
    jnz mmove
    ret


_start:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    ; [rbp-8]:  body ptr
    ; [rbp-24] (2QW): last frame time timespec
    ; [rbp-32]: frame delta t

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
    or qword [ksigact+kernel_sigaction.sa_flags], SA_RESTORER
    ;mov rax, SA_RESETHAND
    ;or qword [ksigact+kernel_sigaction.sa_flags], rax

    ; todo: iter or smth + all signals & error handle
    lea rax, [ksigact]
    mov rdi, SIG_SIGTERM
    call set_signal_rdi_sigact_rax
    lea rax, [ksigact]
    mov rdi, SIG_SIGINT
    call set_signal_rdi_sigact_rax
    lea rax, [ksigact]
    mov rdi, SIG_SIGSEGV
    call set_signal_rdi_sigact_rax

    ;mov rax, OS_PAUSE
    ;syscall

    ; mov rdx, body_size
    ; lea rbx, [bodies+body_size*0]
    ; lea rcx, [sun_body]
    ; call mmove
    ; mov rdx, body_size
    ; lea rbx, [bodies+body_size*1]
    ; lea rcx, [earth_body]
    ; call mmove
    ; mov rdx, body_size
    ; lea rbx, [bodies+body_size*2]
    ; lea rcx, [moon_body]
    ; call mmove
    call init

    mov rax, OS_CLOCK_GETTIME
    mov rdi, CLOCK_MONOTONIC
    lea rsi, [rbp-24]
    syscall

    .render_loop_start:
        %ifdef SYNC_SEQUENCES
        call render_esu
        %endif

        mov rax, OS_SCHED_YIELD
        syscall
        mov rax, OS_CLOCK_GETTIME
        mov rdi, CLOCK_MONOTONIC
        lea rsi, [rsp-16]
        syscall
        mov rax, qword [rsp-16+timespec.tv_sec]
        sub rax, qword [rbp-24+timespec.tv_sec]
        mov rdx, 1000000000
        imul rdx ; result in rdx:rax, but not that big
        add rax, qword [rsp-16+timespec.tv_nsec]
        sub rax, qword [rbp-24+timespec.tv_nsec]
        mov [rbp-32], rax
        mov rcx, [rsp-16+timespec.tv_sec]
        mov [rbp-24+timespec.tv_sec], rcx
        mov rcx, [rsp-16+timespec.tv_nsec]
        mov [rbp-24+timespec.tv_nsec], rcx

        %ifdef SYNC_SEQUENCES
        call render_bsu
        %endif
        call render_clear

        ; todo: print dt
        mov rax, OS_WRITE
        mov rdi, FD_STDOUT
        lea rsi, [str_fps_head]
        mov rdx, str_fps_headl
        syscall
        ; this just 1e12 / n, giving fps basically
        xor rdx, rdx
        mov rcx, [rbp-32]
        mov rax, 1000000000
        div rcx
        mov rcx, 10
        call print_rax_radix_rcx

        lea rax, [bodies]
        mov [rbp-8], rax
    .render_loop:
        mov rax, [rbp-8]
        mov rbx, [rax+body.col]
        test rbx, rbx
        jz .render_loop_start
        call print_body
        mov rax, [rbp-8]
        mov rcx, qword [rbp-32]
        call body_rax_apply_speed_dt_rcx
        lea rbx, [bodies]
        .accel_loop:
            cmp rax, rbx
            je .accel_loop_next
            mov rcx, [rbx+body.col]
            test rcx, rcx
            jz .accel_loop_tail
            mov rcx, [rbp-32]
            call body_rax_grav_to_rbx_dt_rcx
            .accel_loop_next:
            add rbx, body_size
            jmp .accel_loop
            .accel_loop_tail:
        add qword [rbp-8], body_size
        jmp .render_loop
        .exitt:
    %ifdef SYNC_SEQUENCES
    call render_esu
    %endif

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
