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

    ; TODO: move to pos_X

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
        mov rax, [rbp-8]
        mov rdi, qword [rax+body.pos_y] ; also loads pos_y
        mov rsi, r15 ; v offset
        sub rsi, r9
        call go_pos_rdi2f_ln_rsi

        mov rax, r15
        sub rax, r9
        mov rcx, 10
        call print_rax_radix_rcx

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
        jmp .print_body_j_align1_tail
        .print_body_j_align1:
            mov rax, OS_WRITE
            mov rdi, FD_STDOUT
            mov rsi, SPACE
            mov rdx, 1
            syscall

            dec r10
            .print_body_j_align1_tail:
            cmp r10, 0
            jg .print_body_j_align1

        pop r10
        push r10
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

        pop r10
        mov r11, r10
        mov r10, r15
        sub r10, r11
        jmp .print_body_j_align2_tail
        .print_body_j_align2:
            mov rax, OS_WRITE
            mov rdi, FD_STDOUT
            mov rsi, SPACE
            mov rdx, 1
            syscall

            dec r10
            .print_body_j_align2_tail:
            cmp r10, 0
            jg .print_body_j_align2

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
go_pos_rdi2f_ln_rsi:
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

; iterating through lines of a 3 long body would do
; 1/3, 2/3, 3/3; which aren't vercailly "even", starts
; at 0.3333 and ends with 1, which would render an empty line
; we instead want 0.25, 0.50, 0.75, leaving both edges out
; and this is as simple as multiplying by n/(n + 1) (where n
; is simly the amount of lines)
;
; rax: of number

;get_normalization_ratio:
;    mov qword [rsp-8], rax
;    fild qword [rsp-8]
;    inc qword [rsp-8]
;    fild qword [rsp-8]
;    fdivp st1, st0
;
;    ret

; OR, we can shift everything half a unit under, like
; 1/3, 2/3, 3/3 -> 1/3 - 1/6, 2/3 - 1/6, 3/3 - 1/6 =
; 0.3, 0.6, 1   -> 0.1666666, 0.5,       0.8333333
; and instead of looking like (doing a staircase)
; ####
; ########
; ############
; or
; ###
; ######
; #########
; looks like
; ##
; ######
; ##########
;get_shift_constant:
;    ;fld1
;    ;mov qword [rsp-8], rax
;    ;fild qword [rsp-8]
;    ;fdivp st1, st0
;    ;mov qword [rsp-8], 2
;    ;fild qword [rsp-8]
;    ;fdivp st1, st0
;
;    mov dword [rsp-8], __float32__(0.5)
;    fld dword [rsp-8]
;
;    ret

; aaaand, unnecessary cuz if done in the proper moment is
; just substracting 1/2 every time
