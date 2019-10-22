(* ll ir compilation -------------------------------------------------------- *)

open Ll
open X86

(* Overview ----------------------------------------------------------------- *)

(* We suggest that you spend some time understinging this entire file and
   how it fits with the compiler pipeline before making changes.  The suggested
   plan for implementing the compiler is provided on the project web page.
*)


(* helpers ------------------------------------------------------------------ *)

(* Map LL comparison operations to X86 condition codes *)
let compile_cnd = function
  | Ll.Eq  -> X86.Eq
  | Ll.Ne  -> X86.Neq
  | Ll.Slt -> X86.Lt
  | Ll.Sle -> X86.Le
  | Ll.Sgt -> X86.Gt
  | Ll.Sge -> X86.Ge


(* locals and layout -------------------------------------------------------- *)

(* One key problem in compiling the LLVM IR is how to map its local
   identifiers to X86 abstractions.  For the best performance, one
   would want to use an X86 register for each LLVM %uid.  However,
   since there are an unlimited number of %uids and only 16 registers,
   doing so effectively is quite difficult.  We will see later in the
   course how _register allocation_ algorithms can do a good job at
   this.

   A simpler, but less performant, implementation is to map each %uid
   in the LLVM source to a _stack slot_ (i.e. a region of memory in
   the stack).  Since LLVMlite, unlike real LLVM, permits %uid locals
   to store only 64-bit data, each stack slot is an 8-byte value.

   [ NOTE: For compiling LLVMlite, even i1 data values should be
   represented as a 8-byte quad. This greatly simplifies code
   generation. ]

   We call the datastructure that maps each %uid to its stack slot a
   'stack layout'.  A stack layout maps a uid to an X86 operand for
   accessing its contents.  For this compilation strategy, the operand
   is always an offset from ebp (in bytes) that represents a storage slot in
   the stack.
*)

type layout = (uid * X86.operand) list

(* A context contains the global type declarations (needed for getelementptr
   calculations) and a stack layout. *)
type ctxt = { tdecls : (tid * ty) list
            ; layout : layout
            }

(* useful for looking up items in tdecls or layouts *)
let lookup m x = List.assoc x m

let get (ctxt:ctxt) (id :uid) :X86.operand =
  snd @@ List.find (fun (uid, op) -> id = uid) ctxt.layout


(* compiling operands  ------------------------------------------------------ *)

(* LLVM IR instructions support several kinds of operands.

   LL local %uids live in stack slots, whereas global ids live at
   global addresses that must be computed from a label.  Constants are
   immediately available, and the operand Null is the 64-bit 0 value.

     NOTE: two important facts about global identifiers:

     (1) You should use (Platform.mangle gid) to obtain a string
     suitable for naming a global label on your platform (OS X expects
     "_main" while linux expects "main").

     (2) 64-bit assembly labels are not allowed as immediate operands.
     That is, the X86 code: movq _gid %rax which looks like it should
     put the address denoted by _gid into %rax is not allowed.
     Instead, you need to compute an %rip-relative address using the
     leaq instruction:   leaq _gid(%rip).

   One strategy for compiling instruction operands is to use a
   designated register (or registers) for holding the values being
   manipulated by the LLVM IR instruction. You might find it useful to
   implement the following helper function, whose job is to generate
   the X86 instruction that moves an LLVM operand into a designated
   destination (usually a register).
*)
let compile_operand ctxt (dest:X86.operand) : Ll.operand -> ins = function
      | Const x -> (Movq, [(Imm (Lit x));dest])
      | Id x -> (Movq, [(get ctxt x);dest])
      | Gid x -> failwith "operand not implemented"
      | Null -> failwith "operand not implemented"




(* compiling call  ---------------------------------------------------------- *)

(* You will probably find it helpful to implement a helper function that
   generates code for the LLVM IR call instruction.

   The code you generate should follow the x64 System V AMD64 ABI
   calling conventions, which places the first six 64-bit (or smaller)
   values in registers and pushes the rest onto the stack.  Note that,
   since all LLVM IR operands are 64-bit values, the first six
   operands will always be placed in registers.  (See the notes about
   compiling fdecl below.)

   [ NOTE: It is the caller's responsibility to clean up arguments
   pushed onto the stack, so you must free the stack space after the
   call returns. ]

   [ NOTE: Don't forget to preserve caller-save registers (only if
   needed). ]
*)
let compile_call ctxt fop args =
  failwith "compile_call not implemented"



(* compiling getelementptr (gep)  ------------------------------------------- *)

(* The getelementptr instruction computes an address by indexing into
   a datastructure, following a path of offsets.  It computes the
   address based on the size of the data, which is dictated by the
   data's type.

   To compile getelmentptr, you must generate x86 code that performs
   the appropriate arithemetic calculations.
*)

(* [size_ty] maps an LLVMlite type to a size in bytes.
    (needed for getelementptr)

   - the size of a struct is the sum of the sizes of each component
   - the size of an array of t's with n elements is n * the size of t
   - all pointers, I1, and I64 are 8 bytes
   - the size of a named type is the size of its definition

   - Void, i8, and functions have undefined sizes according to LLVMlite.
     Your function should simply return 0 in those cases
*)
let rec size_ty tdecls t : int =
  failwith "size_ty not implemented"




(* Generates code that computes a pointer value.

   1. op must be of pointer type: t*

   2. the value of op is the base address of the calculation

   3. the first index in the path is treated as the index into an array
     of elements of type t located at the base address

   4. subsequent indices are interpreted according to the type t:

     - if t is a struct, the index must be a constant n and it
       picks out the n'th element of the struct. [ NOTE: the offset
       within the struct of the n'th element is determined by the
       sizes of the types of the previous elements ]

   - if t is an array, the index can be any operand, and its
       value determines the offset within the array.

     - if t is any other type, the path is invalid

   5. if the index is valid, the remainder of the path is computed as
      in (4), but relative to the type f the sub-element picked out
      by the path so far
*)
let compile_gep ctxt (op : Ll.ty * Ll.operand) (path: Ll.operand list) : ins list =
  failwith "compile_gep not implemented"



(* compiling instructions  -------------------------------------------------- *)

(* The result of compiling a single LLVM instruction might be many x86
   instructions.  We have not determined the structure of this code
   for you. Some of the instructions require only a couple assembly
   instructions, while others require more.  We have suggested that
   you need at least compile_operand, compile_call, and compile_gep
   helpers; you may introduce more as you see fit.

   Here are a few notes:

   - Icmp:  the Set instruction may be of use.  Depending on how you
     compile Cbr, you may want to ensure that the value produced by
     Icmp is exactly 0 or 1.

   - Load & Store: these need to dereference the pointers. Const and
     Null operands aren't valid pointers.  Don't forget to
     Platform.mangle the global identifier.

   - Alloca: needs to return a pointer into the stack

   - Bitcast: does nothing interesting at the assembly level
*)
let compile_insn ctxt (uid, i) : X86.ins list =
      let instruction_list = [] in
      let get_src = compile_operand ctxt (Reg R09) in
      let get_dest = compile_operand ctxt (Reg R10) in
      let move_result_to_stack = (Movq,[(Reg R10);(get ctxt uid)]) in
      let compile_binop bop ty op1 op2 =
        begin match bop with
          | Add -> (get_src op1) :: ((get_dest op2) :: (  (Addq,[(Reg R10);(Reg R09)]):: ((Movq,[(Reg R09);(get ctxt uid)]) :: [])))
          | _ -> failwith "Not yet implemented this binop"
        end
      in
      begin match i with
        | Binop (bop,ty,op1,op2) -> compile_binop bop ty op1 op2
        | _ -> failwith "not yet implented non binop"
      end




(* compiling terminators  --------------------------------------------------- *)
let compile_ret (ctxt:ctxt) (a:Ll.ty * Ll.operand option) = 
  begin match a with
    | (_, None) -> [(Retq, [])]
    | _ -> failwith "retrip"
  end


(* Compile block terminators is not too difficult:

   - Ret should properly exit the function: freeing stack space,
     restoring the value of %rbp, and putting the return value (if
     any) in %rax.

   - Br should jump

   - Cbr branch should treat its operand as a boolean conditional
*)



let print_option (op: 'a option) :unit =
  begin match op with
    | Some _ -> Printf.printf "\nSome\n"
    | None -> Printf.printf "\nNone\n"
  end
(*free stack space for Retq*)
let compile_terminator (ctxt :ctxt) t :ins list  =
  let compile_ret  (return_type:ty) (op :Ll.operand option) : ins list =
    let put_in_rax = compile_operand ctxt (Reg Rax) in
    let retq = [Retq, []] in
    begin match return_type with
      | Void -> if (op!= None ) then raise(Failure "Cannot return an Operand with type Void!")
                                  else retq
      | I64 -> begin match op with
                | Some x -> (put_in_rax x) :: retq
                | None -> raise(Failure "Missing operand when returning i64")
               end
      | _ -> failwith "non void return uniplemented"
    end
  in

  let input = fst t in
  let terminator = snd t in
  begin match terminator with
    | Ret (return_type, op) -> compile_ret return_type op
    | _ -> failwith "only implemented Ret"
  end



  (* | Br lbl -> failwith "terminator Br unimplemented"
  | Cbr (condition, lbl, lbl) -> failwith "terminator Cbr unimplemented" *)


(* compiling blocks --------------------------------------------------------- *)

(* We have left this helper function here for you to complete. *)
let compile_block ctxt blk : ins list =
  let f = fun insn -> compile_insn ctxt insn in
  (List.map f blk.insns |> List.flatten) @ compile_terminator ctxt (snd blk.term)


let compile_lbl_block lbl ctxt blk : elem =
  let result = Asm.text lbl (compile_block ctxt blk) in
  let res_string = X86.string_of_elem result in
  result




(* compile_fdecl ------------------------------------------------------------ *)


(* This helper function computes the location of the nth incoming
   function argument: either in a register or relative to %rbp,
   according to the calling conventions.  You might find it useful for
   compile_fdecl.

   [ NOTE: the first six arguments are numbered 0 .. 5 ]
*)
let arg_loc (n : int) : operand =
  begin match n with
    | 0 -> Reg Rdi  | 1 -> Reg Rsi  | 2 -> Reg Rdx
    | 3 -> Reg Rcx  | 4 -> Reg R08  | 5 -> Reg R09
    | n -> Ind3 (Lit (Int64.of_int @@ 8 * (n-4)), Rbp)
  end

let stack_arg i uid = (uid, arg_loc i)

let rec stack_args i xs = 
  begin match xs with
    | [] -> []
    | x::ys -> (stack_arg i x)::stack_args (i+1) ys
  end

(* We suggest that you create a helper function that computes the 
   stack layout for a given function declaration.

   - each function argument should be copied into a stack slot
   - in this (inefficient) compilation strategy, each local id
     is also stored as a stack slot.
   - see the discusion about locals

*)
let stack_layout args (blk, lbled_blocks) : layout =
  stack_args 0 args 

(*Dumped everything into stack layout for now even arguments and arguments in registers (seems like bad idea)*)
(* at this point argc and arcv get push onto stack.... Good or not good? *)
let stack_layout (args : uid list) ((block :block) , (lbled_blocks :(lbl * block) list)) : layout =
  let pos_offset x = Ind3 (Lit (Int64.of_int (8 * (x+2))), Rbp) in
  let neg_offset x = Ind3 (Lit (Int64.of_int (-8 * (x+1))), Rbp) in
  let param_layout = List.mapi (fun i x -> (x, pos_offset i)) args in
  let local_layout = List.append block.insns (List.flatten @@ List.map (fun x -> (snd x).insns)  lbled_blocks) in
  let local_layout_computed = List.mapi (fun i x -> (fst x, neg_offset i)) local_layout in
  let result = List.append param_layout local_layout_computed in
  result

(*Helper function to print out stack*)
let rec print_stack (layout :layout) :unit =

  begin match layout with
    | x::xs -> Printf.printf "\n%s: %s \n" (fst x) (X86.string_of_operand @@ snd x); print_stack xs
    | [] -> Printf.printf "\n-----------------\n"
  end
(* The code for the entry-point of a function must do several things:

   - since our simple compiler maps local %uids to stack slots,
     compiling the control-flow-graph body of an fdecl requires us to
     compute the layout (see the discussion of locals and layout)

   - the function code should also comply with the calling
     conventions, typically by moving arguments out of the parameter
     registers (or stack slots) into local storage space.  For our
     simple compilation strategy, that local storage space should be
     in the stack. (So the function parameters can also be accounted
     for in the layout.)

   - the function entry code should allocate the stack storage needed
     to hold all of the local stack slots.
*)


let compile_fdecl tdecls name { f_ty; f_param; f_cfg } =
  let stack = stack_layout f_param f_cfg in
  Printf.printf "\n-----------------\n";
  Printf.printf "Stack:\n";
  print_stack stack;
  let ctxt = {tdecls=tdecls;layout=stack} in
  let main_block = fst f_cfg in
  let non_main_blocks = snd f_cfg in
  let main_block_compiled = [Asm.gtext name (compile_block ctxt main_block)] in
  let compiled_blocks = List.map (fun (lbl, block) -> compile_lbl_block lbl ctxt block ) non_main_blocks in
  List.append main_block_compiled compiled_blocks








(* compile_gdecl ------------------------------------------------------------ *)
(* Compile a global value into an X86 global data declaration and map
   a global uid to its associated X86 label.
*)
let rec compile_ginit = function
  | GNull     -> [Quad (Lit 0L)]
  | GGid gid  -> [Quad (Lbl (Platform.mangle gid))]
  | GInt c    -> [Quad (Lit c)]
  | GString s -> [Asciz s]
  | GArray gs | GStruct gs -> List.map compile_gdecl gs |> List.flatten

and compile_gdecl (_, g) = compile_ginit g


(* compile_prog ------------------------------------------------------------- *)
let compile_prog {tdecls; gdecls; fdecls} : X86.prog =
  let g = fun (lbl, gdecl) -> Asm.data (Platform.mangle lbl) (compile_gdecl gdecl) in
  let f = fun (name, fdecl) -> compile_fdecl tdecls name fdecl in
  (List.map g gdecls) @ (List.map f fdecls |> List.flatten)
