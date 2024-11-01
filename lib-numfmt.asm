; string to interger (ik ppl call this atoi, but nvm)
; takes:
;  string pointer (null terminated): rsi
;  radix: rdi
; returns:
;  rax: result
; garbage:
;  rdx: last processed digit
;  rsi: ptr to str final nullbyte+1
; notes:
;  mul => rdx:rax = rax * r/m64
stoi:
    mov rax, 0
    .stoi_parse_digit:
        cmp byte [rsi], 0
        je .stoi_return      ; compare
        mul rdi             ; shift radix

        mov rdx, [rsi]
        and rdx, 0b1111 ; grab digit
        add rax, rdx    ; add digit to the number
        inc rsi
        jmp .stoi_parse_digit
    .stoi_return:
        ret

; integer to string (idk how ppl name this, but I already got stoi)
; takes:
;  rax: integer
;  rdi: radix
; returns:
;  rsi: memory block (freeable when needed)
;  r10: start ptr (within block)
;  r9: str len
; garbage:
;  rax: consumed integer
; notes:
;  div => rdx:rax / r/m64 => rax(quot), rdx(remnd)
itos:
    ; save registers
    push rax
    push rdi
    ; malloc some mem
    mov rax, 64     ; page size (max representable value is 64 bits long,
                  ; a full 64 bit register with radix 2)
    call malloc
    test rax, rax
    jz uerrf        ; allocation error likely?
    mov rsi, rax    ; put malloc'd mem into rsi
    ; restore registers
    pop rdi
    pop rax

    ; align rsi ptr (we write from end)
    mov r10, rsi
    add r10, 64 ; we do an extra number cuz alignment and less intructs
    .itos_iter:
        dec r10
        mov rdx, 0          ; is used as upper half of divide, so set to 0
        div rdi             ; now rax holds the new shifted result by default and we get
                        ; the remainder in rdx to shift into number range (higher
                        ; than 10 radix will work, but range of letters will be broken)
        add rdx, 48         ; '0' == 48
        mov byte [r10], dl  ; lower(8) rdx
        test rax,rax        ; gotta run at least once to at least get a zero when rax = 0
        jnz .itos_iter

    .itos_return:
        mov r9, rsi
        add r9, 64
        sub r9, r10
        ret

print_r10_r9:
print_last_itos:
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, r10
    mov rdx, r9
    syscall
    ret
