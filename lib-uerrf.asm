; quick fn for generic fails
uerrf:
    call post_run

    mov rax, OS_WRITE
    mov rdi, FD_STDOUT
    mov rsi, uerr
    mov rdx, uerrl
    syscall

    mov rax, OS_EXIT
    mov rdi, 1
    syscall
