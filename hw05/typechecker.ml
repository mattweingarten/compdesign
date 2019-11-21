open Ast
open Astlib
open Tctxt

(* Error Reporting ---------------------------------------------------------- *)
(* NOTE: Use type_error to report error messages for ill-typed programs. *)

exception TypeError of string

let type_error (l : 'a node) err =
  let _, (s, e), _ = l.loc in
  raise (TypeError (Printf.sprintf "[%d, %d] %s" s e err))

(* initial context: G0 ------------------------------------------------------ *)
(* The Oat types of the Oat built-in functions *)
let builtins =
  [
    ("array_of_string", ([ TRef RString ], RetVal (TRef (RArray TInt))));
    ("string_of_array", ([ TRef (RArray TInt) ], RetVal (TRef RString)));
    ("length_of_string", ([ TRef RString ], RetVal TInt));
    ("string_of_int", ([ TInt ], RetVal (TRef RString)));
    ("string_cat", ([ TRef RString; TRef RString ], RetVal (TRef RString)));
    ("print_string", ([ TRef RString ], RetVoid));
    ("print_int", ([ TInt ], RetVoid));
    ("print_bool", ([ TBool ], RetVoid));
  ]

(* binary operation types --------------------------------------------------- *)
let typ_of_binop : Ast.binop -> Ast.ty * Ast.ty * Ast.ty = function
  | Add | Mul | Sub | Shl | Shr | Sar | IAnd | IOr -> (TInt, TInt, TInt)
  | Lt | Lte | Gt | Gte -> (TInt, TInt, TBool)
  | And | Or -> (TBool, TBool, TBool)
  | Eq | Neq -> failwith "typ_of_binop called on polymorphic == or !="

(* unary operation types ---------------------------------------------------- *)
let typ_of_unop : Ast.unop -> Ast.ty * Ast.ty = function
  | Neg | Bitnot -> (TInt, TInt)
  | Lognot -> (TBool, TBool)

(* subtyping ---------------------------------------------------------------- *)
(* Decides whether H |- t1 <: t2
   - assumes that H contains the declarations of all the possible struct types

   - you will want to introduce addition (possibly mutually recursive)
      helper functions to implement the different judgments of the subtyping
      relation. We have included a template for subtype_ref to get you started.
      (Don't forget about OCaml's 'and' keyword.)
*)
let rec subtype (c : Tctxt.t) (t1 : Ast.ty) (t2 : Ast.ty) : bool =
  match (t1, t2) with
  | TInt, TInt | TBool, TBool -> true
  | TNullRef rty1, TNullRef rty2
  | TRef rty1, TRef rty2
  | TRef rty1, TNullRef rty2 ->
      subtype_ref c rty1 rty2
  | _ -> false

(* Decides whether H |-r ref1 <: ref2 *)
and subtype_ref (c : Tctxt.t) (t1 : Ast.rty) (t2 : Ast.rty) : bool =
  match (t1, t2) with
  | RString, RString -> true
  | RArray at1, RArray at2 -> subtype c at1 at2
  | RStruct id1, RStruct id2 -> subtype_struct c id1 id2
  | RFun (ts1, ret1), RFun (ts2, ret2) ->
      List.fold_left
        (fun x y -> x && y)
        true
        (List.map (fun (t1, t2) -> subtype c t1 t2) (List.combine ts1 ts2))
      && subtype_ret c ret1 ret2
  | _ -> false

(* will probably need fixing *)
and subtype_struct (c : Tctxt.t) (id1 : Ast.id) (id2 : Ast.id) : bool =
  match
    (Tctxt.lookup_struct_option id1 c, Tctxt.lookup_struct_option id2 c)
  with
  | Some a, Some b -> true
  | _ -> false

and subtype_ret (c : Tctxt.t) (t1 : Ast.ret_ty) (t2 : Ast.ret_ty) : bool =
  match (t1, t2) with
  | RetVoid, RetVoid -> true
  | RetVal rt1, RetVal rt2 -> subtype c rt1 rt2
  | _ -> false

(* well-formed types -------------------------------------------------------- *)
(* Implement a (set of) functions that check that types are well formed according
         to the H |- t and related inference rules

   - the function should succeed by returning () if the type is well-formed
            according to the rules

   - the function should fail using the "type_error" helper function if the
            type is

   - l is just an ast node that provides source location information for
            generating error messages (it's only needed for the type_error generation)

   - tc contains the structure definition context
*)
let rec typecheck_ty (l : 'a Ast.node) (tc : Tctxt.t) (t : Ast.ty) : unit =
  match t with
  | TInt | TBool -> ()
  | TRef rt | TNullRef rt -> typecheck_refty l tc rt

and typecheck_refty (l : 'a Ast.node) (tc : Tctxt.t) (t : Ast.rty) : unit =
  match t with
  | RString -> ()
  | RArray t -> typecheck_ty l tc t
  | RStruct id -> typecheck_struct l tc id
  | RFun (ts, rt) ->
      List.iter (typecheck_ty l tc) ts;
      typecheck_retty l tc rt

and typecheck_struct (l : 'a Ast.node) (tc : Tctxt.t) (id : Ast.id) : unit =
  match Tctxt.lookup_struct_option id tc with
  | Some _ -> ()
  | None -> type_error l @@ "undefined struct " ^ id

and typecheck_retty (l : 'a Ast.node) (tc : Tctxt.t) (t : Ast.ret_ty) : unit =
  match t with RetVoid -> () | RetVal ty -> typecheck_ty l tc ty

(* typechecking expressions ------------------------------------------------- *)
(* Typechecks an expression in the typing context c, returns the type of the
       expression.  This function should implement the inference rules given in the
       oad.pdf specification.  There, they are written:

           H; G; L |- exp : t

       See tctxt.ml for the implementation of the context c, which represents the
       four typing contexts: H - for structure definitions G - for global
       identifiers L - for local identifiers

       Returns the (most precise) type for the expression, if it is type correct
       according to the inference rules.

       Uses the type_error function to indicate a (useful!) error message if the
       expression is not type correct.  The exact wording of the error message is
       not important, but the fact that the error is raised, is important.  (Our
       tests also do not check the location information associated with the error.)

       Notes: - Structure values permit the programmer to write the fields in any
       order (compared with the structure definition).  This means that, given the
       declaration struct T { a:int; b:int; c:int } The expression new T {b=3; c=4;
       a=1} is well typed.  (You should sort the fields to compare them.)

*)
let rec typecheck_exp (c : Tctxt.t) (e : Ast.exp node) : Ast.ty =
  match e.elt with
  | CNull rty ->
      typecheck_ty e c (TRef rty);
      TNullRef rty
  | CBool _ -> TBool
  | CInt _ -> TInt
  | CStr _ -> TRef RString
  | Id id -> typecheck_exp_id e c id
  | CArr (t, es) ->
      typecheck_ty e c t;
      if
        List.fold_left ( && ) true
          (List.map (fun exp -> subtype c (typecheck_exp c exp) t) es)
      then t
      else type_error e "illegal array declaration"
  | _ -> failwith "todo"

and typecheck_exp_id (e : Ast.exp node) (c : Tctxt.t) (id : Ast.id) : Ast.ty =
  match Tctxt.lookup_local_option id c with
  | None -> lookup_global id c
  | Some t -> t

(* statements --------------------------------------------------------------- *)

(* Typecheck a statement
           This function should implement the statment typechecking rules from oat.pdf.

           Inputs:
   - tc: the type context
   - s: the statement node
   - to_ret: the desired return type (from the function declaration)

           Returns:
   - the new type context (which includes newly declared variables in scope
               after this statement
   - A boolean indicating the return behavior of a statement:
                false:  might not return
                true: definitely returns

                in the branching statements, both branches must definitely return

                Intuitively: if one of the two branches of a conditional does not
                contain a return statement, then the entier conditional statement might
                not return.

                looping constructs never definitely return

           Uses the type_error function to indicate a (useful!) error message if the
           statement is not type correct.  The exact wording of the error message is
           not important, but the fact that the error is raised, is important.  (Our
           tests also do not check the location information associated with the error.)

   - You will probably find it convenient to add a helper function that implements the
             block typecheck rules.
*)
let rec typecheck_stmt (tc : Tctxt.t) (s : Ast.stmt node) (to_ret : ret_ty) :
    Tctxt.t * bool =
  match s.elt with
  | Assn (lhs, e) -> (typecheck_stmt_ass tc lhs e, false)
  | Decl (id, e) -> (add_local tc id (typecheck_exp tc e), false)
  | _ -> failwith "not implemented"

and typecheck_stmt_ass (tc : Tctxt.t) (lhs : Ast.exp node) (e : Ast.exp node) :
    Tctxt.t =
  ( match lhs.elt with
  | Id id -> (
      match lookup_global_option id tc with
      | Some (TRef (RFun _)) | Some (TNullRef (RFun _)) ->
          type_error lhs @@ id ^ " is global function id"
      | _ -> () )
  | _ -> () );
  let lhs_t = typecheck_exp tc lhs in
  let ass_t = typecheck_exp tc e in
  if subtype tc ass_t lhs_t then tc else type_error e @@ "wrong assignment type"

and typecheck_stmt_scall (tc : Tctxt.t) (f : Ast.exp node)
    (args : Ast.exp node list) : Tctxt.t =
  let f_ty =
    match typecheck_exp tc f with
    | TRef (RFun (ts, RetVoid)) -> ts
    | _ -> type_error f "return type not void"
  in
  let args_ty = List.map (typecheck_exp tc) args in
  let subtys =
    List.map (fun (t1, t2) -> subtype tc t1 t2) (List.combine args_ty f_ty)
  in
  if List.fold_left ( && ) true subtys then tc
  else type_error f "arguments type mismatch"

(* struct type declarations ------------------------------------------------- *)
(* Here is an example of how to implement the TYP_TDECLOK rule, which is
               is needed elswhere in the type system.
  *)

(* Helper function to look for duplicate field names *)
let rec check_dups fs =
  match fs with
  | [] -> false
  | h :: t -> List.exists (fun x -> x.fieldName = h.fieldName) t || check_dups t

let typecheck_tdecl (tc : Tctxt.t) id fs (l : 'a Ast.node) : unit =
  if check_dups fs then type_error l ("Repeated fields in " ^ id)
  else List.iter (fun f -> typecheck_ty l tc f.ftyp) fs

(* function declarations ---------------------------------------------------- *)
(* typecheck a function declaration
   - extends the local context with the types of the formal parameters to the
              function
   - typechecks the body of the function (passing in the expected return type
   - checks that the function actually returns
*)
let typecheck_block (tc : Tctxt.t) (b : Ast.block) (retty : Ast.ret_ty)
    (nod : 'a Ast.node) =
  let rec recurse l stmts =
    match stmts with
    | [] -> type_error nod @@ "empty block"
    | [ s ] -> (
        match typecheck_stmt l s retty with
        | l1, true -> (l1, true)
        | _ -> type_error nod @@ "no return in function body" )
    | s :: sts -> (
        match typecheck_stmt l s retty with
        | l1, false -> recurse l1 sts
        | _ -> type_error nod @@ "invalid body" )
  in

  recurse tc b

let typecheck_fdecl (tc : Tctxt.t) (f : Ast.fdecl) (l : 'a Ast.node) : unit =
  let lc = List.fold_left (fun c (t, id) -> add_local c id t) tc f.args in
  if check_dups (List.map (fun (t, id) -> { fieldName = id; ftyp = t }) f.args)
  then type_error l @@ "duplicate args in fdecl " ^ f.fname
  else if snd (typecheck_block lc f.body f.frtyp l) = false then
    type_error l @@ "block does not return"

(* creating the typchecking context ----------------------------------------- *)

(* The following functions correspond to the
           judgments that create the global typechecking context.

           create_struct_ctxt: - adds all the struct types to the struct 'S'
           context (checking to see that there are no duplicate fields

             H |-s prog ==> H'


           create_function_ctxt: - adds the the function identifiers and their
           types to the 'F' context (ensuring that there are no redeclared
           function identifiers)

             H ; G1 |-f prog ==> G2


           create_global_ctxt: - typechecks the global initializers and adds
           their identifiers to the 'G' global context

             H ; G1 |-g prog ==> G2


           NOTE: global initializers may mention function identifiers as
           constants, but can't mention other global values *)

let create_struct_ctxt (p : Ast.prog) : Tctxt.t =
  let add_no_dup c id fs =
    match lookup_struct_option id c with
    | None -> add_struct c id fs
    | _ -> type_error (no_loc p) @@ "duplicate struct " ^ id
  in
  let rec build h prog =
    match prog with
    | [] -> h
    | Gtdecl { elt = id, fs } :: ps -> build (add_no_dup h id fs) ps
    | _ :: ps -> build h ps
  in
  build empty p

let create_function_ctxt (tc : Tctxt.t) (p : Ast.prog) : Tctxt.t =
  let typ_ftyp ars retty =
    List.iter (fun (t, _) -> typecheck_ty (no_loc p) tc t) ars;
    typecheck_retty (no_loc p) tc retty
  in
  let add_no_dup c id glob =
    match lookup_global_option id c with
    | None -> add_global c id glob
    | _ -> type_error (no_loc p) @@ "duplicate function name " ^ id
  in
  let rec build g prog =
    match prog with
    | [] -> g
    | Gfdecl { elt = { frtyp = ret_ty; fname = id; args; body = block } } :: ps
      ->
        typ_ftyp args ret_ty;
        build (add_no_dup g id (TRef (RFun (List.map fst args, ret_ty)))) ps
    | _ :: ps -> build g ps
  in
  build tc p

let create_global_ctxt (tc : Tctxt.t) (p : Ast.prog) : Tctxt.t =
  let add_no_dup c id t =
    match lookup_global_option id c with
    | None -> add_global c id t
    | _ -> type_error (no_loc p) @@ "duplicate global " ^ id
  in
  let rec build g prog =
    match prog with
    | [] -> g
    | Gvdecl { elt = { name = id; init = e } } :: ps ->
        build (add_no_dup g id (typecheck_exp g e)) ps
    | _ :: ps -> build g ps
  in
  build tc p

(* This function implements the |- prog and the H ; G |- prog
           rules of the oat.pdf specification.
*)
let typecheck_program (p : Ast.prog) : unit =
  let sc = create_struct_ctxt p in
  let fc = create_function_ctxt sc p in
  let tc = create_global_ctxt fc p in
  List.iter
    (fun p ->
      match p with
      | Gfdecl ({ elt = f } as l) -> typecheck_fdecl tc f l
      | Gtdecl ({ elt = id, fs } as l) -> typecheck_tdecl tc id fs l
      | _ -> ())
    p
