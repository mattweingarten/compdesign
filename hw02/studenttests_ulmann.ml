open Assert
open X86
open Simulator
open Asm
open Gradedtests
(* These tests are provided by you -- they will be graded manually *)

(* You should also add additional test cases here to help you   *)
(* debug your program.                                          *)

let cc_from_to (n:int) (m:mach) (fo',fs',fz') (fo'',fs'',fz'') = 
  cc_test (Printf.sprintf "expected OF:%b SF:%b ZF:%b" fo'' fs'' fz'')
    n m (fo',fs',fz')
    (fun m -> m.flags.fo = fo'' && m.flags.fs = fs'' && m.flags.fz = fz'')


(* Additional shift cc tests*)
let cc_sarq_0 = test_machine  
  [InsB0 (Movq, [~$0x400600; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Sarq, [(Imm (Lit 0L)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_sarq_1 = test_machine  
  [InsB0 (Movq, [(Imm (Lit 0xFFFFFFFFFFFFFFFFL)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Sarq, [~$0; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_sarq_2 = test_machine  
  [InsB0 (Movq, [~$424242; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Sarq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_sarq_3 = test_machine  
  [InsB0 (Movq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Sarq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_sarq_4 = test_machine  
  [InsB0 (Movq, [~$2; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Sarq, [~$2; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]


let cc_shlq_1 = test_machine  
  [InsB0 (Movq, [~$424242; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shlq, [~$0; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_shlq_2 = test_machine  
  [InsB0 (Movq, [(Imm (Lit 0x3FFFFFFFFFFFFFFFL)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shlq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_shlq_3 = test_machine  
  [InsB0 (Movq, [(Imm (Lit 0x7FFFFFFFFFFFFFFFL)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shlq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_shlq_4 = test_machine  
  [InsB0 (Movq, [(Imm (Lit 0x7FFFFFFFFFFFFFFFL)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shlq, [~$2; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]


let cc_shrq_1 = test_machine  
  [InsB0 (Movq, [~$424242; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shrq, [~$0; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_shrq_2 = test_machine  
  [InsB0 (Movq, [~$(-1); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shrq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_shrq_3 = test_machine  
  [InsB0 (Movq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shrq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_shrq_4 = test_machine  
  [InsB0 (Movq, [~$2; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Shrq, [~$2; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

(* additional overflow tests *)

let cso_mult_1 = test_machine  
  [InsB0 (Movq, [(Imm (Lit 0x4000000000000000L)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Imulq, [~$2; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cso_add_1 = test_machine  
  [InsB0 (Movq, [(Imm (Lit 0x7FFFFFFFFFFFFFFFL)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Addq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cso_sub_1 = test_machine  
  [InsB0 (Movq, [(Imm (Lit 0x8000000000000000L)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Subq, [~$1; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let cc_additional_tests =
  [ ("cc_sarq_0", cc_from_to 2 cc_sarq_0 (false, false, false) (false, false, false));
    ("cc_sarq_1", cc_from_to 2 cc_sarq_1 (false, false, false) (false, false, false));
    ("cc_sarq_2", cc_from_to 2 cc_sarq_2 (true, false, false) (false, false, false));
    ("cc_sarq_4", cc_from_to 2 cc_sarq_4 (true, false, false) (true, false, true));
    ("cc_shlq_1", cc_from_to 2 cc_shlq_1 (true, false, true) (true, false, true));
    ("cc_shlq_2", cc_from_to 2 cc_shlq_2 (false, false, false) (false, false, false));
    ("cc_shlq_3", cc_from_to 2 cc_shlq_3 (false, false, false) (true, true, false));
    ("cc_shlq_4", cc_from_to 2 cc_shlq_4 (false, false, false) (false, true, false));
    ("cc_shrq_1", cc_from_to 2 cc_shrq_1 (false, false, false) (false, false, false));
    ("cc_shrq_2", cc_from_to 2 cc_shrq_2 (false, false, false) (true, false, false));
    ("cc_shrq_3", cc_from_to 2 cc_shrq_3 (false, false, false) (false, false, true));
    ("cc_shrq_4", cc_from_to 2 cc_shrq_4 (false, false, false) (false, false, true));
    ("cc_mult_1", cso_test 2 cso_mult_1 true); 
    ("cc_add_1", cso_test 2 cso_add_1 true); 
    ("cc_sub_1", cso_test 2 cso_sub_1 true); 
  ]

(* additional functional tests *)

let setb_1 = test_machine
  [InsB0 (Movq, [(Imm (Lit 0xFFFFFFFFFFFFFFFFL)); ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Cmpq, [~$2; ~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Set Le, [~%Rax]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let setb_2 = test_machine
  [InsB0 (Movq, [(Imm (Lit 0xFFFFFFFFFFFFFFFFL)); Ind2 Rsp]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Addq, [~$7; ~%Rsp]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Cmpq, [~$2; ~$1]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag
   ;InsB0 (Set Gt, [Ind2 Rsp]);InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]

let additional_func_tests = [
  ("setb_1", machine_test "only to change the lowest byte" 3 setb_1 (fun m -> 
    m.regs.(rind Rax) = 0xFFFFFFFFFFFFFF01L
  ));  
  ("setb_2", machine_test "only to change the lowest byte" 4 setb_2 (fun m -> 
    m.mem.(0xffff) = Byte(Char.chr 0)
  ));  
]


let provided_tests : suite = [
  Test ("Additonal cc tests", cc_additional_tests);
  Test ("Additonal functionality tests", additional_func_tests);
] 
