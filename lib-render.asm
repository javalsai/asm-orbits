render_clear:
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, ansi_erase_in_display
    mov rdx, ansi_erase_in_displayl
    syscall
    ret

render_bsu:
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, ansi_bsu
    mov rdx, ansi_bsul
    syscall
    ret

render_esu:
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, ansi_esu
    mov rdx, ansi_esul
    syscall
    ret

render_home:
    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, ansi_home
    mov rdx, ansi_homel
    syscall
    ret
