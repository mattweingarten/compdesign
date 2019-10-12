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


(* step helper functions ---------------------------------------------------- *)
(* Get option or throw segfault *)
let get_option o =
  begin match o with
    | Some x -> x
    | None -> raise X86lite_segfault
  end

let ops_check (ops:operand list) (min:int) = 
  if (List.length ops) < min then invalid_arg "too few operands"

(* get source from list *)
let get_src (ops:operand list) : operand = 
  ops_check ops 1;
  List.nth ops 0

(* get dst from list *)
let get_dst (ops:operand list) : operand = 
  ops_check ops 2;
  List.nth ops 1

(* map addr and extract option *)
let get_addr (addr:quad) : int = get_option @@ map_addr addr

(* Simulates one step of the machine:
   - fetch the instruction at %rip
   - compute the source and/or destination information from the operands
   - simulate the instruction semantics
   - update the registers and/or memory appropriately
   - set the condition flags
*)
let step (m:mach) : unit =
  let open Int64_overflow in (* to avoid warning 40 *)
  (*=== HELPER FUNCTIONS ===================================================*)
  (*=== interpreters ===*)
  (* interpret an imm *)
  let interp_imm (i:imm) = 
    begin match i with
      | Lit li -> li
      | Lbl lb -> raise @@ Invalid_argument "lbl not resolved"
    end
  in

  (* interpret a reg *)
  let interp_reg (r:reg) = m.regs.(rind r) in 

  (* interpret an operand *)
  let interp_op (op:operand) : quad = 
    begin match op with
      | Imm i | Ind1 i -> interp_imm i
      | Reg r | Ind2 r -> interp_reg r
      | Ind3 (i, r) -> Int64.add (interp_reg r) (interp_imm i)
    end
  in

  (* get value from mem at addr *)
  let int64_from_mem (addr:quad) = 
    int64_of_sbytes @@ Array.to_list @@ Array.sub m.mem (get_addr addr) 8
  in

  (* get the value of an operand, either reg content or mem content at addr *)
  let get_value (op: operand) : quad = 
    let interp = interp_op op in
    begin match op with
      | Imm _ | Reg _ -> interp
      | _ -> int64_from_mem interp
    end 
  in

  (* get shift amount *)
  let get_amt (op:operand) =   
    begin match op with 
      | Reg Rcx | Imm _ -> Int64.to_int @@ interp_op op
      | _ -> raise @@ Invalid_argument "expected either imm or rcx"
    end 
  in

  (* resolve opcode to a binary arithmentic operation *)
  let get_bin_arith_operation (oc:opcode) = 
    begin match oc with
      | Addq -> Int64_overflow.add
      | Subq -> Int64_overflow.sub
      | Imulq -> Int64_overflow.mul
      | _ -> invalid_arg ("unsupported opcode " ^ (string_of_opcode oc))
    end 
  in

  (* resolve opcode to a unary arithmetic operation *)
  let get_un_arith_operation (oc:opcode) = 
    begin match oc with
      | Negq -> Int64_overflow.neg
      | Incq -> Int64_overflow.succ
      | Decq -> Int64_overflow.pred
      | _ -> invalid_arg ("unsupported opcode " ^ (string_of_opcode oc))
    end
  in

  (* resolve opcode to a binary logic operation *)
  let get_bin_logic_op (oc:opcode) = 
    begin match oc with
      | Andq -> Int64.logand
      | Orq -> Int64.logor
      | Xorq -> Int64.logxor
      | _ -> invalid_arg ("unsupported opcode " ^ (string_of_opcode oc))
    end
  in

  (* resolve opcode to a shift operation *)
  let get_shift_op (oc:opcode) = 
    begin match oc with
      | Sarq -> Int64.shift_right
      | Shrq -> Int64.shift_right_logical
      | Shlq -> Int64.shift_left
      | _ -> invalid_arg ("unsupported opcode " ^ (string_of_opcode oc))
    end 
  in

  (*=== Data manipulators ===*)
  (* store sbytes_list in mem at addr *)
  let rec store_sbytes (bytes:sbyte list) (addr:quad) = 
    Array.blit (Array.of_list bytes) 0 m.mem (get_addr addr) (List.length bytes) in

  (* store result to the adequate location *)
  let store_res (res:quad) (d_op:operand) (addr:quad) = 
    begin match d_op with
      | Reg reg -> m.regs.(rind reg) <- res
      | _ -> store_sbytes (sbytes_of_int64 res) addr
    end 
  in 

  (* set the LSB to b (0 or 1) *)
  let set_LSB (b:quad) (d_op) =  
    begin match d_op with
      | Reg reg -> 
        let mask = Int64.logor 0xfffffffffffffffeL b in
        let r = Int64.logand mask (interp_op d_op) in
        m.regs.(rind reg) <- r
      | _ ->
        let byte = Byte (Char.chr @@ Int64.to_int b) in
        m.mem.((get_addr @@ interp_op d_op) + 7) <- byte 
    end 
  in

  (* set zero flag *)
  let set_zero (v:quad) =   
    if Int64.equal v 0L then m.flags.fz <- true
    else m.flags.fz <- false
  in 

  (* set sign flag *)
  let set_sign (v:quad) =  
    let msb = Int64.shift_right_logical v 63 in
    if Int64.equal msb 1L then m.flags.fs <- true
    else m.flags.fs <- false 
  in

  (* set zero and sign flags *)
  let set_flags1 (v:quad) = set_sign v; set_zero v in  

  (* set all flags *)
  let set_flags2 (v:Int64_overflow.t) = 
    set_flags1 v.value; 
    m.flags.fo <- v.overflow 
  in 

  (*=== Instructions ===*)
  (*=== Arithmetic instructions ===*) 
  let bin_arith_instr (op:opcode) (operands:operand list) : unit=
    let dest_operand = get_dst operands in
    let dest = interp_op dest_operand in
    let dest_val = get_value dest_operand in
    let src = get_value @@ get_src operands in
    let result = get_bin_arith_operation op dest_val src in
    store_res result.value dest_operand dest; 
    set_flags2 result
  in

  let un_arith_instr (op:opcode) (operands:operand list) : unit=
    let dest_operand = get_src operands in
    let dst_addr = interp_op dest_operand in
    let dst_val = get_value dest_operand in
    let result = get_un_arith_operation op dst_val in
    store_res result.value dest_operand dst_addr; set_flags2 result
  in

  (*=== Logic instructions ===*)
  let notq_instr (op:opcode) (operands:operand list) :unit =
    let dst_op = get_src operands in
    let dst_addr = interp_op dst_op in
    let dst_val = get_value dst_op in
    let result = Int64.lognot dst_val in
    store_res result dst_op dst_addr
  in

  let bin_logic_instr (op:opcode) (operands:operand list) :unit =
    let operation = get_bin_logic_op op in
    let src = get_src  operands in
    let src_val = get_value src in
    let dest = get_dst operands in
    let dst_addr = interp_op dest in
    let dst_val = get_value dest in
    let result = operation dst_val src_val in
    store_res result dest dst_addr; set_flags1 result; m.flags.fo <- false
  in

  (*=== Bit manipulation instructions ===*)
  let shift_instr (oc:opcode) (dst:operand) amt : quad = 
    let dst_val = get_value dst in
    let shifted = get_shift_op oc dst_val amt in
    if amt != 0 then set_flags1 shifted; 
    shifted 
  in

  let sarq_instr (os:operand list) = 
    let amt = get_amt (get_src os) in
    let dst_op = get_dst os in
    let shifted = shift_instr Sarq dst_op amt in
    store_res shifted dst_op (interp_op dst_op); 
    if amt = 1 then m.flags.fo <- false
  in

  let shlq_instr (os:operand list) = 
    let amt = get_amt (get_src os) in
    let dst_op = get_dst os in
    let shifted = shift_instr Shlq dst_op amt in
    let top2 = Int64.shift_right_logical shifted 62 in 
    store_res shifted dst_op (interp_op dst_op);
    if amt = 1 && (Int64.equal top2 0L || Int64.equal top2 3L) then m.flags.fo <- true
  in

  let shrq_instr (os:operand list) = 
    let amt = get_amt (get_src os) in
    let dst_op = get_dst os in
    let shifted = shift_instr Shrq dst_op amt in
    let msb = Int64.shift_right_logical shifted 63 in
    store_res shifted dst_op (interp_op dst_op);
    if amt = 1 then m.flags.fo <- if Int64.equal msb 1L then true else false 
  in

  let set_instr (os:operand list) cc = 
    let cc_res = interp_cnd m.flags cc in
    let cc_int = if cc_res then 1L else 0L in
    set_LSB cc_int (get_src os)
  in

  (*=== Data movement instructions ===*)
  let leaq_instr (os:operand list) = 
    begin match (List.hd os) with
      | Ind1 _ | Ind2 _ | Ind3 _ ->
        store_res (interp_op @@ get_src os) (get_dst os) (interp_op @@ get_dst os)
      | _ -> raise @@ Invalid_argument "expected ind"
    end
  in

  let push (s:quad) =   
    m.regs.(rind Rsp) <- Int64.sub m.regs.(rind Rsp) 8L;
    store_sbytes (sbytes_of_int64 s) m.regs.(rind Rsp) in

  let pop (dop:operand) (d:quad) =  
    let rsp_mem = int64_from_mem @@ interp_reg Rsp in
    store_res rsp_mem dop d;
    m.regs.(rind Rsp) <- Int64.add (interp_reg Rsp) 8L 
  in

  (*=== Control-flow instructions ===*)
  let compq_instr (os:operand list) = 
    let open Int64_overflow in
    let s = sub (interp_op @@ get_dst os) (interp_op @@ get_src os) in
    set_flags2 s
  in

  let callq_instr (os:operand list) = 
    push (interp_reg Rip);
    m.regs.(rind Rip) <- interp_op @@ get_src os
  in
  (*=== instruction fetching ===*)
  let instr = m.mem.(get_addr m.regs.(rind Rip)) in     
  m.regs.(rind Rip) <- Int64.add m.regs.(rind Rip) 8L;  
  (*=== instruction execution ===*)
  begin match instr with
    | InsB0 (oc, os) ->
      begin match oc with
        | Addq -> bin_arith_instr Addq os
        | Subq -> bin_arith_instr Subq os 
        | Imulq -> bin_arith_instr Imulq os
        | Negq -> un_arith_instr Negq os
        | Incq -> un_arith_instr Incq os
        | Decq -> un_arith_instr Decq os
        | Notq -> notq_instr Notq os
        | Andq -> bin_logic_instr Andq os
        | Orq -> bin_logic_instr Orq os
        | Xorq -> bin_logic_instr Xorq os
        | Sarq -> sarq_instr os
        | Shlq -> shlq_instr os
        | Shrq -> shrq_instr os
        | Set cc -> set_instr os cc
        | Leaq -> leaq_instr os
        | Movq -> store_res (get_value @@ get_src os) (get_dst os) (interp_op @@ get_dst os)
        | Pushq -> push (get_value @@ get_src os) 
        | Popq -> pop (get_src os) (interp_op @@ get_src os)
        | Cmpq -> compq_instr os
        | Jmp -> m.regs.(rind Rip) <- interp_op @@ get_src os
        | Callq -> callq_instr os
        | Retq -> pop (Reg Rip) (interp_reg Rip)
        | J cc -> if interp_cnd m.flags cc then m.regs.(rind Rip) <- (interp_op @@ get_src os)
      end
    | _ -> ()

  end

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

(* wheter the given elem contains data *)
let is_data (a:asm) =
  begin match a with
    | Data _ -> true
    | _ -> false
  end

let is_same_type (a:asm) (e:elem) = (is_data a) = (is_data e.asm)

(* extract all the elems of type t from p *)
let rec extract_type (t:asm) (p:prog) =
  begin match p with 
    | [] -> []
    | x::xs ->
      if is_same_type t x then x::(extract_type t xs)
      else extract_type t xs
  end

(* get the size of a data segment *)
let size_of_data (d:data) = 
  begin match d with
    | Asciz s -> 1 + (String.length s)
    | Quad _ -> 8
  end 

(* get size of an asm *)
let size_of_asm (a:asm) = 
  begin match a with
    | Text xs -> 8 * (List.length xs)
    | Data xs -> List.fold_left (fun acc d -> acc + (size_of_data d)) 0 xs
  end

(* get total size of a list of elements *)
let size_of_elems (es:elem list) : int = List.fold_left (fun acc e -> acc + (size_of_asm e.asm)) 0 es 

(* count the occurrences of lbl definition *)
let rec count_occurrences (lbl:string) (d:prog)  =
  begin match d with
    | [] -> 0
    | x::xs -> if x.lbl = lbl then 1 + count_occurrences lbl xs
      else count_occurrences lbl xs
  end

(* compute the offset of the label declaration of lbl in the elem list (considering size) *)
let rec lbl_offset (lbl:string) (p:prog) =
  let rec helper (p':prog) (acc:int) = 
    begin match p' with 
      | [] -> raise @@ Undefined_sym lbl
      | x::xs -> 
        if x.lbl = lbl then 0
        else (size_of_asm x.asm) + (helper xs acc)
    end in
  helper p 0

(* get the full address of a label declaration in prog p *) 
let lbl_addr (lbl:string) (p:prog) = 
  let occs = count_occurrences lbl p in (* for sanity check *)
  if occs = 0 then raise @@ Undefined_sym lbl
  else if occs > 1 then raise @@ Redefined_sym lbl
  else Int64.add (Int64.of_int @@ lbl_offset lbl p) mem_bot

(* find the label_to_address mapping in the list of mappings *) 
let rec get_lbl_addr (lbl:string) res = 
  begin match res with
    | [] -> raise @@ Undefined_sym lbl
    | (x,y)::xs -> if lbl = x then y else get_lbl_addr lbl xs
  end

(* get the literal declaration of an addr *)
let get_lit (l:string) (res:(string*quad) list) = Lit (get_lbl_addr l res)

(* patches an operand with resolved address *)
let patch_operand (res:(string*quad) list) (op:operand)  =
  begin match op with
    | (Imm (Lbl l)) -> (Imm (get_lit l res))
    | (Ind1 (Lbl l)) -> (Ind1 (get_lit l res))
    | (Ind3 (Lbl l, r)) -> (Ind3 (get_lit l res, r))
    | _ -> op
  end 
(* traverse a list of operands and substitute labels with their address in mem *)
let rec traverse_ops (ops:operand list) (res:(string*quad) list) : operand list= 
  List.map (patch_operand res) ops
(* traverse a list of instructions and substitute labels with their address in mem *)
let rec traverse_ins (i:ins list) (res:(string*quad) list) : ins list = 
  List.map (fun (opcode, ops) -> (opcode, traverse_ops ops res)) i  

(* traverse a list of data and substitute labels with their address in mem *)
let rec traverse_data (d:data list) (res:(string*quad) list) : data list= 
  begin match d with
    | [] -> []
    | (Quad (Lbl l))::xs -> (Quad (Lit (get_lbl_addr l res)))::(traverse_data xs res)
    | x::xs -> x::(traverse_data xs res)
  end

(* traverse an asm and substitute labels with their address in mem *)
let rec traverse_asm (a:asm) (res:(string*quad) list) : asm = 
  begin match a with
    | (Text x) -> (Text (traverse_ins x res))
    | (Data x) -> (Data (traverse_data x res))
  end

(* resolve all the labels in a program *)
let rec resolve_lbls (p:prog) (res:(string*quad) list) = List.map (fun (e:elem) -> (traverse_asm e.asm res)) p

(* get the mappings to memory of labels in a program *)
let rec get_lbl_addrs (p:prog) = List.map (fun (e:elem) -> (e.lbl, (lbl_addr e.lbl p))) p

(* get the sbyte list of an asm *)
let sbytes_of_asm (a:asm) = 
  begin match a with
    | Text x -> List.fold_left (fun acc ins -> List.append acc (sbytes_of_ins ins)) [] x
    | Data x -> List.fold_left (fun acc data -> List.append acc (sbytes_of_data data)) [] x
  end

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
  (* split text and data progs *)
  let text_prog = extract_type (Text []) p in 
  let data_prog = extract_type (Data []) p in
  (* get sizes of text and data *)
  let text_size = size_of_elems text_prog in
  (* get start address of data in mem *)
  let d_pos = Int64.add mem_bot (Int64.of_int (text_size)) in
  (* get labels_to_mem mappings *)
  let addresses = get_lbl_addrs p in
  (* patch instructions with resolved addresses *)
  let text_res = resolve_lbls text_prog addresses in
  let data_res = resolve_lbls data_prog addresses in
  (* convert segments to sbyte lists *)
  let text_seg = List.fold_left (fun acc elem -> List.append acc (sbytes_of_asm elem)) [] text_res in
  let data_seg = List.fold_left (fun acc elem -> List.append acc (sbytes_of_asm elem)) [] data_res in
  (* declare exex *)
  {
    entry = (get_lbl_addr "main" addresses);
    text_pos = mem_bot;  
    data_pos = d_pos;
    text_seg = text_seg;
    data_seg = data_seg;
  }

(* copy sbytes l to mem at address addr*)
let blit_to_mem (l:sbyte list) (addr:quad) mem = 
  Array.blit (Array.of_list l) 0 mem (get_addr addr) (List.length l)

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
  (* allocate mem *)
  let mem = Array.make mem_size (Byte '\x00') in
  (* allocate regs *)
  let regs = Array.make nregs (Int64.zero) in
  (* convert exit_addr to sbytes *)
  let sbytes_of_exit = sbytes_of_int64 exit_addr in
  (* setup initial memory state *)
  blit_to_mem text_seg text_pos mem;
  blit_to_mem data_seg data_pos mem;
  blit_to_mem sbytes_of_exit (Int64.sub mem_top 8L) mem;
  (* setup initial reg state *)
  regs.(rind Rip) <- entry;
  regs.(rind Rsp) <- (Int64.sub mem_top 8L);
  {
    flags = {fo=false; fs=false; fz=false};
    regs = regs;
    mem = mem;
  }
