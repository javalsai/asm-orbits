struc kernel_sigaction
    .k_sa_handler    resq 1
    .sa_flags        resb 8
    .sa_restorer     resq 1
    .sa_mask         resb 128 ; should be shorter but idk exactly, just null it out
endstruc


set_signal_rdi_sigact_rax:
    mov rsi, rax
    mov rax, OS_RT_SIGACTION
    mov rdx, 0
    mov r10, 8
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
