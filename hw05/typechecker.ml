open Ast
open Astlib
open Tctxt

(* Error Reporting ---------------------------------------------------------- *)
(* NOTE: Use type_error to report error messages for ill-typed programs. *)

exception TypeError of string

let type_error (l : 'a node) err =
  let (_, (s, e), _) = l.loc in
  raise (TypeError (Printf.sprintf "[%d, %d] %s" s e err))


(* initial context: G0 ------------------------------------------------------ *)
(* The Oat types of the Oat built-in functions *)
let builtins =
  [ "array_of_string",  ([TRef RString],  RetVal (TRef(RArray TInt)))
  ; "string_of_array",  ([TRef(RArray TInt)], RetVal (TRef RString))
  ; "length_of_string", ([TRef RString],  RetVal TInt)
  ; "string_of_int",    ([TInt], RetVal (TRef RString))
  ; "string_cat",       ([TRef RString; TRef RString], RetVal (TRef RString))
  ; "print_string",     ([TRef RString],  RetVoid)
  ; "print_int",        ([TInt], RetVoid)
  ; "print_bool",       ([TBool], RetVoid)
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
  | Lognot       -> (TBool, TBool)

(* subtyping ---------------------------------------------------------------- *)
(* Decides whether H |- t1 <: t2
    - assumes that H contains the declarations of all the possible struct types

    - you will want to introduce addition (possibly mutually recursive)
      helper functions to implement the different judgments of the subtyping
      relation. We have included a template for subtype_ref to get you started.
      (Don't forget about OCaml's 'and' keyword.)
*)



let rec subtype (c : Tctxt.t) (t1 : Ast.ty) (t2 : Ast.ty) : bool =
  begin match (t1,t2) with
   | (TInt, TInt) -> true
   | (TBool, TBool) -> true
   | (TRef x, TRef y) | (TNullRef x, TNullRef y) | (TRef x, TNullRef y)  -> subtype_ref c x y
   | _ -> false
  end

(* Decides whether H |-r ref1 <: ref2 *)
and subtype_ref (c : Tctxt.t) (t1 : Ast.rty) (t2 : Ast.rty) : bool =
  let rec compare_fields (f1: Ast.field list) (f2: Ast.field list) : bool =
    begin match (f1,f2) with
      | ([], []) -> true
      | ([], _) -> false
      | h1::l1,h2::l2 ->
                 if ((h1.fieldName = h2.fieldName) && (h1.ftyp = h2.ftyp))
                 then compare_fields l1 l2
                 else false
      | (l1,[]) ->  true
    end
  in

  let subtype_struc  (id1:Ast.id) (id2:Ast.id) : bool =
   begin match (lookup_struct_option id1 c,lookup_struct_option id2 c) with
    | (Some f1, Some f2) -> compare_fields (List.sort(fun f -> compare f)f1) (List.sort(fun f -> compare f)f2)
    | _ -> false
   end
  in

  let subtype_fun ((args1:ty list), (ret1:ret_ty)) ((args2:ty list), (ret2:ret_ty)) :bool =
    List.for_all (fun (a1,a2) -> subtype c a1 a2) (List.combine args1 args2)
    && (sub_rt_type c ret1 ret2)
  in

  begin match (t1, t2) with
    | (RString, RString) -> true
    | (RArray x, RArray y) -> subtype c x y
    | (RStruct id1, RStruct id2) -> subtype_struc id1 id2
    | (RFun (args1, ret1), RFun (args2, ret2)) -> subtype_fun (args1, ret1) (args2, ret2)
    | _ -> false
  end

and sub_rt_type (c : Tctxt.t) (t1 : Ast.ret_ty ) (t2 : Ast.ret_ty ) : bool =
begin match (t1,t2) with
 | (RetVoid,RetVoid) -> true
 | (RetVal x, RetVal y) -> subtype c x y
 | _ -> false
end

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
  begin match t with
    | TInt -> ()
    | TBool -> ()
    | TRef x | TNullRef x -> typecheck_ref l tc x
  end

and typecheck_ref (l : 'a Ast.node) (tc : Tctxt.t) (t : Ast.rty) : unit =
 let error = TypeError("Typerror in reference type at: " ^ Range.string_of_range l.loc) in
 begin match t with
   | RString -> ()
   | RArray x -> typecheck_ty l tc x
   | RStruct id -> begin match lookup_struct_option id tc with | None -> raise error | Some _ -> () end
   | RFun (ts , ret_t) -> List.map(fun t -> typecheck_ty l tc t) ts; typecheck_ret l tc ret_t
 end
and typecheck_ret (l : 'a Ast.node) (tc : Tctxt.t) (t : Ast.ret_ty) : unit =
  begin match t with
    | RetVoid -> ()
    | RetVal x -> typecheck_ty l tc x
  end


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
(* let check_struct_subtypes (c : Tctxt.t) fs1 fs2 : bool =
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
    | Some t -> t *)



let rec typecheck_exp (c : Tctxt.t) (e : Ast.exp node) : Ast.ty =
  let error = TypeError("Type mismatch in expression: " ^ (string_of_exp e) ^
                        " at location" ^ (Range.string_of_range e.loc)) in


  let typecheck_binop (op:binop) (e1:exp node) (e2:exp node): Ast.ty =
    let t1,t2,t = typ_of_binop op in
    let c1, c2 = (typecheck_exp c e1 , typecheck_exp c e2) in
    if (c1 = t1 && c2 = t2) then t else raise error
  in

  let typecheck_unop (op:unop) (e:exp node) : Ast.ty =
    let t1,t = typ_of_unop op in
    let c1 = typecheck_exp c e in
    if (c1 = t1) then t else raise error
  in

  begin match e.elt with
    | CNull rty -> typecheck_ty e c (TRef rty); TNullRef rty
    | CBool _ -> TBool
    | CInt _ -> TInt
    | CStr _ -> TRef (RString)
    | Id id -> begin match lookup_option id c with | Some x -> x | None -> raise error end
    | CArr _ -> failwith "unimplmented"
    | NewArr _ -> failwith "unimplmented"
    | Index _ -> failwith "unimplmented"
    | Length _ -> failwith "unimplmented"
    | CStruct _ -> failwith "unimplmented"
    | Proj _ -> failwith "unimplmented"
    | Call _ -> failwith "unimplemented"
    | Bop (op, e1, e2) ->typecheck_binop op e1 e2
    | Uop (op, e) -> typecheck_unop op e
    (* | _ -> failwith "unimplemented" *)
  end

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


 let rec typecheck_block (tc: Tctxt.t) (block:Ast.block) (to_ret:ret_ty) :Tctxt.t * bool =
  begin match block with
    | h::[] -> typecheck_stmt tc h to_ret
    | h::t -> let c,b = typecheck_stmt tc h to_ret in if b
              then type_error h ("Invalid return") else typecheck_block c t to_ret
    | [] -> type_error (Ast.no_loc "") ("empty block")
  end

(* struct type declarations ------------------------------------------------- *)
(* Here is an example of how to implement the TYP_TDECLOK rule, which is
   is needed elswhere in the type system.
 *)

(* Helper function to look for duplicate field names *)
let rec check_dups fs =
  match fs with
  | [] -> false
  | h :: t -> (List.exists (fun x -> x.fieldName = h.fieldName) t) || check_dups t

let typecheck_tdecl (tc : Tctxt.t) id fs  (l : 'a Ast.node) : unit =
  if check_dups fs
  then type_error l ("Repeated fields in " ^ id)
  else List.iter (fun f -> typecheck_ty l tc f.ftyp) fs

(* function declarations ---------------------------------------------------- *)
(* typecheck a function declaration
    - extends the local context with the types of the formal parameters to the
      function
    - typechecks the body of the function (passing in the expected return type
    - checks that the function actually returns
*)
let rec check_dups_params args =
  match args with
    | [] -> false
    | h::t -> (List.exists (fun x -> h = x ) t) || check_dups_params t



let typecheck_fdecl (tc : Tctxt.t) (f : Ast.fdecl) (l : 'a Ast.node) : unit =
 if (check_dups_params (snd @@ List.split @@ f.args))
 then type_error l ("repeated paramater names in in " ^ f.fname)
 else let new_ctxt = List.fold_left(fun c (t,id) -> add_local c id t ) tc f.args in
 let block_ret = snd @@ typecheck_block new_ctxt (f.body) (f.frtyp) in
 if (block_ret = false) then type_error l ("block does not return" ^ f.fname)

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


let create_struct_ctxt (p:Ast.prog) : Tctxt.t =
  let c = Tctxt.empty in
  List.fold_right (fun decl ->
    match decl with
      | Gtdecl {elt=(id, fs)} -> begin match lookup_struct_option id c with
          | Some _ -> fun c -> c
          | None -> fun c -> add_struct c id fs;
        end
      | _ -> fun c -> c ) (List.rev p) c



let create_function_ctxt (tc:Tctxt.t) (p:Ast.prog) : Tctxt.t =
  let check_function_type (arg_types: Ast.ty list) (ret_ty:ret_ty): unit =
   let l = no_loc "" in
   List.iter (fun t -> typecheck_ty l tc t) arg_types; typecheck_ret l tc ret_ty
  in
  List.fold_right (fun decl ->
    match decl with
      | Gfdecl {elt={frtyp=ret_ty;fname=id;args=args;body=body;}} ->
        let arg_types = List.map(fun x -> fst x) args in
        begin match lookup_global_option id tc with
          | Some _ -> fun c -> c
          | None -> fun c -> check_function_type arg_types ret_ty;add_global c id (TRef(RFun(arg_types, ret_ty)))
        end
      | _ -> fun c -> c
    ) (List.rev p) tc

let create_global_ctxt (tc:Tctxt.t) (p:Ast.prog) : Tctxt.t =
  List.fold_right (fun decl ->
      match decl with
        | Gvdecl {elt={name=id;init=exp}} ->
          begin match lookup_global_option id tc with
            | Some _ -> fun c -> c
            | None -> fun c -> add_global c id (typecheck_exp c exp)
          end
        | _ -> fun c -> c
    ) (List.rev p) tc


(* This function implements the |- prog and the H ; G |- prog
   rules of the oat.pdf specification.
*)
let typecheck_program (p:Ast.prog) : unit =
  let sc = create_struct_ctxt p in
  let fc = create_function_ctxt sc p in
  let tc = create_global_ctxt fc p in
  List.iter (fun p ->
    match p with
    | Gfdecl ({elt=f} as l) -> typecheck_fdecl tc f l
    | Gtdecl ({elt=(id, fs)} as l) -> typecheck_tdecl tc id fs l
    | _ -> ()) p
