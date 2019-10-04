(* source language ---------------------------------------------------------- *)

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
    | Skip
    | Assn of var * exp
    | Seq  of cmd * cmd
    | IfNZ of exp * cmd * cmd
    | WhileNZ of exp * cmd

  (*
    X2 := X1 + X2;
    IFNZ X2 THEN
      X1 := X1 + 1
    ELSE
      X2 := X1
    X2 := X2 * X1
  *)
  let example_branch : cmd =
    let x1 = "X1" in
    let x2 = "X2" in
    let vx1 = Var x1 in
    let vx2 = Var x2 in
    Seq(Assn(x1, Add(vx1, vx2)),
        Seq(IfNZ(vx2,
                 Assn(x1, Add(vx1, Const 1L)),
                 Assn(x2, vx1)),
          Assn(x2, Mul(vx2, vx1))
        ))


  (* 
     X1 := 6;
     X2 := 1;
     WhileNZ X1 DO
       X2 := X2 * X1;
       X1 := X1 + (-1);
     DONE
  *)
  let factorial : cmd =
    let x = "X1" in
    let ans = "X2" in
    Seq(Assn(x, Const 6L),
        Seq(Assn(ans, Const 1L),
            WhileNZ(Var x,
                    Seq(Assn(ans, Mul(Var ans, Var x)),
                        Assn(x,   Add(Var x, Const (-1L) ))))))
      
  
end


module IR = struct
  
  type uid = string     (* Unique identifiers for temporaries. *)
  type lbl = string
  
  (* "gensym" -- generate a new unique identifier *)
  let mk_uid : string -> uid =
    let ctr = ref 0 in
    fun s -> let uid = !ctr in
      ctr := !ctr + 1;
      Printf.sprintf "%s%d" s uid
  
  
  (* operands *)
  type opn = 
    | Id of uid
    | Const of int64

  (* binary arithmetic operations *)
  type bop =
    | Add
    | Mul

  (* comparison operations *)
  type cmpop =
    | Eq
    | Lt
  
  (* instructions *)
  (* note that there is no nesting of operations! *)
  type insn =
    | Let of uid * bop * opn * opn
    | Load of uid * var
    | Store of var * opn
    | ICmp of uid * cmpop * opn * opn
  
  type terminator =
    | Ret 
    | Br of lbl                (* unconditional branch *)
    | Cbr of opn * lbl * lbl   (* conditional branch *)

  (* Basic blocks *)
  type block = { insns: insn list; terminator: terminator }

  (* Control Flow Graph: a pair of an entry block and a set labeled blocks *)
  type cfg = block * (lbl * block) list
  
  type program = cfg
  
  (* pretty printing *)
  let pp_uid u = u
  let pp_var x = Printf.sprintf "var%s" x
  
  let pp_opn = function 
    | Id u   -> pp_uid u
    | Const c -> (Int64.to_string c) ^ "L"

  let pp_bop = function
    | Add -> "add"
    | Mul -> "mul"

  let pp_cmpop = function
    | Eq -> "eq"
    | lt -> "lt"
  
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
    | ICmp (u, cmpop, op1, op2) ->
      Printf.sprintf "let %s = icmp %s %s %s"
        (pp_uid u) (pp_cmpop cmpop) (pp_opn op1) (pp_opn op2)

  let pp_terminator = function
    | Ret -> "  ret ()"
    | Br lbl  -> Printf.sprintf "  br %s" lbl
    | Cbr(op, lbl1, lbl2) -> Printf.sprintf "  cbr %s %s %s" (pp_opn op) lbl1 lbl2

  let pp_block {insns; terminator} =
    (String.concat " in\n" (List.map pp_insn insns)) ^
    (if (List.length insns) > 0 then " in\n" else "")
    ^
    (pp_terminator terminator)

  let pp_cfg (entry_block, blocks) =
    (Printf.sprintf "let rec entry () =\n%s" (pp_block entry_block)) ^ "\n\n" ^
    (String.concat "\n\n"
       (List.map (fun (lbl,block) -> Printf.sprintf "and %s () =\n%s" lbl (pp_block block)) blocks))
  
  let pp_program cfg =
    Printf.sprintf "let program () =\n%s\nin entry ()" (pp_cfg cfg)

  module MLMeaning = struct
    let add = Int64.add
    let mul = Int64.mul
    let load (x : int64 ref) = (!x)
    let store o (x : int64 ref) = x := o
    let icmp cmpop x y = cmpop x y 

    let eq (x : int64) (y : int64) = x = y
    let lt x y = x < y

    let ret x = x

    let cbr cnd lbl1 lbl2 =
      if cnd then lbl1 () else lbl2 ()
    let br lbl = lbl ()
  end
  
end

module Compile = struct
  open SRC
  open IR
  
  type elt = 
    | L of lbl          (* Block labels *)
    | I of insn         (* LL IR instruction *)
    | T of terminator   (* Block terminators *)

  type stream = elt list

  (* During generation, we typically emit code so that it is in
     _reverse_ order when the stream is viewed as a list.  That is,
     instructions closer to the head of the list are to be executed
     later in the program.  That is because cons is more efficient than
     append.

     To help make code generation easier, we define snoc (reverse cons)
     and reverse append, which let us write code sequences in their
     natural order.                                                             *)
  let ( >@ ) x y = y @ x
  let ( >:: ) x y = y :: x


  (* Convert an instruction stream into a control flow graph.
     - assumes that the instructions are in 'reverse' order of execution.
  *)
  let build_cfg (code:stream) : cfg   =
    let blocks_of_stream (code:stream) =
      let (insns, term_opt, blks) =  List.fold_left
	  (fun (insns, term_opt, blks) e ->
             begin match e with
               | L l ->
                 begin match term_opt with
                   | None ->
                     if (List.length insns) = 0 then  ([], None, blks)
                     else failwith @@
                       Printf.sprintf "build_cfg: block labeled %s has\
                                       no terminator" l

                   | Some terminator ->
                     ([], None, (l, {insns; terminator})::blks)
                 end
               | T t  -> ([], Some t, blks)
               | I i  -> (i::insns, term_opt, blks)
             end)
          ([], None, []) code
      in
      begin match term_opt with
        | None -> failwith "build_cfg: entry block has no terminator" 
        | Some terminator ->
          ({insns; terminator}, blks)
      end
    in
    blocks_of_stream code 

  
  let rec compile_exp (e:exp) : (insn list) * opn =
    let compile_bop bop e1 e2 = 
        let ins1, ret1 = compile_exp e1 in
        let ins2, ret2 = compile_exp e2 in
        let ret = mk_uid "tmp" in
        ins1 >@ ins2 >@ [Let (ret, bop, ret1, ret2)], Id ret
    in
    begin match e with
      | Var x ->
        let ret = mk_uid "tmp" in
        [Load(ret, x)], Id ret
      | Const c -> [], Const c
      | Add(e1, e2) -> compile_bop Add e1 e2
      | Mul(e1, e2) -> compile_bop Mul e1 e2
      | Neg(e1) -> compile_bop Mul e1 (Const(-1L))
    end

  let lift : (insn list) -> stream = List.map (fun i -> I i) 
  
  let rec compile_cmd (c:cmd) : stream =
    begin match c with
      | Skip -> []

      | Assn (v, e) ->
        let (is, op) = compile_exp e in
        (lift is) >::  I (Store (v, op)) 

      | Seq  (c1, c2) ->
        (compile_cmd c1) >@ (compile_cmd c2)

      | IfNZ (e, c1, c2) ->
        let (is, result) = compile_exp e in
        let c1_insns = compile_cmd c1 in
        let c2_insns = compile_cmd c2 in
        let guard = mk_uid "guard" in
        let nz_branch = mk_uid "nz_branch" in
        let z_branch = mk_uid "z_branch" in
        let merge = mk_uid "merge" in
        (* Compute the guard result *)
           (lift is)
           >@ [ I (ICmp (guard, Eq, result, Const 0L)) ]
           >@ [ T (Cbr (Id guard, z_branch, nz_branch)) ]

           (* guard is non-zero *)
           >@ [ L nz_branch ]
           >@ c1_insns
           >@ [ T (Br merge) ]


           (* guard is zero *)
           >@ [ L z_branch ]
           >@ c2_insns
           >@ [ T (Br merge) ]

           >@ [ L merge ]

      | WhileNZ (e, c) ->
        let (is, result) = compile_exp e in
        let c_insns = compile_cmd c in
        let guard = mk_uid "guard" in
        let entry = mk_uid "entry" in
        let body =  mk_uid "body" in
        let exit =  mk_uid "exit" in
           [ T (Br entry) ]
        >@ [ L entry ]
        >@ (lift is)
        >@ [ I (ICmp (guard, Eq, result, Const 0L)) ]
        >@ [ T (Cbr (Id guard, exit, body)) ]
        >@ [ L body ]
        >@ c_insns
        >@ [ T (Br entry) ]
        >@ [ L exit ]
    end
    
  let compile (c:cmd) : IR.program =
    build_cfg ((compile_cmd c) >:: T Ret)
    

end


