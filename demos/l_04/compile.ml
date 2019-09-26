(* source language ---------------------------------------------------------- *)

type var = string

(* Object language: a simple datatype of 64-bit integer expressions 
   Legal variables: X1 .. X8
 *)
type exp =
  | Var of var            (* string representing an object-language variable *)
  | Const of int64        (* a constant int64 value *)
  | Add of exp * exp      (* sum of two expressions *)
  | Mul of exp * exp      (* product of two expressions *)
  | Neg of exp            (* negation of an expression *)

(* Static context: contains the set of legally scoped variables *)
let context = ["X1"; "X2"; "X3"; "X4"; "X5"; "X6"; "X7"; "X8"]

(* Checks that the source program is well formed *)
let rec static_check (e:exp) : unit =
  begin match e with
    | Var x -> if List.mem x context
               then ()
               else failwith @@ Printf.sprintf "Variable not in scope: %s" x
    | Const _ -> ()
    | Add(e1, e2)
    | Mul(e1, e2) -> static_check e1; static_check e2
    | Neg(e) -> static_check e
  end



(* back-end translation to x86 ---------------------------------------------- *)
open X86

(* Demonstrates x86_64 System V AMD64 ABI calling conventions:
   - first six integer/pointer args are passed in:
     rdi, rsi, rdx, rcx, r8, r9
   - arguments seven and higher are pushed onto the stack (right-to-left)
     
   return value in rax

   - callee save: rbp, rbx, r12-r15
   - caller save: all others
*)

let function_prologue : X86.ins list =
  Asm.([ Pushq, [~%Rbp]
       ; Movq, [~%Rsp; ~%Rbp]
       ])

let function_epilogue : X86.ins list =
  Asm.([ Popq, [~%Rbp]
       ; Retq, []
    ])

(* compiling the context ---------------------------------------------------- *)

(* In this simple language, each free identifier of the expression maps 
   directly to an X86 operand.   
*)

(* Assumes that x is a well-scoped variable *)
let compile_var (x:var) : X86.operand =
  Asm.(match x with
  | "X1" -> ~%Rdi
  | "X2" -> ~%Rsi
  | "X3" -> ~%Rdx
  | "X4" -> ~%Rcx
  | "X5" -> ~%R08
  | "X6" -> ~%R09
  | "X7" -> Ind3(Lit (Int64.of_int (16)), Rbp)
  | "X8" -> Ind3(Lit (Int64.of_int (24)), Rbp)
  | _ -> failwith @@ Printf.sprintf "unbound variable %s" x
  )


(* compilation strategy 1: use the Rax invariant ------------------------ *)

(* Invariant: 
    - compile the expression directly into Rax
    - use the stack to remember intermediate results for binary operations
    - use the dedicated register R10 for binary operations
*)

let rec compile_exp (e:exp) : X86.ins list =
  let compile_op op e1 e2 =
    Asm.( (compile_exp e1)
        @ [Pushq, [~%Rax]]
        @ ((compile_exp e2))
        @ [Popq, [~%R10]
          ;op, [~%R10; ~%Rax]])
  in

  begin match e with
    | Var x   -> Asm.[Movq, [compile_var x; ~%Rax]]
    | Const c -> Asm.[Movq, [Imm (Lit c)  ; ~%Rax]]
    | Add (e1, e2) -> Asm.(compile_op Addq e1 e2)
    | Mul (e1, e2) -> Asm.(compile_op Imulq e1 e2)
    | Neg e -> compile_exp e
               @ Asm.[Imulq, [~$(-1); ~%Rax]]
  end

      


let compile1 (src:exp) : X86.prog =
  Asm.[gtext "_program" @@
         function_prologue 
       @ (compile_exp src)
       @ function_epilogue
      ]





(* compilation strategy 2: use the stack-based ir --------------------------- *)

(* intermediate representation ---------------------------------------------- *)

(* A stack-oriented intermediate representation *)
type insn =
  | IPushC of int64   (* push an int64 constant onto the stack *)
  | IPushV of var     (* push value of var onto the stack *)
  | IMul              (* multiply the top two values on the stack *)
  | IAdd              (* add the top two values on the stack *)
  | INeg              (* negate the top value on the stack *)

type program = insn list

let rec flatten (e:exp) : program =
  begin match e with
    | Var x       -> [IPushV x]
    | Const c     -> [IPushC c]
    | Add(e1, e2) -> (flatten e1) @ (flatten e2) @ [IAdd]
    | Mul(e1, e2) -> (flatten e1) @ (flatten e2) @ [IMul]
    | Neg(e)      -> (flatten e) @ [INeg]
  end


(* use the x86 stack *)

let compile_op (op:opcode) : X86.ins list =
  Asm.([ Popq, [~%Rax]
       ; Popq, [~%R10]
       ; op, [~%R10; ~%Rax]
       ; Pushq, [~%Rax]
       ])

let compile_neg : X86.ins list =
  Asm.([  Popq, [~%Rax]
       ;  Imulq, [~$(-1); ~%Rax]
       ;  Pushq, [~%Rax]
  ])

let rec compile_insn (i:insn) : X86.ins list =
  begin match i with
    | IPushC c -> Asm.([Pushq, [Imm (Lit c)]])
    | IPushV x -> Asm.([Pushq, [compile_var x]])
    | IMul -> compile_op Imulq
    | IAdd -> compile_op Addq
    | INeg -> compile_neg 
  end



let compile2 (src:exp) : X86.prog =
  let ir : program =
    static_check src;
    flatten src
  in
  Asm.[ gtext "_program" @@
      function_prologue
    @ (List.concat (List.map compile_insn ir))
    @ [ Popq, [~%Rax] ]
    @ function_epilogue
  ]
  


