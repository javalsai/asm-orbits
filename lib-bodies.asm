struc body
    .pos_x   resd 1
    .pos_y   resd 1
    .vel_x   resd 1
    .vel_y   resd 1
    .radius  resb 1
    .mass    resb 1
    .col     resq 1
    .col_len resb 1
endstruc
; body = {
;   0  f32     pox_x, (in "units (L)")
;   4  f32     pos_y, (in "units (L)")
;   8  f32     vel_x, (in "units" (L) / ms )
;   12 f32     vel_y, (in "units" (L) / ms )
;   16 u8      radius, (in chars)
;   17 u8      mass, (in "units" (M))
;   18 *char   escape_color
;   26 u8      escape_color_len
; }

; rax: *body
; assuming the body is on proper position (no negative or "over-screen")
print_body:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    ; [rbp-8]: *body
    mov [rbp-8], rax

    ; print escape color
    mov rsi, [rax+body.col]
    movzx rdx, byte [rax+body.col_len]
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    syscall

    ; render thing
    mov qword [rsp-8], 0x0107F ; round mode
    fldcw [rsp-8]

    mov rax, [rbp-8]
    movzx r15, byte [rax+body.radius]
    mov r9, r15

    .print_body_loop_i:
        mov r10, r15
        inc r10
        sub r10, r9

        mov qword [rsp-8], r10
        fild qword [rsp-8]
        fsub dword [HALF]
        fimul dword [TWO]
        mov qword [rsp-8], r15
        fisub dword [rsp-8]
        fidiv dword [rsp-8]
        call sin_arccos
        mov qword [rsp-8], r15
        fimul dword [rsp-8]
        fistp qword [rsp-8]
        mov r10, qword [rsp-8]
        dec r10

        push r10
        mov r11, r10
        mov r10, r15
        sub r10, r11

        mov rax, [rbp-8]
        mov rdi, qword [rax+body.pos_x] ; also loads pos_y
        ; radius correction {{{
        mov dl, [rax+body.radius]
        xor rax, rax
        mov al, dl
        shr al, 1
        ; }}}
        mov rsi, r15 ; v offset
        sub rsi, r9  ; v offset
        sub rsi, rax ; radius correction
        mov rdx, r10 ; h offset
        sub rsi, rax ; radius correction
        call go_pos_rdi2f_ln_rsi_col_rdx

        pop r10
        jmp .print_body_loop_j_tail
        .print_body_loop_j:
            mov rax, OS_WRITE
            mov rdi, FD_STDOUT
            mov rsi, UNIT
            mov rdx, UNIT_SIZE
            syscall

            dec r10
            .print_body_loop_j_tail:
            cmp r10, 0
            jg .print_body_loop_j

        ; todo: remove and just go to pos
        mov rax, OS_WRITE
        mov rdi, FD_STDOUT
        mov rsi, NEWLINE
        mov rdx, 1
        syscall

        dec r9
        cmp r9, 0
        jg .print_body_loop_i

    mov rsp, rbp
    pop rbp
    ret

; sin(arccos(x)) = sqrt(1 - x^2)
; (number loaded into fpu)
sin_arccos:
    fmul st0, st0
    fchs
    fiadd dword [ONE]
    fsqrt
    ret

; go to pos in rdi (x:y, 32floats, concat'd)
; with a verticall offset of rsi
go_pos_rdi2f_ln_rsi_col_rdx:
    push rdx
    push rsi
    push rdi
    ; low -> high addrs
    ; [ fy fy fy fy fx fx fx fx ] [ ...
    ; [ sp sp sp sp sp sp sp sp ] [ ...
    ;   ^^          +4            +8...
        mov rax, OS_WRITE
        mov rdi, FD_STDOUT
        lea rsi, [ansi_home]
        mov rdx, 2
        syscall
    fld dword [rsp+4]
    fistp qword [rsp-8]
    mov rax, [rsp-8]
    inc rax
    add rax, qword [rsp+8]
    mov rcx, 10
    call print_rax_radix_rcx
        mov rax, OS_WRITE
        mov rdi, FD_STDOUT
        mov byte [rsp-8], ';'
        lea rsi, [rsp-8]
        mov rdx, 1
        syscall
    fld dword [rsp]
    fistp qword [rsp-8]
    mov rax, [rsp-8]
    inc rax
    add rax, qword [rsp+16]
    mov rcx, 10
    call print_rax_radix_rcx
        mov rax, OS_WRITE
        mov rdi, FD_STDOUT
        mov byte [rsp-8], 'H'
        lea rsi, [rsp-8]
        mov rdx, 1
        syscall
    pop rdi
    pop rsi
    pop rdx
    ret

print_rax_radix_rcx:
    push rbp
    mov rbp, rsp

    jmp .pdts_tail
    .push_digits_to_stack:
        xor rdx, rdx
        div rcx ; ( rdx:rax + rdx' ) / _ = rax'
        add rdx, '0'
        push rdx ; push rem to stack
        .pdts_tail:
        test rax, rax
        jnz .push_digits_to_stack

    cmp rsp, rbp
    jne .zero_case_tail
    push '0'
    .zero_case_tail:

    ; reverse stack printing
    .reverse_loop:
        cmp rsp, rbp
        je .reverse_tail
        mov rax, OS_WRITE
        mov rdi, FD_STDOUT
        lea rsi, [rsp]
        mov rdx, 1
        syscall
        add rsp, 8
        jmp .reverse_loop
        .reverse_tail:

    pop rbp
    ret

; IVE BEEN THINKING BOUT YOU WAY TOO MUCH
; I TRIED TO STOP IT BUT ITS HARD TO STOP THE RUSHH
; OF ALL THE ATTENTION, THE MESSAGES
; I TRIED TO KEEP IT IN MY HEAD
; BUT NOOW I THINK I HAVEE A LITTLEEE CRUSH
;
; WAIT
;
; MAYBE ITS NOT JUST MEEE MAYBE YOURE THINKING THE SAMEE
; NOW THAT I THINK BACK THAT THOUGHT DOESNT EVEN SEEM THAT INSANEE
; WELL I THINK IT DOESNT MAYBEEE CUZ U TEXT ME EVERY DAYYY
; AND WHEN WE'RE TOGETHER WITH FRIENDS YOU SEEM TO TREAT ME DIFFERENTLYYY
body_rax_apply_speed_dt_rcx:
    fld dword [rax+body.vel_x]
    mov qword [rsp-8], rcx
    fild qword [rsp-8]
    fmulp

    mov qword [rsp-8], 1000000000
    fild qword [rsp-8]
    fdivp

    fld dword [rax+body.pos_x]
    faddp
    fstp dword [rax+body.pos_x]


    fld dword [rax+body.vel_y]
    mov qword [rsp-8], rcx
    fild qword [rsp-8]
    fmulp

    mov qword [rsp-8], 1000000000
    fild qword [rsp-8]
    fdivp

    fld dword [rax+body.pos_y]
    faddp
    fstp dword [rax+body.pos_y]
    ret

; aaaand, unnecessary cuz if done in the proper moment is
; just substracting 1/2 every time


; I WANT TO BOY YOU SMTH
; BUT I DONT HAVE ANY MONEYYYYYYYYY
; NO I DONT HAVE ANY MONEYYY
;
; I WANT TO BOY YOU SMTHHH
; NO I DONT HAVE AN MONEY, NO I DONT HAVE MONEY
; ....
; HMMHMMMHHHH
; ...
; AH AHAHA HAHHHHHAHHHH
; AHUAHUAHAHHAHAHUAHAHHUHH
; AHMMMHAMAHMAHMAMMMM
; HA
; HAMNMNMNMNMNMHAAMNAMNMNMMANAHANMNM
