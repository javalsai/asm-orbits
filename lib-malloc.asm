; https://man7.org/linux/man-pages/man3/malloc.3.html
; takes:
;  rax: size
; returns:
;  rax: addr
malloc:
    push rax
    mov rax, OS_OPEN
    mov rdi, zero_dev                 ; mmaping /dev/zero allocates arbitrary memory
    mov rsi, O_RDWR                   ; flags
    mov rdx, 0                        ; mode, only used on creation
    syscall
    ; fd is in rax btw

    mov r8, rax                       ; mmap /dev/zero's fs
    mov rax, OS_MMAP
    mov rdi, 0                        ; destination will be arbitrary
    pop rsi                           ; page size
    mov rdx, PROT_READ | PROT_WRITE   ; r/w page
    mov r10, MAP_PRIVATE              ; private pages
    mov r9, 0                         ; "off"?
    syscall
    ; rax has the mapped location btw

    ret

; takes
;  r10: ptr
;  r9: size
free:
    mov rdi, r10
    mov rsi, r9
free_rdi_rsi:
    mov rax, OS_MUNMAP
    syscall
    ret
