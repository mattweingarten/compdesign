open Assert
open X86
open Asm
open Simulator
open Gradedtests

(** Creates memory layout out of given instructions. *)
let sbytes_of_ins (instructions:ins list) : sbyte list =
  List.concat @@ List.map (fun i -> [InsB0 i;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag;InsFrag]) instructions

(** Creates machine out of given instructions. *)
let machine_of_ins (instructions:ins list) : mach =
  sbytes_of_ins instructions |> test_machine

(** Creates machine out of given instructions and data. *)
let machine_of_ins2 (instructions:ins list) (data:sbyte list) : mach =
  sbytes_of_ins instructions @ data |> test_machine

(** Check if memory has given value at given address. *)
let check_memory (memory:mem) (address:int64) (value:int64) : bool =
  value = int64_of_sbytes @@ Array.to_list @@ Array.sub memory (get_option @@ map_addr address) 8

let b0 = Byte '\x00'
let bff = Byte '\xff'

let provided_tests : suite = [

  Test ("Student-Provided Tests For step", [
    ("movq1", machine_test "rax=5" 1 (machine_of_ins [Movq, [~$5; ~%Rax]])
      (fun {regs} -> regs.(rind Rax) = 5L));
    ("movq2", machine_test "rax=*0x400010=65" 2 (machine_of_ins [
        Movq, [~$65; Ind1 (Lit 0x400010L)];
        Movq, [Ind1 (Lit 0x400010L); ~%Rax];
      ]) (fun {regs;mem} -> regs.(rind Rax) = 65L && mem.(16) = Byte 'A'));
    ("movq3", machine_test "rax=*0x400018=66" 3 (machine_of_ins [
        Movq, [~$0x400018; ~%Rax];
        Movq, [~$66; Ind2 Rax];
        Movq, [Ind2 Rax; ~%Rax];
      ]) (fun {regs;mem} -> regs.(rind Rax) = 66L && mem.(24) = Byte 'B'));
    ("movq4", machine_test "rax=*0x400020=67" 3 (machine_of_ins [
        Movq, [~$0x400018; ~%Rax];
        Movq, [~$67; Ind3 (Lit 8L, Rax)];
        Movq, [Ind3 (Lit 8L, Rax); ~%Rax];
      ]) (fun {regs;mem} -> regs.(rind Rax) = 67L && mem.(32) = Byte 'C'));
    ("movq5", machine_test "rax=*0x400021=MIN_INT" 3 (machine_of_ins [
        Movq, [~$0x400018; ~%Rax];
        Movq, [~$0x80; Ind3 (Lit 16L, Rax)];
        Movq, [Ind3 (Lit 9L, Rax); ~%Rax];
      ]) (fun {regs;mem} -> regs.(rind Rax) = Int64.min_int && mem.(40) = Byte '\x80'));
    (* Segfault on invalid memory access *)
    ("movq6", fun () -> try (machine_test "segfault" 1 (machine_of_ins [
        Movq, [Ind1 (Lit 0x410000L); ~%Rax];
      ]) (fun _ -> true) ());
      failwith "bad address" with X86lite_segfault -> ());
    ("movq7", fun () -> try (machine_test "segfault" 2 (machine_of_ins [
        Movq, [~$0x3ffffff; ~%Rax];
        Movq, [Ind2 Rax; ~%Rax];
      ]) (fun _ -> true) ());
      failwith "bad address" with X86lite_segfault -> ());
    ("movq8", fun () -> try (machine_test "segfault" 2 (machine_of_ins [
        Movq, [~$0x410000; ~%Rax];
        Movq, [Ind3 (Lit (-7L), Rax); ~%Rax];
      ]) (fun _ -> true) ());
      failwith "bad address" with X86lite_segfault -> ());

    ("negq1", machine_test "rax=-5" 2 (machine_of_ins [
        Movq, [~$5; ~%Rax];
        Negq, [~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = -5L));
    ("negq2", machine_test "rax=MIN_INT" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Negq, [~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.min_int &&
        flags.fo && flags.fs && not flags.fz));
    ("negq3", machine_test "rax=MIN_INT+1" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.max_int); ~%Rax];
        Negq, [~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.add Int64.min_int 1L &&
        not flags.fo && flags.fs && not flags.fz));

    ("incq1", machine_test "rax=5" 2 (machine_of_ins [
        Movq, [~$4; ~%Rax];
        Incq, [~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 5L));
    ("incq2", machine_test "rax=MIN_INT" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.max_int); ~%Rax];
        Incq, [~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.min_int &&
        flags.fo && flags.fs && not flags.fz));

    ("decq1", machine_test "rax=5" 2 (machine_of_ins [
        Movq, [~$6; ~%Rax];
        Decq, [~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 5L));
    ("decq2", machine_test "rax=MAX_INT" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Decq, [~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.max_int &&
        flags.fo && not flags.fs && not flags.fz));

    ("addq1", machine_test "rax=55" 2 (machine_of_ins [
        Movq, [~$4; ~%Rax];
        Addq, [~$51; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 55L));
    ("addq2", machine_test "rax=MIN_INT+4" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.max_int); ~%Rax];
        Addq, [~$5; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.add Int64.min_int 4L &&
        flags.fo && flags.fs && not flags.fz));

    ("subq1", machine_test "rax=55" 2 (machine_of_ins [
        Movq, [~$100; ~%Rax];
        Subq, [~$45; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 55L));
    ("subq2", machine_test "rax=MIN_INT" 2 (machine_of_ins [
        Movq, [Imm (Lit (Int64.add Int64.min_int 3L)); ~%Rax];
        Subq, [~$3; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.min_int &&
        not flags.fo && flags.fs && not flags.fz));
    ("subq3", machine_test "rax=MAX_INT" 2 (machine_of_ins [
        Movq, [Imm (Lit (Int64.add Int64.min_int 3L)); ~%Rax];
        Subq, [~$4; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.max_int &&
        flags.fo && not flags.fs && not flags.fz));
    ("subq4", machine_test "rax=0" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Subq, [Imm (Lit Int64.min_int); ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = 0L &&
        flags.fo && not flags.fs && flags.fz));

    ("cmpq1", machine_test "rax=100" 2 (machine_of_ins [
        Movq, [~$100; ~%Rax];
        Cmpq, [~$45; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 100L));
    ("cmpq2", machine_test "rax=MIN_INT+3" 2 (machine_of_ins [
        Movq, [Imm (Lit (Int64.add Int64.min_int 3L)); ~%Rax];
        Cmpq, [~$3; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.add Int64.min_int 3L &&
        not flags.fo && flags.fs && not flags.fz));
    ("cmpq3", machine_test "rax=MAX_INT+3" 2 (machine_of_ins [
        Movq, [Imm (Lit (Int64.add Int64.min_int 3L)); ~%Rax];
        Cmpq, [~$4; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.add Int64.min_int 3L &&
        flags.fo && not flags.fs && not flags.fz));
    ("cmpq4", machine_test "rax=MIN_INT" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Cmpq, [Imm (Lit Int64.min_int); ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = Int64.min_int &&
        flags.fo && not flags.fs && flags.fz));
    (* Compq does not need a destination *)
    ("cmpq5", machine_test "OF=1 FS=0 FZ=1" 1 (machine_of_ins [
        Cmpq, [Imm (Lit Int64.min_int); Imm (Lit Int64.min_int)];
      ]) (fun {flags} -> flags.fo && not flags.fs && flags.fz));

    ("imulq1", machine_test "rax=55" 2 (machine_of_ins [
        Movq, [~$5; ~%Rax];
        Imulq, [~$11; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 55L));
    ("imulq2", machine_test "rax=MAX_INT rbx=MIN_INT" 4 (machine_of_ins [
        Movq, [Imm (Lit Int64.max_int); ~%Rax];
        Imulq, [~$1; ~%Rax];
        Movq, [Imm (Lit Int64.min_int); ~%Rbx];
        Imulq, [~$1; ~%Rbx];
      ]) (fun {flags;regs} -> not flags.fo && (* ZF and SF undefined *)
        regs.(rind Rax) = Int64.max_int &&
        regs.(rind Rbx) = Int64.min_int));
    ("imulq3", machine_test "rax=4 and OF" 2 (machine_of_ins [
        Movq, [Imm (Lit 0x4000000000000001L); ~%Rax];
        Imulq, [~$4; ~%Rax];
      ]) (fun {flags;regs} -> flags.fo (* ZF and SF undefined *) &&
        regs.(rind Rax) = 4L));
    ("imulq4", machine_test "rax=0 and OF" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Imulq, [~$2; ~%Rax];
      ]) (fun {flags;regs} -> flags.fo (* ZF and SF undefined *) &&
        regs.(rind Rax) = 0L));

    ("notq1", machine_test "rax=-1" 2 (machine_of_ins [
        Movq, [~$0; ~%Rax];
        Notq, [~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = -1L));
    ("notq2", machine_test "rax=MIN_INT" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.max_int); ~%Rax];
        Notq, [~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = Int64.min_int));

    ("andq1", machine_test "rax=0b00101" 2 (machine_of_ins [
        Movq, [~$0b00111; ~%Rax];
        Andq, [~$0b01101; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = 0b00101L &&
        not flags.fo && not flags.fs && not flags.fz));
    ("andq2", machine_test "rax=0" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Andq, [Imm (Lit Int64.max_int); ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = 0L &&
        not flags.fo && not flags.fs && flags.fz));

    ("orq1", machine_test "rax=0b01111" 2 (machine_of_ins [
        Movq, [~$0b00111; ~%Rax];
        Orq,  [~$0b01101; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = 0b01111L &&
        not flags.fo && not flags.fs && not flags.fz));
    ("orq2", machine_test "rax=-1" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Orq,  [Imm (Lit Int64.max_int); ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = -1L &&
        not flags.fo && flags.fs && not flags.fz));

    ("xorq1", machine_test "rax=0b01010" 2 (machine_of_ins [
        Movq, [~$0b00111; ~%Rax];
        Xorq, [~$0b01101; ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = 0b01010L &&
        not flags.fo && not flags.fs && not flags.fz));
    ("xorq2", machine_test "rax=-1" 2 (machine_of_ins [
        Movq, [Imm (Lit Int64.min_int); ~%Rax];
        Xorq, [Imm (Lit Int64.max_int); ~%Rax];
      ]) (fun {flags;regs} -> regs.(rind Rax) = -1L &&
        not flags.fo && flags.fs && not flags.fz));

    ("leaq1", machine_test "rax=0x400000" 1 (machine_of_ins [
        Leaq, [Ind1 (Lit 0x400000L); ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 0x400000L));
    ("leaq2", machine_test "rax=0x400010" 2 (machine_of_ins [
        Movq, [~$0x400010; ~%Rax];
        Leaq, [Ind2 Rax; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 0x400010L));
    ("leaq3", machine_test "rax=0x400020" 2 (machine_of_ins [
        Movq, [~$0x400010; ~%Rax];
        Leaq, [Ind3 (Lit 0x10L, Rax); ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 0x400020L));
    (* Invalid addresses do not segfault until accessed *)
    ("leaq4", machine_test "rax=0" 2 (machine_of_ins [
        Movq, [~$0; ~%Rax];
        Leaq, [Ind2 Rax; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 0L));
    ("leaq5", machine_test "rax=0x410000" 1 (machine_of_ins [
        Leaq, [Ind1 (Lit 0x410000L); ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 0x410000L));
    ("leaq6", fun () -> try (machine_test "segfault" 2 (machine_of_ins [
        Leaq, [Ind1 (Lit 0x410000L); ~%Rax];
        Movq, [Ind2 Rax; ~%Rax];
      ]) (fun _ -> true) ());
      failwith "bad address" with X86lite_segfault -> ());
    (* As answered by Yichen Yan on moodle *)
    ("leaq7", machine_test "rax=0x400008L" 1 (machine_of_ins [
        Leaq, [Ind2 Rip; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 0x400008L));

    ("setb1", machine_test "rax=rdx=r09=1 rbx=rcx=r08=0" 8 (machine_of_ins [
        Movq, [~$0; ~%Rax];
        Cmpq, [~$0; ~$0];
        Set Eq, [~%Rax];
        Set Neq, [~%Rbx];
        Set Gt, [~%Rcx];
        Set Ge, [~%Rdx];
        Set Lt, [~%R08];
        Set Le, [~%R09];
      ]) (fun {regs} ->
        regs.(rind Rax) = 1L && regs.(rind Rdx) = 1L && regs.(rind R09) = 1L &&
        regs.(rind Rbx) = 0L && regs.(rind Rcx) = 0L && regs.(rind R08) = 0L));
    ("setb2", machine_test "rbx=r08=r09=1 rax=rcx=rdx=0" 8 (machine_of_ins [
        Movq, [~$0; ~%Rax];
        Cmpq, [~$5; ~$(-5)];
        Set Eq, [~%Rax];
        Set Neq, [~%Rbx];
        Set Gt, [~%Rcx];
        Set Ge, [~%Rdx];
        Set Lt, [~%R08];
        Set Le, [~%R09];
      ]) (fun {regs} ->
        regs.(rind Rbx) = 1L && regs.(rind R08) = 1L && regs.(rind R09) = 1L &&
        regs.(rind Rax) = 0L && regs.(rind Rcx) = 0L && regs.(rind Rdx) = 0L));
    (* setq does only access lowest byte *)
    ("setb3", machine_test "*0x400018=0x01ffffffffffffff" 3 (machine_of_ins [
        Movq, [~$(-1); Ind1 (Lit 0x400018L)];
        Cmpq, [~$0; ~$0];
        Set Eq, [Ind1 (Lit 0x400018L)];
      ]) (fun {mem} -> Array.sub mem 24 8 = [|Byte '\x01';bff;bff;bff;bff;bff;bff;bff|]));
    ("setb4", machine_test "*0x400018=0x00ffffffffffffff" 3 (machine_of_ins [
        Movq, [~$(-1); Ind1 (Lit 0x400018L)];
        Cmpq, [~$0; ~$0];
        Set Neq, [Ind1 (Lit 0x400018L)];
      ]) (fun {mem} -> Array.sub mem 24 8 = [|b0;bff;bff;bff;bff;bff;bff;bff|]));

    ("jmp1", machine_test "rax=5" 3 (machine_of_ins [
        Movq, [~$5; ~%Rax];
        Jmp, [~$0x400000];
        Movq, [~$1337; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 5L));
    ("jmp2", machine_test "rax=5" 3 (machine_of_ins [
        Movq, [~$5; ~%Rax];
        Jmp, [~$0x400008];
        Movq, [~$1337; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 5L));
    ("jmp3", machine_test "rax=5" 4 (machine_of_ins [
        Movq, [~$5; ~%Rax];
        Movq, [~$0x400000; ~%Rbx];
        Jmp, [Reg Rbx];
        Movq, [~$1337; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 5L));

    ("j1", machine_test "rax=5" 4 (machine_of_ins [
        Movq, [~$5; ~%Rax];
        Cmpq, [~$0; ~$0];
        J Eq, [~$0x400000];
        Movq, [~$1337; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 5L));
    ("j2", machine_test "rax=1337" 4 (machine_of_ins [
        Movq, [~$5; ~%Rax];
        Cmpq, [~$0; ~$0];
        J Neq, [~$0x400000];
        Movq, [~$1337; ~%Rax];
      ]) (fun {regs} -> regs.(rind Rax) = 1337L));

    ("pushq1", machine_test "rsp=0x40fff0 *0x40fff0=5" 1 (machine_of_ins [
        Pushq, [~$5];
      ]) (fun {regs;mem} ->
        regs.(rind Rsp) = Int64.sub mem_top 16L &&
        check_memory mem (Int64.sub mem_top 16L) 5L));
    ("pushq2", machine_test "rsp=0x40ffe0 *0x40fff0=5 *0x40ffe8=13 *0x40ffe0=59" 3 (machine_of_ins [
        Pushq, [~$5];
        Pushq, [~$13];
        Pushq, [~$59];
      ]) (fun {regs;mem} ->
        regs.(rind Rsp) = Int64.sub mem_top 32L &&
        check_memory mem (Int64.sub mem_top 16L) 5L &&
        check_memory mem (Int64.sub mem_top 24L) 13L &&
        check_memory mem (Int64.sub mem_top 32L) 59L));

    ("popq1", machine_test "rax=13 rsp=0x40ffe8 *0x40fff0=5" 3 (machine_of_ins [
        Pushq, [~$5];
        Pushq, [~$13];
        Popq, [~%Rax];
      ]) (fun {regs;mem} ->
        regs.(rind Rax) = 13L &&
        regs.(rind Rsp) = Int64.sub mem_top 16L &&
        check_memory mem (Int64.sub mem_top 16L) 5L));
    ("popq2", machine_test "rax=13 rsp=0x40ffe8 *0x40fff0=5" 5 (machine_of_ins [
        Pushq, [~$5];
        Pushq, [~$13];
        Pushq, [~$59];
        Popq, [~%Rax];
        Popq, [~%Rax];
      ]) (fun {regs;mem} ->
        regs.(rind Rax) = 13L &&
        regs.(rind Rsp) = Int64.sub mem_top 16L &&
        check_memory mem (Int64.sub mem_top 16L) 5L));
    ("popq3", machine_test "rax=-1337 rsp=0x40fff8" 6 (machine_of_ins [
        Pushq, [~$27];
        Pushq, [~$42];
        Popq, [~%Rax];
        Popq, [~%Rax];
        Pushq, [~$(-1337)];
        Popq, [~%Rax];
      ]) (fun {regs;mem} ->
        regs.(rind Rax) = -1337L &&
        regs.(rind Rsp) = Int64.sub mem_top 8L));

    ("callq1", machine_test "rsp=0x40fff0 rip=0x400020 *0x40fff0=0x400008" 1 (machine_of_ins [
        Callq, [~$0x400020];
      ]) (fun {regs;mem} ->
        regs.(rind Rsp) = Int64.sub mem_top 16L &&
        regs.(rind Rip) = 0x400020L &&
        check_memory mem (Int64.sub mem_top 16L) 0x400008L));
    ("callq2", machine_test "rsp=0x40ffe8 rip=0x400030 *0x40fff0=0x400008 *0x40ffe8=0x400010" 2 (machine_of_ins [
        Callq, [~$0x400008];
        Callq, [~$0x400030];
      ]) (fun {regs;mem} ->
        regs.(rind Rsp) = Int64.sub mem_top 24L &&
        regs.(rind Rip) = 0x400030L &&
        check_memory mem (Int64.sub mem_top 16L) 0x400008L &&
        check_memory mem (Int64.sub mem_top 24L) 0x400010L));

    ("retq1", machine_test "rsp=0x40fff8 rip=0x400008 rax=5" 3 (machine_of_ins [
        Callq, [~$0x400010];
        Movq, [~$42; ~%Rax];
        Movq, [~$5; ~%Rax];
        Retq, [];
      ]) (fun {regs;mem} ->
        regs.(rind Rsp) = Int64.sub mem_top 8L &&
        regs.(rind Rip) = 0x400008L &&
        regs.(rind Rax) = 5L));
  ]);

]
