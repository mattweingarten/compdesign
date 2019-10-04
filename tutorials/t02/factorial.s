.globl factorial
.text
factorial:
  movq $0, %rax 
  movq $1, %rcx 

  call _factorial

_factorial: 
   cmp $0, %rdi 
   je _base_case
   cmp $1, %rdi 
   je _base_case
   imulq %rdi, %rcx 
   decq %rdi
   callq _factorial 

_base_case: 
    movq %rcx, %rax
    retq
