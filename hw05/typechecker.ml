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


let sort_fields (fields:Ast.field list) : Ast.field list =
  List.sort(fun f1 f2 -> compare (f1.fieldName) (f2.fieldName)) fields
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
      | (l1,[]) ->  true
      | h1::l1,h2::l2 ->
                 if ((h1.fieldName = h2.fieldName) && (h1.ftyp = h2.ftyp))
                 then compare_fields l1 l2
                 else false
    end
  in

  let subtype_struc  (id1:Ast.id) (id2:Ast.id) : bool =
   begin match (lookup_struct_option id1 c,lookup_struct_option id2 c) with
    | (Some f1, Some f2) -> compare_fields (sort_fields f1) (sort_fields f2)
    | _ -> false
   end
  in

  let subtype_fun ((args1:ty list), (ret1:ret_ty)) ((args2:ty list), (ret2:ret_ty)) :bool =
    let combined = try List.combine args1 args2 with Invalid_argument _ -> [(TBool,TInt)]  in
    (*This is just so it returns false if args different size instead of error*)
    List.for_all (fun (a1,a2) -> subtype c a2 a1) combined
    && (sub_rt_type c ret1 ret2)
  in

  begin match (t1, t2) with
    | (RString, RString) -> true
    | (RArray x, RArray y) -> x = y
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

let rec typecheck_exp (c : Tctxt.t) (e : Ast.exp node) : Ast.ty =

  let typecheck_binop (op:binop) (e1:exp node) (e2:exp node): Ast.ty =
    let c1, c2 = (typecheck_exp c e1 , typecheck_exp c e2) in
    begin match op with
      | Neq | Eq -> if (subtype c c1 c2) && (subtype c c1 c2) then TBool
                    else type_error e ("Comparing type " ^ (string_of_ty c1) ^ " with type " ^ (string_of_ty c2))
      | _ ->
        let t1,t2,t =  typ_of_binop op in
        if (c1 = t1 && c2 = t2) then t else type_error e ("Not correct type for binop: " ^ (string_of_binop op))
    end
  in

  let typecheck_unop (op:unop) (e:exp node) : Ast.ty =
    let t1,t = typ_of_unop op in
    let c1 = typecheck_exp c e in
    if (c1 = t1) then t else type_error e ("Not correct type for unop: " ^ (string_of_unop op))
  in

  let typecheck_carr (t:Ast.ty) (es:exp node list) :Ast.ty =
    typecheck_ty e c t;
    let ts = List.map (fun e -> subtype c (typecheck_exp c e) t)  es in
    let correct = List.for_all(fun b -> b = true) ts in
    if correct then TRef(RArray t) else type_error e ("Array elements not correct type: " ^ (string_of_ty t))
  in

  let typecheck_newarr (t:Ast.ty) (e1:exp node) (id:id) (e2:exp node): Ast.ty =
    typecheck_ty e c t;
    if (typecheck_exp c e1) != TInt then type_error e ("Array size not int in newArr");
    if lookup_local_option id c != None then type_error e (id ^ " already defined");
    let new_c = add_local c id TInt in
    let e2_t = typecheck_exp new_c e2 in
    if (subtype new_c e2_t t) then TRef(RArray t)
    else type_error e ((string_of_ty e2_t) ^ " not subtype of Array type: " ^ (string_of_ty t))
  in

  let typecheck_index (e1:exp node) (e2:exp node)  :Ast.ty =
    let arr_t = typecheck_exp c e1 in
    let t = begin match arr_t with
      | TRef(RArray x) -> x
      | _ -> type_error e ("Trying to index into non Array type")
    end in
    if((typecheck_exp c e2 ) = TInt) then t
    else type_error e ("Trying to Index into Array with non-Int type")
  in

  let typecheck_length (e:exp node) :Ast.ty =
    let arr_t = typecheck_exp c e in
    begin match arr_t with
      | TRef(RArray x) -> TInt
      | _ -> type_error e ("Calling length on non Array type")
    end
  in

  let typecheck_call (fname:exp node) (args: exp node list): Ast.ty =
    let args_t, ret_t = begin match typecheck_exp c fname with
      | TRef(RFun(x,RetVal y)) -> (x,y)
      | _ -> type_error e ((string_of_exp e) ^ " is not function in a call expression")
    end in
    let args_t' = List.map(fun e -> typecheck_exp c e) args in
    let subtypes = try List.map2 (fun t' t -> subtype c t' t) args_t' args_t
    with Invalid_argument _ -> type_error e ("Wrong amount of Input arguments in function: " ^ (string_of_exp fname)) in
    if (List.for_all (fun b -> b = true) subtypes) then ret_t
    else type_error e ("The function inputs are not the correct type in function: " ^ (string_of_exp fname))
  in


  let typecheck_struct (id:id) (es:(id * exp node) list) :Ast.ty =
    let fields = begin match lookup_struct_option id c with
              | Some x -> sort_fields x
              | None -> type_error e ("Undefined struct: " ^ id)
            end in
    let fields' = sort_fields @@ List.map(fun (id, e) ->{fieldName=id;ftyp=(typecheck_exp c e)}) es in
    let bools = try List.map2(fun f' f -> subtype c f'.ftyp f.ftyp) fields' fields
    with Invalid_argument  _ -> type_error e ("Structure " ^ id ^ " new declaration dont have the same amount of fields") in
    if(List.for_all(fun b -> b = true) bools) then TRef(RStruct id) else type_error e ("Fields dont match in structure " ^ id)
  in

  let typecheck_proj (e: exp node) (fieldname:id) :Ast.ty =
    let fields = begin match typecheck_exp c e with
      | TRef(RStruct id) -> begin match lookup_struct_option id c with
                             | Some x -> x
                             | None -> type_error e ("Trying to access non existent struct: " ^ id)
                            end
      | _ -> type_error e ("Trying to access field: " ^ fieldname ^ " in " ^ (string_of_exp e) ^ " which is not a struct")
    end in
    try (List.find(fun f -> f.fieldName = fieldname) fields).ftyp
    with Not_found -> type_error e ("Field: " ^ fieldname ^ " doesnt exist for structure" ^ (string_of_exp e))
  in


  begin match e.elt with
    | CNull rty -> typecheck_ty e c (TRef rty); TNullRef rty
    | CBool _ -> TBool
    | CInt _ -> TInt
    | CStr _ -> TRef RString
    | Id id -> begin match lookup_option id c with | Some x -> x | None -> type_error e (id ^ " not defined in ctxt") end
    | CArr (t,es) -> typecheck_carr t es
    | NewArr (t, e1, id ,e2) -> typecheck_newarr t e1 id e2
    | Index (e1,e2) -> typecheck_index e1 e2
    | Length e -> typecheck_length e
    | CStruct (id, es) -> typecheck_struct id es
    | Proj (e, id) -> typecheck_proj e id
    | Call (fname, args) -> typecheck_call fname args
    | Bop (op, e1, e2) ->typecheck_binop op e1 e2
    | Uop (op, e) -> typecheck_unop op e
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
      | [] -> (tc,false)
  end
  in


  let type_ass (lhs:exp node) (rhs:exp node):  Tctxt.t * bool =
    let t = typecheck_exp tc lhs in
    let t' = typecheck_exp tc rhs in
    if (subtype tc t' t = false) then type_error s ((string_of_ty t') ^ " not subtype of: " ^ (string_of_ty t));

    begin match lhs.elt with
      | Id id -> begin match lookup_local_option id tc with
                  | Some _ -> ()
                  | None ->        begin match lookup_global_option id tc with
                                      | Some gt -> begin match gt with
                                        | TRef(RFun _) ->  type_error s (id ^ " already defined as function")
                                        | _ -> () end
                                      | None -> ()
                                   end
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
    let args_t' = List.map (fun e ->  typecheck_exp tc e) args in
    let args_t,return = match typecheck_exp tc fname with
    | TRef(RFun(args,ret)) -> (args,ret) | _ -> type_error s (id ^  " not a function") in
    if (return != RetVoid) then type_error s ("function " ^ id ^  " does not return void");
    let bools = try List.map2(fun t' t -> subtype tc t' t) args_t' args_t with
    | Invalid_argument _ -> type_error s ("function " ^ id ^ " has invalid input types") in
    if((List.for_all( fun b -> b = true) bools)) then (tc, false)
    else type_error s ("Function args input are not supertypes of function in: " ^ (string_of_stmt s));

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


  let type_cast (rt :rty) (id: id) (e:exp node) (ifb: block) (elseb: block) :Tctxt.t * bool =
    let ref' = begin match (typecheck_exp tc e) with
      | TNullRef  rty -> rty
      | _ -> type_error s ("Ifq statment cond has type: " ^ (string_of_ty (typecheck_exp tc e))
                            ^ " but expected type: " ^ (string_of_ty (TRef (rt))))
    end in
    if ((subtype_ref tc ref' rt) = false )then
       type_error s ("Got type: " ^ (string_of_ty (TRef(ref'))) ^ " but expected: " ^ (string_of_ty (TRef (rt))))
    else
    let tc1, b1 = typecheck_block (add_local tc id (TRef(rt))) ifb to_ret in
    let tc2, b2 = typecheck_block tc elseb to_ret in
    (tc, b1 && b2)
  in

  begin match s.elt with
    | Assn (lhs,rhs) -> type_ass lhs rhs
    | Decl  (id, e) -> type_decl id e
    | Ret exp -> type_ret exp
    | SCall (fname,args) -> type_scall fname args
    | If (cond, ifb, elseb) -> type_if cond ifb elseb
    | Cast (rt, id, exp, ifb, elseb) -> type_cast rt id exp ifb elseb
    | For (vdecls, eo, so, body) -> type_for vdecls eo so body
    | While (cond, body) -> type_while cond body
  end


 let rec typecheck_block (tc: Tctxt.t) (block:Ast.block) (to_ret:ret_ty) :Tctxt.t * bool =
  begin match block with
    | h::[] -> typecheck_stmt tc h to_ret
    | h::t -> let c,b = typecheck_stmt tc h to_ret in if b
              then type_error h ("Invalid return") else typecheck_block c t to_ret
    | [] -> (tc,false)
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

(*Also adds builtins to ctxt*)
let create_struct_ctxt (p:Ast.prog) : Tctxt.t =
  let c_empty = Tctxt.empty in
  let c = List.fold_left (fun c (id, (ts, ret_t))-> add_global c id ((TRef(RFun(ts,ret_t)))))  c_empty builtins in
  List.fold_right (fun decl ->
    match decl with
      | Gtdecl {elt=(id, fs)} ->
        fun c ->
        begin match lookup_struct_option id c with
          | Some _ -> type_error (no_loc "") (id ^ " structure variable already declared(double decleration)")
          | None -> add_struct c id fs;
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
        fun c ->
        begin match lookup_global_option id c with
          | Some _ -> type_error (no_loc "") (id ^ " function already declared(double decleration)")
          | None -> check_function_type arg_types ret_ty;add_global c id (TRef(RFun(arg_types, ret_ty)))
        end
      | _ -> fun c -> c
    ) (List.rev p) tc

let create_global_ctxt (tc:Tctxt.t) (p:Ast.prog) : Tctxt.t =
  List.fold_right (fun decl ->
      match decl with
        | Gvdecl {elt={name=id;init=exp}} ->

          fun c ->
            (* TODO: error_global fptr scope*)
            begin match exp.elt with
              | Id id2 -> begin match lookup_global_option id2 c with
                            | Some _ ->
                              begin match lookup_global_option id2 tc with
                                | None -> type_error (no_loc "") ("cant assign global variable: " ^ id ^ " to another global variable: " ^ id2 )
                                | Some _ -> ()
                              end
                            | None -> ()
                          end
              | _ -> ()
            end;
            begin match lookup_global_option id c with
              | Some _ -> type_error (no_loc "") (id ^ " global variable already declared(double decleration)")
              | None -> add_global c id (typecheck_exp c exp)
            end
        | _ -> fun c -> c
    ) (List.rev p) tc


(* This function implements the |- prog and the H ; G |- prog
   rules of the oat.pdf specification.
*)
let typecheck_program (p:Ast.prog) : unit =
  let sc = create_struct_ctxt p in (*Also adds builtins to ctxt*)
  let fc = create_function_ctxt sc p in
  let tc = create_global_ctxt fc p in
  List.iter (fun p ->
    match p with
    | Gfdecl ({elt=f} as l) -> typecheck_fdecl tc f l
    | Gtdecl ({elt=(id, fs)} as l) -> typecheck_tdecl tc id fs l
    | _ -> ()) p
