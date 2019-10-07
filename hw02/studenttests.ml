open Assert
open X86
open Simulator
open Gradedtests

(* These tests are provided by you -- they will be graded manually *)

(* You should also add additional test cases here to help you   *)
(* debug your program.                                          *)

let sarq_1 = test_machine
    [InsB0 (Movq, [Imm (Lit 4L); Reg Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
    ;InsB0 (Sarq, [Imm (Lit 1L); Reg Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
    ]

let sarq_tests = [
  ("mov_mr", machine_test "$rax=2 fo=0" 2 sarq_1
     (fun m -> m.regs.(rind Rax) = 2L && m.flags.fo = false)
  );
]

let provided_tests : suite = [
  Test ("sarq", sarq_tests);
  Test ("Student-Provided Big Test for Part III: Score recorded as PartIIITestCase", [
    ]);

] 
