open Assert
open X86
open Simulator
open Gradedtests

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

let provided_tests : suite = [
  Test ("sarq", sarq_tests);
  Test ("shrq", shrq_tests);
  Test ("Student-Provided Big Test for Part III: Score recorded as PartIIITestCase", [
    ]);

] 
