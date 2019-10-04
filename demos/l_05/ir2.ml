(* source language ---------------------------------------------------------- *)

(* This variant of the language treats variables as mutable.
   Their interpretation in ML has type "int64 ref"
*)

type var = string
module SRC = struct

  (* Abstract syntax of arithmetic expressions *)
  type exp =
    | Var of var
    | Add of exp * exp
    | Mul of exp * exp
    | Neg of exp
    | Const of int64

  (* Abstract syntax of commands *)
  type cmd =
    | Skip                       (* skip    *)
    | Assn of var * exp          (* X := e  *)
    | Seq  of cmd * cmd          (* c1 ; c2 *)

  (* 
        (1 + X4) + (3 + (X1 * 5) )
  *)
  let example : exp =
    Add(Add(Const 1L, Var "X4"),
        Add(Const 3L, Mul(Var "X1",
                         Const 5L)))

  (*
     X1 := (1 + X4) + (3 + (X1 * 5) ) ;
     Skip ;
     X2 := X1 * X1 ;
  *)
  let example_cmd : cmd =
    Seq(Assn("X1", example),
    Seq(Skip,
        Assn("X2", Mul(Var "X1", Var "X1"))))
  
end


module IR = struct
  (* Unique identifiers for temporaries. *)
  type uid = int

  (* "gensym" -- generate a new unique identifier *)
  let mk_uid : unit -> uid =
    let ctr = ref 0 in
    fun () -> let uid = !ctr in
      ctr := !ctr + 1;
      uid

  (* operands *)
  type opn = 
    | Id of uid
    | Const of int64

  (* binary operations *)
  type bop =
    | Add
    | Mul
  
  (* instructions *)
  (* note that there is no nesting of operations! *)
  type insn =
    | Let of uid * bop * opn * opn
    | Load of uid * var
    | Store of var * opn
  
  type program = {
    insns: insn list
  }


  (* pretty printing *)
  let pp_uid u = Printf.sprintf "tmp%d" u
  let pp_var x = Printf.sprintf "var%s" x
  
  let pp_opn = function 
    | Id u   -> pp_uid u
    | Const c -> (Int64.to_string c)^"L"

  let pp_bop = function
    | Add -> "add"
    | Mul -> "mul"
  
  let pp_insn = function
    | Let (u, bop, op1, op2) ->
      Printf.sprintf "let %s = %s %s %s"
        (pp_uid u) (pp_bop bop) (pp_opn op1) (pp_opn op2)
    | Load (u, x) ->
      Printf.sprintf "let %s = load %s"
        (pp_uid u) (pp_var x)
    | Store (x, op) ->
      Printf.sprintf "let _ = store %s %s"
        (pp_opn op) (pp_var x)
  
  let pp_program {insns} =
    (String.concat " in\n" (List.map pp_insn insns)) ^
    (Printf.sprintf " in\n  ()")


  module MLMeaning = struct
    let add = Int64.add
    let mul = Int64.mul
    let load x = !x
    let store o x = x := o
  end
  
end


module Compile = struct
  open SRC
  
  let rec compile_exp (e:exp) : (IR.insn list) * IR.opn =
    let compile_bop bop e1 e2 = 
        let ins1, ret1 = compile_exp e1 in
        let ins2, ret2 = compile_exp e2 in
        let ret = IR.mk_uid () in
        ins1 @ ins2 @ IR.[Let (ret, bop, ret1, ret2)], IR.Id ret
    in
    begin match e with
      | Var x ->
        let ret = IR.mk_uid () in
        IR.[Load(ret, x)], IR.Id ret
      | Const c     -> [], IR.Const c
      | Add(e1, e2) -> compile_bop IR.Add e1 e2
      | Mul(e1, e2) -> compile_bop IR.Mul e1 e2
      | Neg(e1)     -> compile_bop IR.Mul e1 (Const(-1L))
    end

  let rec compile_cmd (c:cmd) : (IR.insn list) =
    begin match c with
      | Skip -> []
      | Assn(x, e) ->
        let ins1, ret1 = compile_exp e in
        ins1 @ IR.[Store(x, ret1)]
      | Seq(c1, c2) ->
        (compile_cmd c1) @ (compile_cmd c2)
    end
    
  let compile (c:cmd) : IR.program =
    let insns = compile_cmd c in
    IR.{ insns }

end

