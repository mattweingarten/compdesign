.globl sum 
.text

sum:
    movq $0, %rax 
    movq $0, %rcx 
    call f 

f:  
   cmp $0, %rdi 
   je g 
   addq %rdi, %rcx 
   decq %rdi
   callq f 

g: 
    movq %rcx, %rax  
    retq

