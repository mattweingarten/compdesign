open Assert
open X86
open Simulator
open Gradedtests
open Asm


(* These tests are provided by you -- they will be graded manually *)

(* You should also add additional test cases here to help you   *)
(* debug your program.                                          *)

(* basic functionality test (shift by 1) *)
let sarq_1 = test_machine
    [InsB0 (Movq, [Imm (Lit 4L); Reg Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
    ;InsB0 (Sarq, [Imm (Lit 1L); Reg Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
    ]

let shrq_1 = test_machine
    [InsB0 (Movq, [Imm (Lit 4L); Reg Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
    ;InsB0 (Shrq, [Imm (Lit 1L); Reg Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
    ]

let sarq_tests = [
  ("sarq", machine_test "$rax=2 fo=0" 2 sarq_1
     (fun m -> m.regs.(rind Rax) = 2L && m.flags.fo = false)
  );
]

let shrq_tests = [
  ("shrq", machine_test "$rax=2 fo=0" 2 shrq_1
     (fun m -> m.regs.(rind Rax) = 2L && m.flags.fo = false)
  );
]


let gcd m n = [ text "main"
                          [ Movq, [~$n; ~%Rax]
                          ; Movq, [~$m; ~%Rdi]
                          ; Jmp, [~$$"compare"]
                          ]
                      ; text "compare"
                          [ Cmpq, [~%Rax; ~%Rdi]
                            ; J Eq,  [~$$"exit"]
                            ; J Lt, [~$$"swap"]
                            ; Jmp, [~$$"loop"]
                          ]
                      ; text "swap"
                          [ Movq, [~%Rax; ~%Rsi]
                          ; Movq, [~%Rdi; ~%Rax]
                          ; Movq, [~%Rsi; ~%Rdi]
                          ; Jmp, [~$$"loop"]
                          ]
                      ; text "loop"
                          [ Subq, [~%Rax; ~%Rdi]
                          ; Jmp, [~$$"compare"]
                          ]
                      ; text "exit"
                                 [ Retq,  []
                                 ]
                ]



let provided_tests : suite = [
  Test ("sarq", sarq_tests);
  Test ("shrq", shrq_tests);
  Test ("Student-Provided Big Test for Part III: Score recorded as PartIIITestCase", [
      ("gcd1", program_test (gcd 120 12) 12L);
      ("gcd2", program_test (gcd 5 3) 1L);
      ("gcd3", program_test (gcd 3 5) 1L);
      ("gcd4", program_test (gcd 67 17) 1L);
      ("gcd5", program_test (gcd 17 67) 1L);
      ("gcd6", program_test (gcd 15 27) 3L);
      ("gcd7", program_test (gcd 27 15) 3L);
      ("gcd8", program_test (gcd 6 8) 2L);
      ("gcd9", program_test (gcd 8 6) 2L);
      ("gcd10", program_test (gcd 512 1671) 1L);
      ("gcd11", program_test (gcd 1671 512) 1L);
    ]);

]


(* Printf.printf "Here is result of program test: %d\n" (Int64.to_int (program_test (factorial_rec 5))); *)
