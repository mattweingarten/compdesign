open Ll
open Llutil
open Ast

(* instruction streams ------------------------------------------------------ *)

(* As in the last project, we'll be working with a flattened representation
   of LLVMlite programs to make emitting code easier. This version
   additionally makes it possible to emit elements will be gathered up and
   "hoisted" to specific parts of the constructed CFG
   - G of gid * Ll.gdecl: allows you to output global definitions in the middle
     of the instruction stream. You will find this useful for compiling string
     literals
   - E of uid * insn: allows you to emit an instruction that will be moved up
     to the entry block of the current function. This will be useful for
     compiling local variable declarations
*)

type elt =
  | L of Ll.lbl (* block labels *)
  | I of uid * Ll.insn (* instruction *)
  | T of Ll.terminator (* block terminators *)
  | G of gid * Ll.gdecl (* hoisted globals (usually strings) *)
  | E of uid * Ll.insn

(* hoisted entry block instructions *)

(*TODO Hoist all alloca functions*)
type stream = elt list

let ( >@ ) x y = y @ x

let ( >:: ) x y = y :: x

let lift : (uid * insn) list -> stream = List.rev_map (fun (x, i) -> I (x, i))

(* Build a CFG and collection of global variable definitions from a stream *)
let cfg_of_stream (code : stream) : Ll.cfg * (Ll.gid * Ll.gdecl) list =
  let gs, einsns, insns, term_opt, blks =
    List.fold_left
      (fun (gs, einsns, insns, term_opt, blks) e ->
        match e with
        | L l -> (
            match term_opt with
            | None ->
                if List.length insns = 0 then (gs, einsns, [], None, blks)
                else
                  failwith
                  @@ Printf.sprintf
                       "build_cfg: block labeled %s hasno terminator" l
            | Some term -> (gs, einsns, [], None, (l, { insns; term }) :: blks)
            )
        | T t -> (gs, einsns, [], Some (Llutil.Parsing.gensym "tmn", t), blks)
        | I (uid, insn) -> (gs, einsns, (uid, insn) :: insns, term_opt, blks)
        | G (gid, gdecl) -> ((gid, gdecl) :: gs, einsns, insns, term_opt, blks)
        | E (uid, i) -> (gs, (uid, i) :: einsns, insns, term_opt, blks))
      ([], [], [], None, []) code
  in
  match term_opt with
  | None -> failwith "build_cfg: entry block has no terminator"
  | Some term ->
      let insns = einsns @ insns in
      (({ insns; term }, blks), gs)

(* compilation contexts ----------------------------------------------------- *)

(* To compile OAT variables, we maintain a mapping of source identifiers to the
   corresponding LLVMlite operands. Bindings are added for global OAT variables
   and local variables that are in scope. *)

module Ctxt = struct
  type t = (Ast.id * (Ll.ty * Ll.operand)) list

  let empty = []

  (* Add a binding to the context *)
  let add (c : t) (id : id) (bnd : Ll.ty * Ll.operand) : t = (id, bnd) :: c

  (* Lookup a binding in the context *)
  let lookup (id : Ast.id) (c : t) : Ll.ty * Ll.operand = List.assoc id c

  (* Lookup a function, fail otherwise *)
  let lookup_function (id : Ast.id) (c : t) : Ll.ty * Ll.operand =
    match List.assoc id c with
    | Ptr (Fun (args, ret)), g -> (Ptr (Fun (args, ret)), g)
    | _ -> failwith @@ id ^ " not bound to a function"

  let lookup_function_option (id : Ast.id) (c : t) : (Ll.ty * Ll.operand) option
      =
    try Some (lookup_function id c) with _ -> None
end

(* compiling OAT types ------------------------------------------------------ *)

(* The mapping of source types onto LLVMlite is straightforward. Booleans and ints
   are represented as the the corresponding integer types. OAT strings are
   pointers to bytes (I8). Arrays are the most interesting type: they are
   represented as pointers to structs where the first component is the number
   of elements in the following array.

   The trickiest part of this project will be satisfying LLVM's rudimentary type
   system. Recall that global arrays in LLVMlite need to be declared with their
   length in the type to statically allocate the right amount of memory. The
   global strings and arrays you emit will therefore have a more specific type
   annotation than the output of cmp_rty. You will have to carefully bitcast
   gids to satisfy the LLVM type checker.
*)

let rec cmp_ty : Ast.ty -> Ll.ty = function
  | Ast.TBool -> I1
  | Ast.TInt -> I64
  | Ast.TRef r -> Ptr (cmp_rty r)

and cmp_rty : Ast.rty -> Ll.ty = function
  | Ast.RString -> I8
  | Ast.RArray u -> Struct [ I64; Array (0, cmp_ty u) ]
  | Ast.RFun (ts, t) ->
      let args, ret = cmp_fty (ts, t) in
      Fun (args, ret)

and cmp_ret_ty : Ast.ret_ty -> Ll.ty = function
  | Ast.RetVoid -> Void
  | Ast.RetVal t -> cmp_ty t

and cmp_fty (ts, r) : Ll.fty = (List.map cmp_ty ts, cmp_ret_ty r)

let typ_of_binop : Ast.binop -> Ast.ty * Ast.ty * Ast.ty = function
  | Add | Mul | Sub | Shl | Shr | Sar | IAnd | IOr -> (TInt, TInt, TInt)
  | Eq | Neq | Lt | Lte | Gt | Gte -> (TInt, TInt, TBool)
  | And | Or -> (TBool, TBool, TBool)

let typ_of_unop : Ast.unop -> Ast.ty * Ast.ty = function
  | Neg | Bitnot -> (TInt, TInt)
  | Lognot -> (TBool, TBool)

(* Some useful helper functions *)

(* Generate a fresh temporary identifier. Since OAT identifiers cannot begin
   with an underscore, these should not clash with any source variables *)
let gensym : string -> string =
  let c = ref 0 in
  fun (s : string) ->
    incr c;
    Printf.sprintf "_%s%d" s !c

(* Amount of space an Oat type takes when stored in the satck, in bytes.
   Note that since structured values are manipulated by reference, all
   Oat values take 8 bytes on the stack.
*)
let size_oat_ty (t : Ast.ty) = 8L

(* Generate code to allocate an array of source type TRef (RArray t) of the
   given size. Note "size" is an operand whose value can be computed at
   runtime *)
let oat_alloc_array (t : Ast.ty) (size : Ll.operand) : Ll.ty * operand * stream
    =
  let ans_id, arr_id = (gensym "array", gensym "raw_array") in
  let ans_ty = cmp_ty @@ TRef (RArray t) in
  let arr_ty = Ptr I64 in
  ( ans_ty,
    Id ans_id,
    lift
      [
        (arr_id, Call (arr_ty, Gid "oat_alloc_array", [ (I64, size) ]));
        (ans_id, Bitcast (arr_ty, Id arr_id, ans_ty));
      ] )

let fst3 ((x : 'a), (y : 'b), (z : 'c)) : 'a = x

let snd3 ((x : 'a), (y : 'b), (z : 'c)) : 'b = y

let thd3 ((x : 'a), (y : 'b), (z : 'c)) : 'c = z

(* Compiles an expression exp in context c, outputting the Ll operand that will
   recieve the value of the expression, and the stream of instructions
   implementing the expression.

   Tips:
   - use the provided cmp_ty function!

   - string literals (CStr s) should be hoisted. You'll need to bitcast the
     resulting gid to (Ptr I8)

   - use the provided "oat_alloc_array" function to implement literal arrays
     (CArr) and the (NewArr) expressions

   - we found it useful to write a helper function
     cmp_exp_as : Ctxt.t -> Ast.exp node -> Ll.ty -> Ll.operand * stream
     that compiles an expression and optionally inserts a bitcast to the
     desired Ll type. This is useful for dealing with OAT identifiers that
     correspond to gids that don't quite have the type you want

*)
(*TODO rest of expression compiling*)

let rec cmp_exp (c : Ctxt.t) (exp : Ast.exp node) : Ll.ty * Ll.operand * stream
    =
  let match_binop (op : Ast.binop) (t : Ll.ty) (op1 : Ll.operand)
      (op2 : Ll.operand) : Ll.insn =
    match op with
    | Add -> Binop (Add, t, op1, op2)
    | Sub -> Binop (Sub, t, op1, op2)
    | Mul -> Binop (Mul, t, op1, op2)
    | IAnd -> Binop (And, t, op1, op2)
    | IOr -> Binop (Or, t, op1, op2)
    | Shl -> Binop (Shl, t, op1, op2)
    | Shr -> Binop (Lshr, t, op1, op2)
    | Sar -> Binop (Ashr, t, op1, op2)
    | Eq -> Icmp (Eq, I64, op1, op2)
    | Neq -> Icmp (Ne, I64, op1, op2)
    | Gt -> Icmp (Sgt, I64, op1, op2)
    | Gte -> Icmp (Sge, I64, op1, op2)
    | Lt -> Icmp (Slt, I64, op1, op2)
    | Lte -> Icmp (Sle, I64, op1, op2)
    | And -> Binop (And, t, op1, op2)
    | Or -> Binop (Or, t, op1, op2)
  in

  let cmp_binop (op : binop) (e1 : exp node) (e2 : exp node) :
      Ll.ty * Ll.operand * stream =
    let t = cmp_ty @@ thd3 @@ typ_of_binop op in
    let cmp_e1 = cmp_exp c e1 in
    let cmp_e2 = cmp_exp c e2 in
    let stream1 = thd3 cmp_e1 in
    let stream2 = thd3 cmp_e2 in
    let op1 = snd3 cmp_e1 in
    let op2 = snd3 cmp_e2 in
    let new_symbol = gensym "b" in
    (*Use b for binop variable*)
    let curr_stream = [ I (new_symbol, match_binop op t op1 op2) ] in
    (t, Ll.Id new_symbol, curr_stream @ stream1 @ stream2)
  in

  let match_unop (op : Ast.unop) (t : Ll.ty) (op1 : Ll.operand) : Ll.insn =
    match op with
    | Neg -> Binop (Mul, t, Const (-1L), op1)
    | Lognot -> Binop (Xor, t, Const 1L, op1)
    | Bitnot -> Binop (Xor, t, Const (-1L), op1)
  in

  let cmp_unop (op : unop) (e1 : exp node) : Ll.ty * Ll.operand * stream =
    let t = cmp_ty @@ snd @@ typ_of_unop op in
    let cmp_e1 = cmp_exp c e1 in
    let stream1 = thd3 cmp_e1 in
    let op1 = snd3 cmp_e1 in
    let new_symbol = gensym "u" in
    (*Use u for binop variable*)
    let curr_stream = [ I (new_symbol, match_unop op t op1) ] in
    (t, Ll.Id new_symbol, curr_stream @ stream1)
  in

  let cmp_id (id : Ast.id) : Ll.ty * Ll.operand * stream =
    let t, operand = Ctxt.lookup id c in
    let sym = gensym "l" in
    let sym_b = gensym "bc" in
    match (t, operand) with
    | Array (_, I8), Gid _ ->
        (* (Ptr I8, Id sym_b, lift [ (sym_b, Bitcast (Ptr t, operand, Ptr I8)) ]) *)
        ( Ptr I8,
          Id sym_b,
          lift [ (sym_b, Gep (Ptr t, operand, [ Const 0L; Const 0L ])) ] )
    | Struct [ _; Array (_, t') ], Gid _ ->
        let ty = Ptr (Struct [ I64; Array (0, t') ]) in
        (ty, Id sym_b, lift [ (sym_b, Bitcast (Ptr t, operand, ty)) ])
    | _ -> (t, Id sym, [ I (sym, Load (Ptr t, operand)) ])
  in

  let cmp_string (s : string) : Ll.ty * Ll.operand * stream =
    let s_sym = gensym "string" in
    let g_sym = gensym "g" in
    let b_sym = gensym "b" in
    let len = 1 + String.length s in
    let str =
      [
        (* I (b_sym, Bitcast (Ptr (Array (len, I8)), Id g_sym, Ptr I8)); *)
        I (g_sym, Gep (Ptr (Array (len, I8)), Gid s_sym, [ Const 0L; Const 0L ]));
        G (s_sym, (Array (len, I8), GString s));
      ]
    in
    (Ptr I8, Id g_sym, str)
  in
  let cmp_call (e : exp node) (es : exp node list) : Ll.ty * Ll.operand * stream
      =
    let id =
      match e.elt with Id id -> id | _ -> failwith "invalid call function"
    in
    let cmp_es = List.map (fun e -> cmp_exp c e) es in
    let t1, fname = Ctxt.lookup_function id c in
    let ret_t =
      match t1 with
      | Ptr (Fun (_, ret_t)) -> ret_t
      | _ -> failwith "invalid function lookup"
    in
    let new_sym = gensym "c" in
    let args_list = List.map (fun (t, op, _) -> (t, op)) cmp_es in
    let initial = [ I (new_sym, Call (ret_t, fname, args_list)) ] in
    let new_str =
      List.flatten @@ List.map (fun (_, _, str) -> str) cmp_es >@ initial
    in
    (ret_t, Id new_sym, new_str)
  in

  let cmp_index (e1 : exp node) (e2 : exp node) : Ll.ty * Ll.operand * stream =
    let t1, op1, str1 = cmp_exp c e1 in
    let t2, op2, str2 = cmp_exp c e2 in
    let new_s = gensym "gep" in
    let new_l = gensym "load" in
    let final_t =
      match t1 with
      | Ptr (Struct [ _; Array (_, t) ]) -> t
      | _ -> failwith @@ "not array " ^ string_of_ty t1 ^ string_of_operand op1
    in
    ( final_t,
      Id new_l,
      str1 >@ str2
      >@ lift
           [
             (new_s, Gep (t1, op1, [ Const 0L; Const 1L; op2 ]));
             (new_l, Load (Ptr final_t, Id new_s));
           ] )
  in

  let cmp_carr (t : ty) (es : exp node list) : Ll.ty * Ll.operand * stream =
    let alloc = oat_alloc_array t (Const (Int64.of_int @@ List.length es)) in
    let rec traverse_es els i =
      match els with
      | [] -> []
      | e :: els' ->
          let t, op, str = cmp_exp c e in
          let arr_id =
            match List.hd (thd3 alloc) with
            | I (i, _) -> i
            | _ -> failwith "wrong"
          in
          let sym_elem = gensym "elem" in
          str
          >@ lift
               [
                 ( sym_elem,
                   Gep
                     ( fst3 alloc,
                       Id arr_id,
                       [ Const 0L; Const 1L; Const (Int64.of_int i) ] ) );
                 (gensym "s", Store (t, op, Id sym_elem));
               ]
          >@ traverse_es els' (i + 1)
    in
    let str = traverse_es es 0 in
    (fst3 alloc, snd3 alloc, thd3 alloc >@ str)
  in

  match exp.elt with
  | CNull t -> (cmp_ty t, Null, [])
  | CBool b -> if b = true then (I1, Const 1L, []) else (I1, Const 0L, [])
  | CInt i -> (I64, Const i, [])
  | CStr s -> cmp_string s
  | CArr (t, es) -> cmp_carr t es
  | NewArr (t, e) -> oat_alloc_array t (snd3 @@ cmp_exp c e)
  | Id id -> cmp_id id
  | Index (e1, e2) -> cmp_index e1 e2
  | Call (e, es) -> cmp_call e es
  | Bop (op, e1, e2) -> cmp_binop op e1 e2
  | Uop (op, e) -> cmp_unop op e

let cmp_exp_as (c : Ctxt.t) (exp : Ast.exp node) (t_final : Ll.ty) :
    Ll.operand * stream =
  let t, op, str = cmp_exp c exp in
  let new_sym = gensym "gc" in
  let new_str = [ I (new_sym, Bitcast (t, op, t_final)) ] @ str in
  (Id new_sym, new_str)

(* Compile a statement in context c with return typ rt. Return a new context,
   possibly extended with new local bindings, and the instruction stream
   implementing the statement.

   Left-hand-sides of assignment statements must either be OAT identifiers,
   or an index into some arbitrary expression of array type. Otherwise, the
   program is not well-formed and your compiler may throw an error.

   Tips:
   - for local variable declarations, you will need to emit Allocas in the
     entry block of the current function using the E() constructor.

   - don't forget to add a bindings to the context for local variable
     declarations

   - you can avoid some work by translating For loops to the corresponding
     While loop, building the AST and recursively calling cmp_stmt

   - you might find it helpful to reuse the code you wrote for the Call
     expression to implement the SCall statement

   - compiling the left-hand-side of an assignment is almost exactly like
     compiling the Id or Index expression. Instead of loading the resulting
     pointer, you just need to store to it!

*)
let rec cmp_stmt (c : Ctxt.t) (rt : Ll.ty) (stmt : Ast.stmt node) :
    Ctxt.t * stream =
  let cmp_ret (op : exp node option) : Ctxt.t * stream =
    match op with
    | Some x ->
        let t, o, s = cmp_exp c x in
        (c, [ T (Ret (t, Some o)) ] @ s)
    (* begin match t with
         | I1 | I64 | Ptr _ | Fun _ ->  (c, [T (Ret (t, Some o))] @ s)
         | _ -> failwith "invalid return type"
         end *)
    | None -> (c, [ T (Ret (Void, None)) ])
  in

  let cmp_dec (id : Ast.id) (e : exp node) : Ctxt.t * stream =
    let t, operand, str = cmp_exp c e in
    let new_symbol_a = gensym "a" in
    (*use a for alloca pointers*)
    let new_symbol_s = gensym "s" in
    (*use s for store*)
    let new_str =
      [
        I (new_symbol_s, Store (t, operand, Id new_symbol_a));
        E (new_symbol_a, Alloca t);
      ]
      @ str
    in
    let new_ctxt = Ctxt.add c id (t, Id new_symbol_a) in
    (new_ctxt, new_str)
  in

  let cmp_index (e1 : exp node) (e2 : exp node) (e : exp node) : Ctxt.t * stream
      =
    let t1, op1, str1 = cmp_exp c e1 in
    let t2, op2, str2 = cmp_exp c e2 in
    let t, op, str = cmp_exp c e in
    let new_s = gensym "gep" in
    let new_l = gensym "load" in
    let final_t =
      match t1 with
      | Ptr (Struct [ _; Array (_, t) ]) -> t
      | _ -> failwith @@ "not array " ^ string_of_ty t1 ^ string_of_operand op1
    in
    let new_c = Ctxt.add c new_s (final_t, Id new_s) in
    ( new_c,
      str1 >@ str2 >@ str
      >@ lift
           [
             (new_s, Gep (t1, op1, [ Const 0L; Const 1L; op2 ]));
             (new_l, Store (final_t, op, Id new_s));
           ] )
  in

  (*TODO assignment using indexing into arrays*)
  let cmp_ass (lhs : exp node) (e : exp node) : Ctxt.t * stream =
    match lhs.elt with
    | Id id ->
        let t, op = Ctxt.lookup id c in
        let et, eop, str = cmp_exp c e in
        (* if et != t then failwith "typemismatch in assignment"; *)
        (c, [ I (gensym "s", Store (et, eop, op)) ] @ str)
    | Index (l1, l2) -> cmp_index l1 l2 e
    | _ -> failwith "invalid assignment lhs"
  in
  let cmp_if (e : exp node) (if_stmts : stmt node list)
      (else_stmts : stmt node list) : Ctxt.t * stream =
    let t, op, str = cmp_exp c e in
    if t != I1 then failwith "non boolean expression in if statement";
    let if_lbl = gensym "iflbl" in
    let else_lbl = gensym "elselbl" in
    let end_lbl = gensym "endlbl" in
    let if_streams = cmp_block c rt if_stmts in
    let else_streams = cmp_block c rt else_stmts in
    let br_term = [ T (Cbr (op, if_lbl, else_lbl)) ] in
    ( c,
      [ L end_lbl ] @ [ T (Br end_lbl) ] @ else_streams @ [ L else_lbl ]
      @ [ T (Br end_lbl) ] @ if_streams @ [ L if_lbl ] @ br_term @ str )
  in

  let cmp_while (e : exp node) (stmts : stmt node list) : Ctxt.t * stream =
    let t, op, str = cmp_exp c e in
    if t != I1 then failwith "non boolean expression in if statement";
    let cond_lbl = gensym "condlbl" in
    let start_lbl = gensym "startlbl" in
    let end_lbl = gensym "endlbl" in
    let br_term = [ T (Cbr (op, start_lbl, end_lbl)) ] in
    let body_stream = cmp_block c rt stmts in
    ( c,
      [ L end_lbl ] @ [ T (Br cond_lbl) ] @ body_stream @ [ L start_lbl ]
      @ br_term @ str @ [ L cond_lbl ] @ [ T (Br cond_lbl) ] )
  in

  let cmp_for (vdecls : vdecl list) (eoption : exp node option)
      (stmtoption : stmt node option) (stmts : stmt node list) : Ctxt.t * stream
      =
    let cond_lbl = gensym "condlbl" in
    let body_lbl = gensym "bodylbl" in
    let end_lbl = gensym "endlbl" in

    let cmp_declarations =
      List.map (fun (id, exp) -> cmp_stmt c rt (no_loc (Decl (id, exp)))) vdecls
    in
    let declarations =
      List.flatten @@ List.map (fun (c, str) -> str) cmp_declarations
    in
    let new_ctxt =
      c @ List.flatten @@ List.map (fun (c, str) -> c) cmp_declarations
    in
    let cond_t, cond_op, cond_str =
      match eoption with
      | Some exp -> cmp_exp new_ctxt exp
      | None -> cmp_exp new_ctxt (no_loc @@ CBool true)
    in
    if cond_t != I1 then failwith "non boolean expression in if statement";
    let stmt_ctxt, stmt_str =
      match stmtoption with
      | Some x -> cmp_stmt new_ctxt rt x
      | None -> (new_ctxt, [])
    in
    let body_str =
      List.flatten
      @@ List.map (fun stmt -> snd @@ cmp_stmt new_ctxt rt stmt) stmts
    in
    let cond_br = [ T (Cbr (cond_op, body_lbl, end_lbl)) ] in
    ( c,
      [ L end_lbl ] @ [ T (Br cond_lbl) ] @ stmt_str @ body_str @ [ L body_lbl ]
      @ cond_br @ cond_str @ [ L cond_lbl ] @ [ T (Br cond_lbl) ] @ declarations
    )
  in

  (* TODO: fix call *)
  match stmt.elt with
  | Assn (lhs, e) -> cmp_ass lhs e
  | Decl (id, e) -> cmp_dec id e
  | Ret x -> cmp_ret x
  | SCall (e, es) -> (c, thd3 @@ cmp_exp c (no_loc (Call (e, es))))
  | If (e, if_stmts, else_stmts) -> cmp_if e if_stmts else_stmts
  | For (vdecls, eoption, stmtoption, stmts) ->
      cmp_for vdecls eoption stmtoption stmts
  | While (e, stmts) -> cmp_while e stmts

(* Compile a series of statements *)
and cmp_block (c : Ctxt.t) (rt : Ll.ty) (stmts : Ast.block) : stream =
  snd
  @@ List.fold_left
       (fun (c, code) s ->
         let c, stmt_code = cmp_stmt c rt s in
         (c, code >@ stmt_code))
       (c, []) stmts

(* Adds each function identifer to the context at an
   appropriately translated type.

   NOTE: The Gid of a function is just its source name
*)
let cmp_function_ctxt (c : Ctxt.t) (p : Ast.prog) : Ctxt.t =
  List.fold_left
    (fun c -> function
      | Ast.Gfdecl { elt = { frtyp; fname; args } } ->
          let ft = TRef (RFun (List.map fst args, frtyp)) in
          Ctxt.add c fname (cmp_ty ft, Gid fname) | _ -> c)
    c p

(* Populate a context with bindings for global variables
   mapping OAT identifiers to LLVMlite gids and their types.

   Only a small subset of OAT expressions can be used as global initializers
   in well-formed programs. (The constructors starting with C).
*)

let cmp_global_ctxt (c : Ctxt.t) (p : Ast.prog) : Ctxt.t =
  let rec get_type_from_exp (e : exp) : Ll.ty =
    match e with
    | CNull t -> cmp_ty t
    | CBool _ -> I1
    | CInt _ -> I64
    | CStr s -> Array (1 + String.length s, I8)
    | CArr (t, es) ->
        let len = List.length es in
        let t_inside = get_type_from_exp (List.hd es).elt in
        Struct [ I64; Array (len, t_inside) ]
    | _ -> failwith "Invalid  expression for global declarations."
  in
  List.fold_left
    (fun c -> function
      | Ast.Gvdecl { elt = { name; init } } ->
          Ctxt.add c name (get_type_from_exp @@ init.elt, Gid name) | _ -> c)
    c p

(* Compile a function declaration in global context c. Return the LLVMlite cfg
   and a list of global declarations containing the string literals appearing
   in the function.

   You will need to
   1. Allocate stack space for the function parameters using Alloca
   2. Store the function arguments in their corresponding alloca'd stack slot
   3. Extend the context with bindings for function variables
   3. Compile the body of the function using cmp_block
   4. Use cfg_of_stream to produce a LLVMlite cfg from
*)
let cmp_fdecl (c : Ctxt.t) (f : Ast.fdecl node) :
    Ll.fdecl * (Ll.gid * Ll.gdecl) list =
  let f_type =
    (List.map (fun x -> cmp_ty @@ fst x) f.elt.args, cmp_ret_ty f.elt.frtyp)
  in
  let params = List.map (fun x -> snd x) f.elt.args in
  let new_symbols = List.map (fun _ -> gensym "pa") f.elt.args in
  let allocate_params =
    List.flatten
    @@ List.map
         (fun ((t_ast, id), new_sym) ->
           let t = cmp_ty t_ast in
           [
             I (gensym "s", Store (t, Id id, Id new_sym)); E (new_sym, Alloca t);
           ])
         (List.combine f.elt.args new_symbols)
  in
  let new_ctxt =
    List.fold_left
      (fun c ((t_ast, id), new_sym) -> Ctxt.add c id (cmp_ty t_ast, Id new_sym))
      c
      (List.combine f.elt.args new_symbols)
  in
  let cfg =
    cfg_of_stream
    @@ cmp_block new_ctxt (snd f_type) f.elt.body
    @ allocate_params
  in
  ({ f_ty = f_type; f_param = params; f_cfg = fst cfg }, snd cfg)

(* Compile a global initializer, returning the resulting LLVMlite global
   declaration, and a list of additional global declarations.

   Tips:
   - Only CNull, CBool, CInt, CStr, and CArr can appear as global initializers
     in well-formed OAT programs. Your compiler may throw an error for the other
     cases

   - OAT arrays are always handled via pointers. A global array of arrays will
     be an array of pointers to arrays emitted as additional global declarations
*)

(*TODO: Compile global array decl and fix string*)
let rec cmp_gexp c (e : Ast.exp node) : Ll.gdecl * (Ll.gid * Ll.gdecl) list =
  match e.elt with
  | CNull t -> ((cmp_ty t, GNull), [])
  | CBool b -> if b = true then ((I1, GInt 1L), []) else ((I1, GInt 0L), [])
  | CInt i -> ((I64, GInt i), [])
  | CStr s ->
      let len = 1 + String.length s in
      ((Array (len, I8), GString s), [])
  | CArr (t, es) -> (
      let len = List.length es in
      let arr_type = Struct [ I64; Array (len, cmp_ty t) ] in
      let g_es = List.map (fun e -> fst @@ cmp_gexp c e) es in
      match cmp_ty t with
      | Ptr (Struct _) ->
          let add_decls = List.map (fun e -> (gensym "nested", e)) g_es in
          ( ( arr_type,
              GStruct
                [
                  (I64, GInt (Int64.of_int len));
                  ( Array (len, cmp_ty t),
                    GArray
                      (List.map
                         (fun d -> (fst (snd d), GGid (fst d)))
                         add_decls) );
                ] ),
            add_decls )
      | _ ->
          ( ( arr_type,
              GStruct
                [
                  (I64, GInt (Int64.of_int len));
                  (Array (len, cmp_ty t), GArray g_es);
                ] ),
            [] ) )
  | x ->
      failwith @@ "Invalid  expression " ^ Astlib.string_of_exp e
      ^ "for global declarations."

(* Oat internals function context ------------------------------------------- *)
let internals = [ ("oat_alloc_array", Ll.Fun ([ I64 ], Ptr I64)) ]

(* Oat builtin function context --------------------------------------------- *)
let builtins =
  [
    ( "array_of_string",
      cmp_rty @@ RFun ([ TRef RString ], RetVal (TRef (RArray TInt))) );
    ( "string_of_array",
      cmp_rty @@ RFun ([ TRef (RArray TInt) ], RetVal (TRef RString)) );
    ("length_of_string", cmp_rty @@ RFun ([ TRef RString ], RetVal TInt));
    ("string_of_int", cmp_rty @@ RFun ([ TInt ], RetVal (TRef RString)));
    ( "string_cat",
      cmp_rty @@ RFun ([ TRef RString; TRef RString ], RetVal (TRef RString)) );
    ("print_string", cmp_rty @@ RFun ([ TRef RString ], RetVoid));
    ("print_int", cmp_rty @@ RFun ([ TInt ], RetVoid));
    ("print_bool", cmp_rty @@ RFun ([ TBool ], RetVoid));
  ]

(* Compile a OAT program to LLVMlite *)
let cmp_prog (p : Ast.prog) : Ll.prog =
  (* add built-in functions to context *)
  let init_ctxt =
    List.fold_left
      (fun c (i, t) -> Ctxt.add c i (Ll.Ptr t, Gid i))
      Ctxt.empty builtins
  in
  let fc = cmp_function_ctxt init_ctxt p in

  (* build global variable context *)
  let c = cmp_global_ctxt fc p in

  (* compile functions and global variables *)
  let fdecls, gdecls =
    List.fold_right
      (fun d (fs, gs) ->
        match d with
        | Ast.Gvdecl { elt = gd } ->
            let ll_gd, gs' = cmp_gexp c gd.init in
            (fs, ((gd.name, ll_gd) :: gs') @ gs)
        | Ast.Gfdecl fd ->
            let fdecl, gs' = cmp_fdecl c fd in
            ((fd.elt.fname, fdecl) :: fs, gs' @ gs))
      p ([], [])
  in

  (* gather external declarations *)
  let edecls = internals @ builtins in
  { tdecls = []; gdecls; fdecls; edecls }
