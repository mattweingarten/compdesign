(* source language ---------------------------------------------------------- *)

type var = string
module SRC = struct

  (* An object language: a simple datatype of 64-bit integer expressions *)
  type exp =
    | Var of var          (* string representing an object-language variable *)
    | Const of int64      (* a constant int64 value *)
    | Add of exp * exp    (* sum of two expressions *)
    | Mul of exp * exp    (* product of two expressions *)
    | Neg of exp          (* negation of an expression *)

  (* 
        (1 + X4) + (3 + (X1 * 5) )
  *)
  let example : exp =
    Add(Add(Const 1L, Var "X4"),
        Add(Const 3L, Mul(Var "X1",
                         Const 5L)))
  
end





(* simple let language intermediate representation -------------------------- *)
module IR = struct
  (* Unique identifiers for temporaries. *)
  type uid = int

  (* "gensym" -- generate a new unique identifier *)
  let mk_uid : unit -> uid =
    let ctr = ref 0 in
    fun () -> let uid = !ctr in
      ctr := !ctr + 1;
      uid

  (* syntactic values *)
  type opn = 
    | Id of uid
    | Const of int64
    | Var of var

  (* binary operations *)
  type bop =
    | Add
    | Mul
             
  (* instructions *)
  (* note that there is no nesting of operations! *)
  type insn =
    | Let of uid * bop * opn * opn

  type program = {
    insns: insn list;
    ret: opn
  }


  (* Pretty printing *)
  let pp_uid u = Printf.sprintf "tmp%d" u
  let pp_var x = Printf.sprintf "var%s" x
      
  let pp_opn = function 
    | Id u   -> pp_uid u
    | Const c -> (Int64.to_string c)^"L"
    | Var x   -> pp_var x

  let pp_bop = function
    | Add -> "add"
    | Mul -> "mul"

  let pp_insn = function
    | Let (u, bop, op1, op2) ->
      Printf.sprintf "let %s = %s %s %s"
        (pp_uid u) (pp_bop bop) (pp_opn op1) (pp_opn op2)

  let pp_program {insns; ret} =
    (String.concat " in\n" (List.map pp_insn insns)) ^
    (Printf.sprintf " in\n  ret %s" (pp_opn ret))


  module MLMeaning = struct
    let add = Int64.add
    let mul = Int64.mul
    let ret x = x
  end
  
end





module Compile = struct
  open SRC

  (* Expressions produce answers, so the result of compiling an expression
     is a list of instructions and an operand that will contain the final
     result of comping the expression.  

     - we can share the code common to binary operations.
  *)
  
  let rec compile_exp (e:exp) : (IR.insn list) * IR.opn =
    let compile_bop bop e1 e2 = 
        let ins1, ret1 = compile_exp e1 in
        let ins2, ret2 = compile_exp e2 in
        let ret = IR.mk_uid () in
        ins1 @ ins2 @ IR.[Let (ret, bop, ret1, ret2)], IR.Id ret
    in
    begin match e with
      | Var x       -> [], IR.Var x
      | Const c     -> [], IR.Const c
      | Add(e1, e2) -> compile_bop IR.Add e1 e2
      | Mul(e1, e2) -> compile_bop IR.Mul e1 e2
      | Neg(e1)     -> compile_bop IR.Mul e1 (Const(-1L))
    end
  
  let compile (e:exp) : IR.program =
    let insns, ret = compile_exp e in
    IR.{ insns; ret }

end


