open Assert
open X86
open Simulator
open Gradedtests
open Asm

(* These tests are provided by you -- they will be graded manually *)

(* You should also add additional test cases here to help you   *)
(* debug your program.                                          *)

let inss_to_sbytes (inss:ins list) : sbyte list =
  List.map sbytes_of_ins inss |> List.flatten

let machine_test_inss (inss:ins list) =
  inss_to_sbytes inss |> test_machine |> machine_test "" (List.length inss)

type cc_expected = CC_set | CC_cleared | CC_unchanged

let machine_test_cc (inss:ins list) (fo', fs', fz') () : unit =
  List.iter (fun init ->
    let expect : cc_expected -> bool = function
      | CC_set -> true
      | CC_cleared -> false
      | CC_unchanged -> init in
    let m = inss_to_sbytes inss |> test_machine in
    machine_test "" (List.length inss)
      {m with flags = {fo = init; fs = init; fz = init}}
      (fun {flags} ->
        expect fo' = flags.fo &&
        expect fs' = flags.fs &&
        expect fz' = flags.fz) ()
  ) [false; true]

let provided_tests : suite = [
  Test ("Student-Provided Big Test for Part III: Score recorded as PartIIITestCase", [
  ]);

  Test ("Instruction Tests", [
    (* unary ops *)
  ("negq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Negq, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = -42L)
  );
  ("incq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Incq, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = 43L)
  );
  ("decq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Decq, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = 41L)
  );
  ("notq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Notq, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = -43L)
  );
    (* binary ops *)
  ("addq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Movq, [~$13; ~%Rbx]; Addq, [~%Rbx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = 55L)
  );
  ("subq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Movq, [~$13; ~%Rbx]; Subq, [~%Rbx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = 29L)
  );
  ("imulq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Movq, [~$(-13); ~%Rbx]; Imulq, [~%Rbx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = -546L)
  );
  ("xorq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Movq, [~$13; ~%Rbx]; Xorq, [~%Rbx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = 39L)
  );
  ("orq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Movq, [~$13; ~%Rbx]; Orq, [~%Rbx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = 47L)
  );
  ("andq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Movq, [~$13; ~%Rbx]; Andq, [~%Rbx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = 8L)
  );
  ("sarq", machine_test_inss
    [Movq, [~$(-42); ~%Rax]; Movq, [~$2; ~%Rcx]; Sarq, [~%Rcx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = -11L)
  );
  ("shlq", machine_test_inss
    [Movq, [~$(-42); ~%Rax]; Movq, [~$2; ~%Rcx]; Shlq, [~%Rcx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = -168L)
  );
  ("shrq", machine_test_inss
    [Movq, [~$(-42); ~%Rax]; Movq, [~$2; ~%Rcx]; Shrq, [~%Rcx; ~%Rax]]
    (fun m -> m.regs.(rind Rax) = 0x3ffffffffffffff5L)
  );
    (* other ops *)
  ("leaq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Leaq, [Ind3 (Lit 13L, Rax); ~%Rbx]]
    (fun m -> m.regs.(rind Rbx) = 55L)
  );
  ("pushq", machine_test_inss
    [Movq, [~$42; ~%Rax]; Pushq, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = 42L
      && m.regs.(rind Rsp) = Int64.sub mem_top 16L
      && int64_of_sbytes (sbyte_list m.mem (mem_size-16)) = 42L)
  );
  ("popq", machine_test_inss
    [Movq, [~$42; Ind2 Rsp]; Popq, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = 42L
      && m.regs.(rind Rsp) = mem_top
      && int64_of_sbytes (sbyte_list m.mem (mem_size-8)) = 42L)
  );
  ("set true", machine_test_inss
    [Movq, [Imm (Lit 0x123456789abcdefL); ~%Rax]; Cmpq, [~$1; ~$2]; Set Gt, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = 0x123456789abcd01L)
  );
  ("set false", machine_test_inss
    [Movq, [Imm (Lit 0x123456789abcdefL); ~%Rax]; Cmpq, [~$2; ~$2]; Set Gt, [~%Rax]]
    (fun m -> m.regs.(rind Rax) = 0x123456789abcd00L)
  );
  ("set mem", machine_test_inss
    [Movq, [Imm (Lit 0x123456789abcdefL); Ind2 Rsp]; Cmpq, [~$1; ~$2]; Set Gt, [Ind2 Rsp]]
    (fun m -> int64_of_sbytes (sbyte_list m.mem (mem_size-8)) = 0x123456789abcd01L)
  );
  ("set at mem top does not cause segfault", machine_test_inss
    [Addq, [~$7; ~%Rsp]; Cmpq, [~$1; ~$2]; Set Gt, [Ind2 Rsp]]
    (fun m -> (m.mem.(mem_size-1)) = Byte (Char.chr 1))
  );
  ("jmp", machine_test_inss
    [Jmp, [~$42]]
    (fun m -> m.regs.(rind Rip) = 42L)
  );
  ("j true", machine_test_inss
    [Cmpq, [~$1; ~$2]; J Gt, [~$42]]
    (fun m -> m.regs.(rind Rip) = 42L)
  );
  ("j false", machine_test_inss
    [Cmpq, [~$2; ~$2]; J Gt, [~$42]]
    (fun m -> m.regs.(rind Rip) = Int64.add mem_bot 16L)
  );
  ("retq", machine_test_inss
    [Movq, [~$42; Ind2 Rsp]; Retq, []]
    (fun m -> m.regs.(rind Rip) = 42L
      && m.regs.(rind Rsp) = mem_top)
  );
  ("callq", machine_test_inss
    [Callq, [~$42]]
    (fun m -> m.regs.(rind Rip) = 42L
      && m.regs.(rind Rsp) = Int64.sub mem_top 16L
      && int64_of_sbytes (sbyte_list m.mem (mem_size-16)) =
        Int64.add mem_bot 8L)
  );
  (* missing: Movq, Cmpq *)
  ]);
    (* fo, fs, fz *)
  Test ("Condition Flag Set Tests", [
  ("notq should not touch flags", machine_test_cc
    [Movq, [~$42; ~%Rax]; Notq, [~%Rax]]
    (CC_unchanged, CC_unchanged, CC_unchanged)
  );
  ("imulq no overflow", machine_test_inss
    [Movq, [~$42; ~%Rax]; Movq, [~$(-13); ~%Rbx]; Imulq, [~%Rbx; ~%Rax]]
    (fun m -> m.flags.fo = false)
  );
  ("imulq overflow", machine_test_inss
    [Movq, [Imm (Lit 0x0001000000000000L); ~%Rax];  Imulq, [~%Rax; ~%Rax]]
    (fun m -> m.flags.fo = true)
  );
   (* if AMT=0 flags are unaffected *)
  ("sarq-flags-amt0", machine_test_cc
    [Movq, [~$(-42); ~%Rax]; Sarq, [~$0; ~%Rax]]
    (CC_unchanged, CC_unchanged, CC_unchanged)
  );
  ("shlq-flags-amt0", machine_test_cc
    [Movq, [~$(-42); ~%Rax]; Shlq, [~$0; ~%Rax]]
    (CC_unchanged, CC_unchanged, CC_unchanged)
  );
  ("shrq-flags-amt0", machine_test_cc
    [Movq, [~$(-42); ~%Rax]; Shrq, [~$0; ~%Rax]]
    (CC_unchanged, CC_unchanged, CC_unchanged)
  );
   (* if AMT=1 then fo=0, fs and fz normal*)
  ("sarq-flags-amt1", machine_test_cc
    [Movq, [~$(-42); ~%Rax]; Movq, [~$1; ~%Rcx]; Sarq, [~%Rcx; ~%Rax]]
    (CC_cleared, CC_set, CC_cleared)
  );
   (* OF is set if the top two bits of DEST are different and the shift amount is 1 *)
  ("shlq-flags-amt1-01", machine_test_cc
    [Movq, [Imm (Lit 0x4000000000000000L); ~%Rax]; Shlq, [~$1; ~%Rax]]
    (CC_set, CC_set, CC_cleared)
  );
  ("shlq-flags-amt1-10", machine_test_cc
    [Movq, [Imm (Lit 0x8000000000000000L); ~%Rax]; Shlq, [~$1; ~%Rax]]
    (CC_set, CC_cleared, CC_set)
  );
  ("shlq-flags-amt1-00", machine_test_cc
    [Movq, [~$0; ~%Rax]; Shlq, [~$1; ~%Rax]]
    (CC_unchanged, CC_cleared, CC_set)
  );
  ("shlq-flags-amt1-11", machine_test_cc
    [Movq, [Imm (Lit 0xc000000000000000L); ~%Rax]; Shlq, [~$1; ~%Rax]]
    (CC_unchanged, CC_set, CC_cleared)
  );
   (* OF is set to the most-significant bit of the original operand if the shift amount is 1 *)
  ("shrq-flags-amt1", machine_test_cc
    [Movq, [~$1; ~%Rax]; Shrq, [~$1; ~%Rax]]
    (CC_cleared, CC_cleared, CC_set)
  );
  ("shrq-flags-amt1", machine_test_cc
    [Movq, [~$(-1); ~%Rax]; Shrq, [~$1; ~%Rax]]
    (CC_set, CC_cleared, CC_cleared)
  );
   (* if AMT<>1 then fo is unaffected *)
  ("sarq-flags-amt3", machine_test_cc
    [Movq, [~$(-42); ~%Rax]; Sarq, [~$3; ~%Rax]]
    (CC_unchanged, CC_set, CC_cleared)
  );
  ("shlq-flags-amt3", machine_test_cc
    [Movq, [~$(-42); ~%Rax]; Shlq, [~$3; ~%Rax]]
    (CC_unchanged, CC_set, CC_cleared)
  );
  ("shrq-flags-amt3", machine_test_cc
    [Movq, [~$(-42); ~%Rax]; Shrq, [~$3; ~%Rax]]
    (CC_unchanged, CC_cleared, CC_cleared)
  );
  ]);
  Test ("End-to-end Factorial", [
    ("fact6-iter", program_test (factorial_iter 6) 720L);
  ]);
]
