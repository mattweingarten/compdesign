(* X86lite Simulator *)

(* See the documentation in the X86lite specification, available on the
   course web pages, for a detailed explanation of the instruction
   semantics.
*)

open X86

(* simulator machine state -------------------------------------------------- *)

let mem_bot = 0x400000L          (* lowest valid address *)
let mem_top = 0x410000L          (* one past the last byte in memory *)
let mem_size = Int64.to_int (Int64.sub mem_top mem_bot)
let nregs = 17                   (* including Rip *)
let ins_size = 8L                (* assume we have a 8-byte encoding *)
let exit_addr = 0xfdeadL         (* halt when m.regs(%rip) = exit_addr *)

(* Your simulator should raise this exception if it tries to read from or
   store to an address not within the valid address space. *)
exception X86lite_segfault

(* The simulator memory maps addresses to symbolic bytes.  Symbolic
   bytes are either actual data indicated by the Byte constructor or
   'symbolic instructions' that take up four bytes for the purposes of
   layout.

   The symbolic bytes abstract away from the details of how
   instructions are represented in memory.  Each instruction takes
   exactly eight consecutive bytes, where the first byte InsB0 stores
   the actual instruction, and the next sevent bytes are InsFrag
   elements, which aren't valid data.

   For example, the two-instruction sequence:
        at&t syntax             ocaml syntax
      movq %rdi, (%rsp)       Movq,  [~%Rdi; Ind2 Rsp]
      decq %rdi               Decq,  [~%Rdi]

   is represented by the following elements of the mem array (starting
   at address 0x400000):

       0x400000 :  InsB0 (Movq,  [~%Rdi; Ind2 Rsp])
       0x400001 :  InsFrag
       0x400002 :  InsFrag
       0x400003 :  InsFrag
       0x400004 :  InsFrag
       0x400005 :  InsFrag
       0x400006 :  InsFrag
       0x400007 :  InsFrag
       0x400008 :  InsB0 (Decq,  [~%Rdi])
       0x40000A :  InsFrag
       0x40000B :  InsFrag
       0x40000C :  InsFrag
       0x40000D :  InsFrag
       0x40000E :  InsFrag
       0x40000F :  InsFrag
       0x400010 :  InsFrag
*)
type sbyte = InsB0 of ins       (* 1st byte of an instruction *)
           | InsFrag            (* 2nd - 7th bytes of an instruction *)
           | Byte of char       (* non-instruction byte *)

(* memory maps addresses to symbolic bytes *)
type mem = sbyte array

(* Flags for condition codes *)
type flags = { mutable fo : bool
             ; mutable fs : bool
             ; mutable fz : bool
             }

(* Register files *)
type regs = int64 array

(* Complete machine state *)
type mach = { flags : flags
            ; regs : regs
            ; mem : mem
            }

(* simulator helper functions ----------------------------------------------- *)

(* The index of a register in the regs array *)
let rind : reg -> int = function
  | Rip -> 16
  | Rax -> 0  | Rbx -> 1  | Rcx -> 2  | Rdx -> 3
  | Rsi -> 4  | Rdi -> 5  | Rbp -> 6  | Rsp -> 7
  | R08 -> 8  | R09 -> 9  | R10 -> 10 | R11 -> 11
  | R12 -> 12 | R13 -> 13 | R14 -> 14 | R15 -> 15

(* Helper functions for reading/writing sbytes *)

(* Convert an int64 to its sbyte representation *)
let sbytes_of_int64 (i:int64) : sbyte list =
  let open Char in
  let open Int64 in
  List.map (fun n -> Byte (shift_right i n |> logand 0xffL |> to_int |> chr))
    [0; 8; 16; 24; 32; 40; 48; 56]

(* Convert an sbyte representation to an int64 *)
let int64_of_sbytes (bs:sbyte list) : int64 =
  let open Char in
  let open Int64 in
  let f b i = match b with
    | Byte c -> logor (shift_left i 8) (c |> code |> of_int)
    | _ -> 0L
  in
  List.fold_right f bs 0L

(* Convert a string to its sbyte representation *)
let sbytes_of_string (s:string) : sbyte list =
  let rec loop acc = function
    | i when i < 0 -> acc
    | i -> loop (Byte s.[i]::acc) (pred i)
  in
  loop [Byte '\x00'] @@ String.length s - 1

(* Serialize an instruction to sbytes *)
let sbytes_of_ins (op, args:ins) : sbyte list =
  let check = function
    | Imm (Lbl _) | Ind1 (Lbl _) | Ind3 (Lbl _, _) ->
      invalid_arg "sbytes_of_ins: tried to serialize a label!"
    | o -> ()
  in
  List.iter check args;
  [InsB0 (op, args); InsFrag; InsFrag; InsFrag; InsFrag; InsFrag; InsFrag; InsFrag]

(* Serialize a data element to sbytes *)
let sbytes_of_data : data -> sbyte list = function
  | Quad (Lit i) -> sbytes_of_int64 i
  | Asciz s -> sbytes_of_string s
  | Quad (Lbl _) -> invalid_arg "sbytes_of_data: tried to serialize a label!"


(* It might be useful to toggle printing of intermediate states of your
   simulator. *)
let debug_simulator = ref false

(* Interpret a condition code with respect to the given flags. *)
let interp_cnd {fo; fs; fz} : cnd -> bool = fun x ->
  begin match x with
    | Eq -> fz
    | Neq -> not fz
    | Gt -> (fo = fs) && (not fz)
    | Ge -> (fo = fs)
    | Lt -> fo != fs
    | Le -> (fo != fs) || fz
  end


(* Maps an X86lite address into Some OCaml array index,
   or None if the address is not within the legal address space. *)
let map_addr (addr:quad) : int option =
  if addr >= mem_bot && addr < mem_top then
    Some (Int64.to_int (Int64.sub addr mem_bot))
  else
    None

(* Get option or throw segfault *)
let get_option o =
  begin match o with
    | Some x -> x
    | None -> raise X86lite_segfault
  end

(* get source from list *)
let get_src l = List.nth_opt l 0

(* get dst from list *)
let get_dst l = List.nth_opt l 1

(* map addr and extract option *)
let get_addr a = get_option @@ map_addr a

(* Simulates one step of the machine:
   - fetch the instruction at %rip
   - compute the source and/or destination information from the operands
   - simulate the instruction semantics
   - update the registers and/or memory appropriately
   - set the condition flags
*)
let step (m:mach) : unit =
  let interp_imm (i:imm) =
    begin match i with
      | Lit li -> li
      | Lbl lb -> raise @@ Invalid_argument "lbl not resolved"
    end in
  let interp_reg (r:reg) = m.regs.(rind r) in
  let interp_op (op:operand) : quad =
    begin match op with
      | Imm i | Ind1 i -> interp_imm i
      | Reg r | Ind2 r -> interp_reg r
      | Ind3 (i, r) -> Int64.add (interp_reg r) (interp_imm i)
    end in
  let rec get_ops (os:operand list) =
    begin match os with
      | [] -> []
      | o::ops -> (interp_op o)::(get_ops ops)
    end in
  let set_sign (v:quad) =
    let sign = Int64.shift_right_logical v 63 in
    if sign = 1L then m.flags.fs <- true
    else m.flags.fs <- false in
  let set_zero (v:quad) =
    if v = 0L then m.flags.fz <- true
    else m.flags.fz <- false in
  let rec store_sbytes bytes addr =
    Printf.printf "storing bytes at *%s\n" @@ Int64.to_string addr;
    begin match bytes with
      | [] -> ()
      | hd::tl ->
        let m_addr = get_addr addr in
        Printf.printf "mapped index *%d\n" m_addr;
        m.mem.(m_addr) <- hd;
        store_sbytes tl (Int64.succ addr)
    end in
  let store_res (res:quad) (d_op:operand) (d_addr:quad)=
    begin match d_op with
      | Reg reg -> m.regs.(rind reg) <- res
      | _ ->
        let res_sbytes = sbytes_of_int64 res in
        Printf.printf "addr %s res %s\n" (Int64.to_string d_addr) (Int64.to_string res);
        store_sbytes res_sbytes d_addr
    end in
  let instr = m.mem.(get_addr m.regs.(rind Rip)) in
  let rip_next =
    m.regs.(rind Rip) <- Int64.add m.regs.(rind Rip) 8L;
    begin match m.mem.(get_addr m.regs.(rind Rip)) with
      | InsB0 _ -> ()
      | _ -> m.regs.(rind Rip) <- exit_addr
    end;
    Printf.printf "new rip %s\n" @@ Int64.to_string m.regs.(rind Rip) in
  begin match instr with
    | InsB0 (oc, os) ->
      let ops = get_ops os in
      let src = get_src ops in
      let d_op = get_dst os in
      let d_addr = get_dst ops in
      begin match oc with
        | Leaq ->
          begin match (List.hd os) with
            | Ind1 _ | Ind2 _ | Ind3 _ ->
              store_res (get_option src) (get_option d_op) (get_option d_addr)
            | _ -> raise @@ Invalid_argument "expected ind"
          end
        | Movq -> store_res (get_option src) (get_option d_op) (get_option d_addr)
        | Pushq -> 
          m.regs.(rind Rsp) <- Int64.sub m.regs.(rind Rsp) 8L;
          store_sbytes (sbytes_of_int64 @@ get_option src) m.regs.(rind Rsp)
        | _ -> ()
      end
    | _ -> ()
  end

(*
      Movq | Pushq | Popq
            | Leaq
            | Incq | Decq | Negq | Notq
            | Addq | Subq | Imulq | Xorq | Orq | Andq
            | Shlq | Sarq | Shrq
            | Cmpq
            | Jmp | Je | Jne | Jg | Jge | Jl | Jle
            | Callq | Retq
*)

(* Runs the machine until the rip register reaches a designated
   memory address. *)
let run (m:mach) : int64 =
  while m.regs.(rind Rip) <> exit_addr do step m done;
  m.regs.(rind Rax)

(* assembling and linking --------------------------------------------------- *)

(* A representation of the executable *)
type exec = { entry    : quad              (* address of the entry point *)
            ; text_pos : quad              (* starting address of the code *)
            ; data_pos : quad              (* starting address of the data *)
            ; text_seg : sbyte list        (* contents of the text segment *)
            ; data_seg : sbyte list        (* contents of the data segment *)
            }

(* Assemble should raise this when a label is used but not defined *)
exception Undefined_sym of lbl

(* Assemble should raise this when a label is defined more than once *)
exception Redefined_sym of lbl

(* Convert an X86 program into an object file:
   - separate the text and data segments
   - compute the size of each segment
      Note: the size of an Asciz string section is (1 + the string length)

   - resolve the labels to concrete addresses and 'patch' the instructions to
     replace Lbl values with the corresponding Imm values.

   - the text segment starts at the lowest address
   - the data segment starts after the text segment

   HINT: List.fold_left and List.fold_right are your friends.
*)
let assemble (p:prog) : exec =
  failwith "assemble unimplemented"

(* Convert an object file into an executable machine state.
   - allocate the mem array
   - set up the memory state by writing the symbolic bytes to the
      appropriate locations
   - create the inital register state
   - initialize rip to the entry point address
   - initializes rsp to the last word in memory
   - the other registers are initialized to 0
   - the condition code flags start as 'false'

   Hint: The Array.make, Array.blit, and Array.of_list library functions
   may be of use.
*)
let load {entry; text_pos; data_pos; text_seg; data_seg} : mach =
  failwith "load unimplemented"
