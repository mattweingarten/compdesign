.globl n_nplus1 
.text

n_nplus1:
   movq %rdi, %rdx 
   movq %rdi, %rax
   callq _f
    

_f:
    cmpq $0, %rdi
    je g
    imulq %rdx, %rax
    decq %rdi 
    callq _f  
g:
    retq
