; body = {
;   0 u8      radius, (in chars)
;   1 u8      pox_x, (in "units (L)")
;   2 u8      pos_y, (in "units (L)")
;   3 u8      vel_x, (in "units" (L) / ms )
;   4 u8      vel_y, (in "units" (L) / ms )
;   5 u8      mass, (in "units" (M))
;   6 *char   escape_color
;   14 u8     escape_color_len
; }

; rax: *body
print_body:
    push rax
    ; TODO: move to pos_X

    ; print escape color
    mov rsi, [rax+6]
    mov rdx, [byte rax+14]
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    syscall

    ; render thing
    mov qword [qword_tmp], 0x077F ; ceil code
    fldcw [qword_tmp]

    pop rax
    movzx r15, byte [rax]
    mov r9, r15
    .print_body_loop_i:
        mov r10, r15
        inc r10
        sub r10, r9

        mov qword [qword_tmp], r10
        fild qword [qword_tmp]
        mov qword [qword_tmp], 2
        fimul dword [qword_tmp]
        mov qword [qword_tmp], r15
        fisub dword [qword_tmp]
        fidiv dword [qword_tmp]
        call sin_arccos
        mov qword [qword_tmp], r15
        fimul dword [qword_tmp]
        fistp qword [qword_tmp]
        mov r10, qword [qword_tmp]

        push r10
        mov r11, r10
        mov r10, r15
        sub r10, r11
        ;shr r11, 1
        jmp .print_body_j_align_tail
        .print_body_j_align:
            mov rax, OS_WRITE
            mov rdi, FD_STDOUT
            mov rsi, SPACE
            mov rdx, 1
            syscall

            dec r10
            .print_body_j_align_tail:
            cmp r10, 0
            jg .print_body_j_align

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
        mov rax, OS_WRITE
        mov rdi, FD_STDOUT
        mov rsi, NEWLINE
        mov rdx, 1
        syscall

        dec r9
        cmp r9, 0
        jg .print_body_loop_i

    ret

; sin(arccos(x)) = sqrt(1 - x^2)
; (number loaded into fpu)
sin_arccos:
    fmul st0, st0
    fchs
    fiadd dword [ONE]
    fsqrt
    ret
