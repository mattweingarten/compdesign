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
    | (Some f1, Some f2) -> compare_fields f1 f2
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
  failwith "todo: implement typecheck_stmt"


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
let typecheck_fdecl (tc : Tctxt.t) (f : Ast.fdecl) (l : 'a Ast.node) : unit =
  failwith "todo: typecheck_fdecl"

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
  Tctxt.empty

let create_function_ctxt (tc:Tctxt.t) (p:Ast.prog) : Tctxt.t =
  Tctxt.empty

let create_global_ctxt (tc:Tctxt.t) (p:Ast.prog) : Tctxt.t =
  Tctxt.empty


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
