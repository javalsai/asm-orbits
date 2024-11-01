%define PROP_BODY_POS_X       0
%define PROP_BODY_POS_Y       4
%define PROP_BODY_VEL_X       8
%define PROP_BODY_VEL_Y       12
%define PROP_BODY_RADIUS      16
%define PROP_BODY_MASS        17
%define PROP_BODY_ESCAPE      18
%define PROP_BODY_ESCAPE_LEN  26
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
print_body:
    push rax
    ; TODO: move to pos_X

    ; print escape color
    pop rax
    push rax
    mov rsi, [rax+PROP_BODY_ESCAPE]
    mov rdx, [byte rax+PROP_BODY_ESCAPE_LEN]
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    syscall

    ; render thing
    mov qword [qword_tmp], 0x0107F ; round mode
    fldcw [qword_tmp]

    pop rax
    movzx r15, byte [rax+PROP_BODY_RADIUS]
    mov r9, r15

    mov rax, r9
    call get_normalization_ratio
    .print_body_loop_i:
        mov r10, r15
        inc r10
        sub r10, r9

        mov qword [qword_tmp], r10
        fild qword [qword_tmp]
        fmul st0, st1
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
        dec r10

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

; iterating through lines of a 3 long body would do
; 1/3, 2/3, 3/3; which aren't vercailly "even", starts
; at 0.3333 and ends with 1, which would render an empty line
; we instead want 0.25, 0.50, 0.75, leaving both edges out
; and this is as simple as multiplying by n/(n + 1) (where n
; is simly the amount of lines)
;
; rax: of number
get_normalization_ratio:
    mov qword [qword_tmp], rax
    fild qword [qword_tmp]
    inc qword [qword_tmp]
    fild qword [qword_tmp]
    fdivp st1, st0

    ret
