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
  | Some a, Some b -> subtype_struct_fields c a b
  | _ -> false

and subtype_struct_fields (c : Tctxt.t) (fs1 : Ast.field list)
    (fs2 : Ast.field list) : bool =
  match (fs1, fs2) with
  | _, [] -> true
  | [], f :: fs -> false
  | ( { fieldName = id1; ftyp = ty1 } :: fs1',
      { fieldName = id2; ftyp = ty2 } :: fs2' ) ->
    id1 = id2 && ty1 = ty2 && subtype_struct_fields c fs1' fs2'

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
let check_struct_subtypes (c : Tctxt.t) fs1 fs2 : bool =
  let s1 = List.sort (fun (id1, _) (id2, _) -> compare id1 id2) fs1 in
  let s2 =
    List.sort
      (fun { fieldName = id1 } { fieldName = id2 } -> compare id1 id2)
      fs2
  in
  let subtys = List.map2 (fun (_, t1) { ftyp = t2 } -> subtype c t1 t2) s1 s2 in
  List.fold_left ( && ) true subtys

let check_subtypes c tys1 tys2 : bool =
  List.fold_left ( && ) true
    (List.map2 (fun ty1 ty2 -> subtype c ty1 ty2) tys1 tys2)

let rec find_fields fs id =
  match fs with
  | { fieldName = name; ftyp = t } :: fs' ->
    if id = name then t else find_fields fs' id
  | [] -> raise Not_found

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
  | NewArr (t, e1, x, e2) ->
    typecheck_ty e c t;
    if typecheck_exp c e1 != TInt then type_error e "array size not int";
    if lookup_local_option x c != None then
      type_error e @@ x ^ " already defined";
    let e2_ty = typecheck_exp (add_local c x TInt) e2 in
    if subtype c e2_ty t then e2_ty
    else type_error e "invalid array definition"
  | Index (e1, e2) ->
    let arr_ty =
      match typecheck_exp c e1 with
      | TRef (RArray t) -> t
      | _ -> type_error e "not array type"
    in
    if typecheck_exp c e2 = TInt then arr_ty else type_error e "invalid index"
  | Length arr -> (
      match typecheck_exp c arr with
      | TRef (RArray t) -> TInt
      | _ -> type_error e "not array, cannot get length" )
  | CStruct (id, fs) ->
    let struc =
      match lookup_struct_option id c with
      | None -> type_error e @@ "undefined struct " ^ id
      | Some fs -> fs
    in
    if
      check_struct_subtypes c
        (List.map (fun (id, exp) -> (id, typecheck_exp c exp)) fs)
        struc
      = false
    then type_error e "invalid struct fields";
    TRef (RStruct id)
  | Proj (exp, id) -> (
      let s_id =
        match typecheck_exp c exp with
        | TRef (RStruct id) -> id
        | _ -> type_error e "not a struct"
      in
      let s_fs =
        match lookup_struct_option id c with
        | Some fs -> fs
        | _ -> type_error e "undefined struct"
      in
      try find_fields s_fs id
      with Not_found ->
        type_error e @@ "field " ^ id ^ " not defined for struct" )
  | Call (f, args) ->
    let f_args, f_ret =
      match typecheck_exp c f with
      | TRef (RFun (args, RetVal retty)) -> (args, retty)
      | _ -> type_error e "not function"
    in
    let args_tys = List.map (fun e -> typecheck_exp c e) args in
    if check_subtypes c args_tys f_args then f_ret
    else type_error e "invalid argument types"
  | Bop (Eq, e1, e2) | Bop (Neq, e1, e2) ->
    let e1_ty = typecheck_exp c e1 in
    let e2_ty = typecheck_exp c e2 in
    if subtype c e1_ty e2_ty && subtype c e2_ty e1_ty then TBool
    else type_error e "invalid comparison types"
  | Bop (bop, e1, e2) ->
    let e1_ty = typecheck_exp c e1 in
    let e2_ty = typecheck_exp c e2 in
    let t1, t2, final = typ_of_binop bop in
    if e1_ty = t1 && e2_ty = t2 then final
    else type_error e "invalid bop types"
  | Uop (uop, exp) ->
    let u_ty = typ_of_unop uop in
    let e_ty = typecheck_exp c exp in
    if e_ty = fst u_ty then snd u_ty else type_error e "illegal uop type"

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
let rec typecheck_stmt (tc : Tctxt.t) (s:Ast.stmt node) (to_ret:ret_ty) : Tctxt.t * bool =

  let rec typecheck_block (tc: Tctxt.t) (block:Ast.block) (to_ret:ret_ty) :Tctxt.t * bool =
    begin match block with
      | h::[] -> typecheck_stmt tc h to_ret
      | h::t -> let c,b = typecheck_stmt tc h to_ret in if b
        then type_error h ("Invalid return") else typecheck_block c t to_ret
      | [] -> type_error (Ast.no_loc "") ("empty block")
    end
  in


  let type_ass (lhs:exp node) (rhs:exp node):  Tctxt.t * bool =
    let t = typecheck_exp tc lhs in
    let t' = typecheck_exp tc rhs in
    if (subtype tc t' t = false) then type_error s ((string_of_ty t') ^ " not subtype of: " ^ (string_of_ty t));

    begin match lhs.elt with
      | Id id -> begin match lookup_global_option id tc with
          | Some gt -> begin match gt with
              | TRef(RFun _) ->  type_error s (id ^ " already defined as function") | _ -> () end
          | None -> ()
        end
      | _ -> ()
    end;
    let nc = begin match lhs.elt with
      | Id id -> add_local tc id t
      | _ -> tc
    end in
    (nc,false)
  in


  let type_decl (id:Ast.id) (e:exp node):  Tctxt.t * bool =
    begin match lookup_local_option id tc with
      | Some _ -> type_error s (id ^ " already defined as local variable")
      | None -> ()
    end;
    let t = typecheck_exp tc e in
    ((add_local tc id t),false)
  in

  let type_decls (vdecls :vdecl list) :Tctxt.t * bool =
    let new_c = List.fold_left(fun c (id,exp) -> fst @@ typecheck_stmt c {elt=(Decl(id, exp));loc=s.loc} to_ret) tc vdecls
    in (new_c, false)
  in


  let type_scall (fname:exp node) (args: exp node list) :Tctxt.t * bool =
    let id = match fname.elt with | Id id -> id | _ -> type_error s ("Invalid function name") in
    let args_t' = List.map (fun e -> typecheck_exp tc e) args in
    let args_t,return = match typecheck_exp tc fname with
      | TRef(RFun(args,ret)) -> (args,ret) | _ -> type_error s (id ^  " not a function") in
    if (return != RetVoid) then type_error s ("function " ^ id ^  " does not return void");
    let bools = try List.map2(fun t' t -> subtype tc t' t) args_t' args_t with
      | Invalid_argument _ -> type_error s ("function " ^ id ^ " has invalid input types") in
    (tc, List.for_all (fun b -> b) bools)
  in


  let type_if (cond: exp node) (ifb:block) (elseb:block) :Tctxt.t * bool =
    let c = typecheck_exp tc cond in
    if (c != Ast.TBool) then type_error s ("non boolean condition in if statement");
    let ci,rti = typecheck_block tc ifb to_ret in
    let ce, rte = typecheck_block ci elseb to_ret in
    (tc,(rti && rte))
  in


  let type_ret (exp:exp node option) :Tctxt.t * bool =
    begin match to_ret with
      | RetVoid -> begin match exp with | None -> (tc,true) | Some _  -> type_error s ("Function expects return void") end
      | RetVal ret_t ->
        begin match exp with
          | None -> type_error s ("Function returns void but expects return of type: " ^ (string_of_ty ret_t))
          | Some e ->
            let t_exp = typecheck_exp tc e in
            let ret_check = subtype tc t_exp ret_t in
            if (ret_check = false) then type_error s ("return type " ^ (string_of_ty t_exp) ^ " is not subset of " ^ (string_of_ty ret_t));
            (tc,true)
        end
    end


  in


  let type_for (vdecls: vdecl list) (eo: exp node option) (so: stmt node option) (body:block) :Tctxt.t * bool =
    let tc1 = fst @@ type_decls vdecls in
    let exp_t = begin match eo with
      | Some exp -> typecheck_exp tc1 exp
      | None -> TBool
    end in
    if(exp_t != TBool) then type_error s ("Condition expression has type: " ^ (string_of_ty exp_t) ^ " instead of boolean in for loop");
    let stmt_ret = begin match so with
      | Some stmt -> snd @@ typecheck_stmt tc1 stmt to_ret
      | None -> false
    end in
    if(stmt_ret = true) then type_error s ("For loop statement returns, which is not allowed!");
    let a,b = typecheck_block tc1 body to_ret in
    (tc, false)
  in

  let type_while (cond :exp node) (body: block) :Tctxt.t * bool =
    let exp_t = typecheck_exp tc cond in
    if(exp_t != TBool) then type_error s ("Condition expression has type: " ^ (string_of_ty exp_t) ^ " instead of boolean in while loop");
    let a,b = typecheck_block tc body to_ret in
    (tc,false)
  in


  begin match s.elt with
    | Assn (lhs,rhs) -> type_ass lhs rhs
    | Decl  (id, e) -> type_decl id e
    | Ret exp -> type_ret exp
    | SCall (fname,args) -> type_scall fname args
    | If (cond, ifb, elseb) -> type_if cond ifb elseb
    | Cast _ -> failwith "cast unimplemented"
    | For (vdecls, eo, so, body) -> type_for vdecls eo so body
    | While (cond, body) -> type_while cond body
  end


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
