(* astlib.ml *)

(* Helper functions of abstract syntax of trees. *)
(******************************************************************************)

open Format
open Ast
open Range  

(* 
 * Parse an AST from a lexbuf 
 * - the filename is used to generate error messages
 *)
(*  
let parse (filename : string) (buf : Lexing.lexbuf) : Ast.prog =
  try
    Lexer.reset_lexbuf filename 1 buf;
    Parser.toplevel Lexer.token buf
  with Parsing.Parse_error ->
    failwith (Printf.sprintf "Parse error at %s." (Range.string_of_range (Lexer.lex_range buf)))
*)


(** Precedence of binary operators. Higher precedences bind more tightly. *)
let prec_of_binop = function
| Mul -> 100
| Add | Sub -> 90

(** Precedence of expression nodes. *)
let prec_of_exp = function
| Bop (o,_,_) -> prec_of_binop o
| _ -> 200

let string_of_binop = function
| Mul   -> "*"
| Add   -> "+"
| Sub   -> "-"

let print_id_aux fmt t =
  pp_print_string fmt t.elt

let rec print_list_aux fmt sep pp l =
  begin match l with
    | [] -> ()
    | h::[] -> pp fmt h
    | h::tl -> 
	pp fmt h;
	sep ();
	print_list_aux fmt sep pp tl
  end

let rec print_const_aux fmt c =
  begin match c.elt with
    | CInt  v -> pp_print_string fmt (Int64.to_string v)
  end

and print_exp_aux fmt level e =
  let pps = pp_print_string fmt in
  let this_level = prec_of_exp e.elt in
  (if this_level < level then pps "(");
  (match e.elt with
  | Const  c -> print_const_aux fmt c
  | Id i -> print_id_aux fmt i
  | Bop (o,l,r) ->
      pp_open_box fmt 0;
      print_exp_aux fmt this_level l;
      pp_print_space fmt ();
      pp_print_string fmt (string_of_binop o);
      pp_print_space fmt ();
      print_exp_aux fmt this_level r;
      pp_close_box fmt ()
  );
  (if this_level < level then pps ")" )

let print_decl_aux semi fmt {elt={id; init}} =
  pp_open_hbox fmt ();
  pp_print_string fmt "int";
  pp_print_space fmt ();
  print_id_aux fmt id;
  pp_print_space fmt ();
  pp_print_string fmt " =";
  pp_print_space fmt ();
  print_exp_aux fmt 0 init;
  pp_print_string fmt semi;
  pp_close_box fmt ()

let rec print_block_aux fmt stmts =
  let pps = pp_print_string fmt in
  if (List.length stmts) > 0 then begin
    pps "{"; pp_force_newline fmt ();
    pps "  "; pp_open_vbox fmt 0;
    print_list_aux fmt (fun () -> pp_print_space fmt ()) print_stmt_aux stmts;
    pp_close_box fmt (); pp_force_newline fmt ();
    pps "}"
  end else pps "{ }"

and print_cond_aux fmt b_then opt_b_else =
  let pps = pp_print_string fmt in
  print_block_aux fmt b_then;
  begin match opt_b_else with
    | [] -> ()
    | b_else ->
      pps " else ";
      print_block_aux fmt b_else
  end

and print_stmt_aux fmt s =
  let pps = pp_print_string fmt in
  let ppsp = pp_print_space fmt in
  begin match s.elt with
    | Decl d -> print_decl_aux ";" fmt d

    | Assn (i,e) ->
	pp_open_box fmt 0;
	print_id_aux fmt i;
	pps " =";
	ppsp ();
	print_exp_aux fmt 0 e;
	pps ";";
	pp_close_box fmt ()

    | Ret (e) -> 
      pps "return";
      pps " "; print_exp_aux fmt 0 e; pps ";"

    | If(e, b_then, opt_b_else) ->
      pps "if ("; print_exp_aux fmt 0 e; pps ") ";
      print_cond_aux fmt b_then opt_b_else
        
    | While(e, b) ->
	pps "while ("; print_exp_aux fmt 0 e; pps ") ";
	print_block_aux fmt b

    | Block(b) -> print_block_aux fmt b
  end

let print_prog_aux fmt p =
  pp_open_vbox fmt 0;
  List.iter (fun s ->
      print_stmt_aux fmt s;
      pp_force_newline fmt ()
    ) p;
  pp_close_box fmt ()

let print_prog (p:prog) : unit =
  pp_open_hvbox std_formatter 0;
  print_prog_aux std_formatter p;
  pp_close_box std_formatter ();
  pp_print_newline std_formatter ()

let string_of_prog (p:prog) : string =
  pp_open_hvbox str_formatter 0;
  print_prog_aux str_formatter p;
  pp_close_box str_formatter ();
  flush_str_formatter ()

let print_stmt (s:stmt) : unit =
  pp_open_hvbox std_formatter 0;
  print_stmt_aux std_formatter s;
  pp_close_box std_formatter ();
  pp_print_newline std_formatter ()

let string_of_stmt (s:stmt) : string =
  pp_open_hvbox str_formatter 0;
  print_stmt_aux str_formatter s;
  pp_close_box str_formatter ();
  flush_str_formatter ()

let print_block (b:block) : unit =
  pp_open_hvbox std_formatter 0;
  print_block_aux std_formatter b;
  pp_close_box std_formatter ();
  pp_print_newline std_formatter ()
  
let string_of_block (b:block) : string =
  pp_open_hvbox str_formatter 0;
  print_block_aux str_formatter b;
  pp_close_box str_formatter ();
  flush_str_formatter ()

let print_exp (e:exp) : unit =
  pp_open_hvbox std_formatter 0;
  print_exp_aux std_formatter 0 e;
  pp_close_box std_formatter ();
  pp_print_newline std_formatter ()

let string_of_exp (e:exp) : string =
  pp_open_hvbox str_formatter 0;
  print_exp_aux str_formatter 0 e;
  pp_close_box str_formatter ();
  flush_str_formatter ()



(*
(* AST to ML *)
let ml_string_of_const (c:const) : string =
  match c with
    | Cnull _ -> Printf.sprintf "(Cnull (norange))"
    | Cbool (_,b) -> Printf.sprintf "(Cbool (norange, %b))" b
    | Cint (_,i) -> Printf.sprintf "(Cint (norange, %lil))" i
    | Cstring (_,s) -> Printf.sprintf "(Cstring (norange, %S))" s
    
let rec ml_string_of_typ (t:typ) : string =
  begin match t with
    | TBot -> failwith "Internal err (ast2ml): not accessible to users."
    | TBool -> "TBool"
    | TInt -> "TInt"
    | TRef r -> Printf.sprintf "(TRef (%s))" (ml_string_of_ref r)
    | TNullable r -> Printf.sprintf "(TNullable (%s))" (ml_string_of_ref r)
  end

and ml_string_of_ref (r:ref) : string =
  begin match r with    
    | RString -> "RString"
    | RClass cid -> Printf.sprintf "(RClass (\"%s\"))" cid
    | RArray (t) -> Printf.sprintf "(RArray (%s))" (ml_string_of_typ t)
  end

let ml_string_of_id ((_, id):Range.t*string) : string =
  Printf.sprintf "(norange, \"%s\")" id

let rec ml_string_of_exp (e:exp) : string = 
  begin match e with 
    | Const c -> Printf.sprintf "(Const %s)" (ml_string_of_const c)
    | This _ -> Printf.sprintf "(This norange)"
    | New (ty, e1, (_,id), e2) -> 
        Printf.sprintf "(New (%s, %s, (norange, \"%s\"), %s))"
          (ml_string_of_typ ty)
          (ml_string_of_exp e1) id (ml_string_of_exp e2)
    | Ctor (cid, es) -> Printf.sprintf "Ctor(%s, [%s])" (ml_string_of_id cid) 
        (ml_string_of_exps es)
    | LhsOrCall lc -> Printf.sprintf "(LhsOrCall %s)" 
        (ml_string_of_lhs_or_call lc)
    | Binop (o,l,r) -> (
	let binop_str = match o with
	  | Plus _ -> "Plus" | Times _ -> "Times" | Minus _ -> "Minus"
	  | Eq _ -> "Eq" | Neq _ -> "Neq" 
          | Lt _ -> "Lt" | Lte _ -> "Lte" | Gt _ -> "Gt" | Gte _ -> "Gte" 
          | And _ -> "And" | Or _ -> "Or"  | IAnd _ -> "IAnd" | IOr _ -> "IOr" 
	  | Shr _ -> "Shr" | Sar _ -> "Sar" | Shl _ -> "Shl" in
	  Printf.sprintf "(Binop (%s norange,%s,%s))" binop_str 
	    (ml_string_of_exp l) (ml_string_of_exp r)
      )
    | Unop (o,l) -> (
	let unop_str = match o with
	  | Neg _ -> "Neg" | Lognot _ -> "Lognot" | Not _ -> "Not" in
	  Printf.sprintf "(Unop (%s norange,%s))" unop_str (ml_string_of_exp l)
      )
  end


and ml_string_of_exps es : string =
  (List.fold_left (fun s e -> s ^ (ml_string_of_exp e) ^ "; " ) "" es)

and ml_string_of_lhs_or_call lc : string =
  match lc with
    | Lhs l -> Printf.sprintf "(Lhs %s)" (ml_string_of_lhs l)
    | Call c -> Printf.sprintf "(Call %s)" (ml_string_of_call c)

and ml_string_of_call c : string =
  match c with
    | Func (fid, es) -> Printf.sprintf "(Func (%s, [%s]))" (ml_string_of_id fid)
        (ml_string_of_exps es)
    | SuperMethod (id, es) -> Printf.sprintf "(SuperMethod (%s, [%s]))" 
        (ml_string_of_id id) (ml_string_of_exps es)
    | PathMethod (p, es) -> Printf.sprintf "(PathMethod (%s, [%s]))" 
        (ml_string_of_path p) (ml_string_of_exps es)

and ml_string_of_path p : string =
  match p with
    | ThisId id -> Printf.sprintf "(ThisId %s)" (ml_string_of_id id)
    | PathId (lc, id) -> Printf.sprintf "(PathId (%s, %s))" 
        (ml_string_of_lhs_or_call lc) (ml_string_of_id id)

and ml_string_of_lhs l : string = 
  begin match l with
    | Var id -> Printf.sprintf "(Var %s)" (ml_string_of_id id)
    | Path p -> Printf.sprintf "(Path %s)" (ml_string_of_path p)
    | Index (lc, e) -> Printf.sprintf "(Index (%s, %s))" 
        (ml_string_of_lhs_or_call lc) (ml_string_of_exp e)
  end

let rec ml_string_of_init (i:init) : string =
  begin match i with
    | Iexp e -> Printf.sprintf "(Iexp (%s))" (ml_string_of_exp e)
    | Iarray (_,is) -> Printf.sprintf "(Iarray (norange, [%s]))"
        (List.fold_left (fun s i -> s ^ (ml_string_of_init i) ^ "; ") "" is)
 end

let ml_string_of_vdecl {v_ty = vt; v_id=(_,id); v_init=vini} =
  Printf.sprintf "{v_ty=%s; v_id=(norange, \"%s\"); v_init=%s}" 
    (ml_string_of_typ vt) id (ml_string_of_init vini)

let ml_string_of_option (str: 'a -> string) (o:'a option) : string =
  begin match o with
    | None -> "None"
    | Some s -> ("(Some (" ^ (str s) ^ "))")
  end

let rec ml_string_of_block (vdls, stmts) =
  Printf.sprintf "([%s], [%s])"
    (List.fold_left (fun s d -> s ^ (ml_string_of_vdecl d) ^ ";\n") "" vdls)
    (List.fold_left (fun s d -> s ^ (ml_string_of_stmt d) ^ ";\n") "" stmts)

and ml_string_of_stmt (s:stmt) : string =
  begin match s with
    | Assign (l, e) -> Printf.sprintf "Assign(%s, %s)" (ml_string_of_lhs l)
	(ml_string_of_exp e)
    | Scall c -> Printf.sprintf "Scall(%s)" (ml_string_of_call c)
    | Fail (e) -> Printf.sprintf "Fail(%s)" (ml_string_of_exp e)
    | If(e, s, sopt) ->
	Printf.sprintf "If(%s, %s, %s)"
	  (ml_string_of_exp e)
	  (ml_string_of_stmt s)
	  (ml_string_of_option ml_string_of_stmt sopt)
    | IfNull(r, id, e, s, sopt) ->
	Printf.sprintf "IfNull(%s, %s, %s, %s, %s)"
          (ml_string_of_ref r) (ml_string_of_id id)
	  (ml_string_of_exp e) (ml_string_of_stmt s)
	  (ml_string_of_option ml_string_of_stmt sopt)
    | Cast(cid, id, e, s, sopt) ->
	Printf.sprintf "Cast(\"%s\", %s, %s, %s, %s)"
	  cid (ml_string_of_id id) 
          (ml_string_of_exp e) (ml_string_of_stmt s)
	  (ml_string_of_option ml_string_of_stmt sopt)
    | While(e, s) ->
	Printf.sprintf "While(%s, %s)"
	  (ml_string_of_exp e)
	  (ml_string_of_stmt s)
    | For(vdl, eopt, sopt, s) ->
	Printf.sprintf "For([%s], %s, %s, %s)"
	  (List.fold_left (fun s d -> s ^ (ml_string_of_vdecl d) ^ ";\n") "" vdl)
	  (ml_string_of_option ml_string_of_exp eopt)
	  (ml_string_of_option ml_string_of_stmt sopt)
	  (ml_string_of_stmt s)
    | Block b ->
	Printf.sprintf "Block%s" (ml_string_of_block b)
  end
	
let ml_string_of_fdecl ((topt, (_,fid), args, b, eopt):fdecl) : string =
  Printf.sprintf "(%s, (norange, \"%s\"), [%s], %s, %s)" 
    (ml_string_of_option ml_string_of_typ topt) fid 
    (List.fold_left (fun s (t, (_,id)) -> s ^ Printf.sprintf "(%s, (norange, \"%s\"))" (ml_string_of_typ t) id ^ ";\n") "" args)
    (ml_string_of_block b) (ml_string_of_option ml_string_of_exp eopt)

let ml_string_of_efdecl ((topt, (_,fid), args):efdecl) : string =
  Printf.sprintf "(%s, (norange, \"%s\"), [%s])" 
    (ml_string_of_option ml_string_of_typ topt) fid 
    (List.fold_left 
      (fun s (t, id) -> s ^ Printf.sprintf "(%s, %s)" (ml_string_of_typ t) 
        (ml_string_of_id id) ^ ";\n") "" args)

let ml_string_of_ctor ((args, es, cinits, b):ctor) : string =
  Printf.sprintf "([%s], [%s], [%s], %s)" 
    (List.fold_left 
      (fun s (t, id) -> s ^ Printf.sprintf "(%s, %s)" (ml_string_of_typ t) 
        (ml_string_of_id id) ^ ";\n") "" args)
    (List.fold_left (fun s e -> s ^ (ml_string_of_exp e) ^ ";\n") "" es)
    (List.fold_left (fun s (id,i) -> s ^ Printf.sprintf "(%s, %s)" 
      (ml_string_of_id id) (ml_string_of_init i) ^ ";\n") "" cinits)
    (ml_string_of_block b)

let ml_string_of_cdecl ((cid, extopt, fields, ctor, fds):cdecl) : string =
  Printf.sprintf "(\"%s\", %s, [%s], %s, [%s])" 
    cid
    (ml_string_of_option (Printf.sprintf "\"%s\"") extopt) 
    (List.fold_left 
      (fun s (t, id) -> s ^ Printf.sprintf "(%s, %s)" (ml_string_of_typ t) 
        (ml_string_of_id id) ^ ";\n") "" fields)
    (ml_string_of_ctor ctor)
    (List.fold_left (fun s f -> s ^ (ml_string_of_fdecl f) ^ ";\n") "" fds)

let ml_string_of_prog (p :prog) : string =
  Printf.sprintf "([%s])" 
    (List.fold_left 
      (fun s g -> 
        match g with
	  | Gvdecl d -> s ^ "Gvdecl(" ^ (ml_string_of_vdecl d) ^ ");\n"
          | Gefdecl f -> s ^ "Gefdecl(" ^ (ml_string_of_efdecl f) ^ ");\n"
          | Gfdecl f -> s ^ "Gfdecl(" ^ (ml_string_of_fdecl f) ^ ");\n"
          | Gcdecl c -> s ^ "Gcdecl(" ^ (ml_string_of_cdecl c) ^ ");\n"
      ) "" p)

(* Checking AST equivalence *)
let  eq_const c c' : bool =
  begin match (c, c') with
    | (Cnull _, Cnull _) -> true
    | (Cbool (_,b), Cbool (_, b')) -> b = b'
    | (Cint (_,i), Cint (_, i')) -> i = i'
    | (Cstring (_,s), Cstring (_, s')) -> s = s'
    | _ -> false
 end

let eq_binop o o' : bool =
  match (o, o') with
    | (Plus _, Plus _) -> true
    | (Times _, Times _) -> true
    | (Minus _, Minus _) -> true
    | (Eq _, Eq _) -> true
    | (Neq _, Neq _) -> true
    | (Lt _, Lt _) -> true
    | (Lte _, Lte _) -> true
    | (Gt _, Gt _) -> true
    | (Gte _, Gte _) -> true
    | (And _, And _) -> true
    | (Or _, Or _) -> true
    | (IAnd _, IAnd _) -> true
    | (IOr _, IOr _) -> true
    | (Shr _, Shr _) -> true
    | (Sar _, Sar _) -> true
    | (Shl _, Shl _) -> true
    | _ -> false

let eq_unop o o' : bool =
  match (o, o') with
    | (Neg _, Neg _) -> true
    | (Lognot _, Lognot _) -> true
    | (Not _, Not _) -> true
    | _ -> false

let eq_id (_,id) (_,id') : bool =
  id = id'

let rec eq_exp e e' : bool = 
  begin match (e, e') with 
    | (Const c, Const c') -> eq_const c c'
    | (This _, This _) -> true
    | (New (t1, e1, (_,id), e2), New (t2, e1', (_,id'), e2')) ->
        eq_typ t1 t2 && eq_exp e1 e1' && id = id' && eq_exp e2 e2'
    | (Ctor (cid, es), Ctor (cid', es')) ->
        begin try 
            List.iter2 
              (fun e -> fun e' -> if eq_exp e e' then () else failwith "not eq"
              ) es es';
            eq_id cid cid'
          with
 	    | _ -> false
        end
    | (LhsOrCall lc, LhsOrCall lc') -> eq_lhs_or_call lc lc'
    | (Binop (o,l,r), Binop (o',l',r')) -> 
        eq_binop o o' && eq_exp l l' && eq_exp r r'
    | (Unop (o,l), Unop (o',l')) ->
        eq_unop o o' && eq_exp l l'
    | _ -> false
  end

and eq_lhs_or_call lc lc' : bool =
  match (lc, lc') with
    | (Lhs l, Lhs l') -> eq_lhs l l'
    | (Call c, Call c') -> eq_call c c'
    | _ -> false

and eq_exps es es' : bool =
  try 
    List.iter2 
      (fun e -> fun e' -> if eq_exp e e' then () else failwith "not eq"
      ) es es';
    true
  with
    | _ -> false

and eq_call c c' : bool =
  match (c, c') with
    | (Func (fid, es), Func (fid', es')) -> eq_id fid fid' && eq_exps es es' 
    | (SuperMethod (id, es), SuperMethod (id', es')) ->
        eq_id id id' && eq_exps es es' 
    | (PathMethod (p, es), PathMethod (p', es')) ->
        eq_path p p' && eq_exps es es' 
    | _ -> false

and eq_path p p' : bool =
  match (p, p') with
    | (ThisId id, ThisId id') -> eq_id id id'
    | (PathId (lc, id), PathId (lc', id')) -> 
        eq_lhs_or_call lc lc' && eq_id id id'
    | _ -> false

and eq_lhs l l' : bool = 
  begin match (l, l') with
    | (Var id, Var id') -> eq_id id id' 
    | (Path p, Path p') -> eq_path p p'
    | (Index (lc, e), Index (lc', e')) -> eq_lhs_or_call lc lc' && eq_exp e e'
    | _ -> false
  end

and eq_typ t t' : bool =
  begin match (t, t') with
    | (TBot, TBot) -> true
    | (TBool, TBool) -> true
    | (TInt, TInt) -> true
    | (TRef r, TRef r') -> eq_ref r r'
    | (TNullable r, TNullable r') -> eq_ref r r'
    | _ -> false
  end

and eq_ref r r' : bool =
  begin match (r, r') with
    | (RString, RString) -> true
    | (RClass tid, RClass tid') -> tid = tid'
    | (RArray (t), RArray (t')) -> eq_typ t t'
    | _ -> false 
  end

let rec eq_init i i' : bool =
  begin match (i, i') with
    | (Iexp e, Iexp e') -> eq_exp e e'
    | (Iarray (_,is), Iarray (_,is')) -> 
        begin try 
            List.iter2 
              (fun i -> fun i' -> 
                 if eq_init i i' then ()
                 else failwith "not eq"
              ) is is';
            true
        with
          | _ -> false
        end
    | _ -> false
 end

let eq_vdecl {v_ty = vt; v_id=(_,id); v_init=vini}  
  {v_ty = vt'; v_id=(_,id'); v_init=vini'} : bool =
  eq_typ vt vt' && id = id' && eq_init vini vini'

let eq_option (eq: 'a -> 'a -> bool) (o:'a option) (o':'a option) : bool =
  begin match (o, o') with
    | (None, None) -> true
    | (Some s, Some s') -> eq s s'
    | _ -> false
  end

let rec eq_block (vdls, stmts) (vdls', stmts') : bool =
  try 
    List.iter2 
      (fun vdl -> fun vdl' -> 
        if eq_vdecl vdl vdl' then ()
        else failwith "not eq"
       ) vdls vdls';
    List.iter2 
      (fun st -> fun st' -> 
        if eq_stmt st st' then ()
        else failwith "not eq"
       ) stmts stmts';
    true         
  with
    | _ -> false
 
and eq_stmt s s' : bool =
  begin match (s, s') with
    | (Assign (l, e), Assign (l', e')) -> eq_lhs l l' && eq_exp e e'
    | (Scall c, Scall c') -> eq_call c c'
    | (Fail(e), Fail(e')) -> eq_exp e e'
    | (If(e, s, sopt), If(e', s', sopt')) ->
        eq_exp e e' && eq_stmt s s' && eq_option eq_stmt sopt sopt'
    | (IfNull(r, id, e, s, sopt), IfNull(r', id', e', s', sopt')) ->
        eq_ref r r' && eq_id id id' && eq_exp e e' && eq_stmt s s' && 
        eq_option eq_stmt sopt sopt'
    | (Cast(cid, id, e, s, sopt), Cast(cid', id', e', s', sopt')) ->
        cid = cid' && eq_id id id' && eq_exp e e' && 
        eq_stmt s s' && eq_option eq_stmt sopt sopt'
    | (While(e, s), While(e', s')) -> eq_exp e e' && eq_stmt s s' 
    | (For(vdls, eopt, sopt, s), For(vdls', eopt', sopt', s')) ->
         begin try 
           List.iter2 
             (fun vdl -> fun vdl' -> 
               if eq_vdecl vdl vdl' then ()
               else failwith "not eq"
             ) vdls vdls';
           eq_option eq_exp eopt eopt' &&
           eq_option eq_stmt sopt sopt' &&
           eq_stmt s s'
         with
           | _ -> false
 	 end
    | (Block b, Block b') -> eq_block b b'
    | _ -> false
  end
	
let eq_efdecl (topt, fid, args) (topt', fid', args') 
  : bool =
  eq_option eq_typ topt topt' &&
  eq_id fid fid' &&
  begin try 
    List.iter2 
      (fun (t, id) -> fun (t', id') -> 
         if (eq_typ t t' && eq_id id id') then () else failwith "not eq"
      ) args args';
    true
  with
    | _ -> false
  end


let eq_fdecl (topt, (_,fid), args, b, eopt) (topt', (_,fid'), args', b', eopt') 
  : bool =
  eq_option eq_typ topt topt' &&
  fid = fid' &&
  begin try 
    List.iter2 
      (fun (t, (_, id)) -> fun (t', (_, id')) -> 
         if (eq_typ t t' && id = id') then ()
         else failwith "not eq"
      ) args args';
    eq_block b b' &&
    eq_option eq_exp eopt eopt'
  with
    | _ -> false
  end

let eq_ctor (args, es, is, b) (args', es', is', b') 
  : bool =
  begin try 
    List.iter2 
      (fun (t, id) -> fun (t', id') -> 
         if (eq_typ t t' && eq_id id id') then () else failwith "not eq"
      ) args args';
    List.iter2 
      (fun e -> fun e' -> if (eq_exp e e') then () else failwith "not eq") 
      es es';
    List.iter2 
      (fun (id, i) -> fun (id', i') -> 
        if (eq_id id id' && eq_init i i') then () else failwith "not eq") 
      is is';
    eq_block b b'
  with
    | _ -> false
  end

let eq_cdecl (cid, extopt, fields, ctor, fs) (cid', extopt', fields', ctor', fs') 
  : bool =
  cid = cid' &&
  eq_option (=) extopt extopt' &&
  eq_ctor ctor ctor' &&
  try 
    List.iter2 
      (fun (t,id) -> fun (t',id') -> 
        if eq_typ t t' && eq_id id id' then () else failwith "not eq") 
      fields fields';
    List.iter2 
      (fun f -> fun f' -> if eq_fdecl f f' then () else failwith "not eq") 
      fs fs';
    true         
  with
    | _ -> false


let eq_prog p p' : bool =
  try
    List.iter2 
      (fun g -> fun g' -> 
        match (g, g') with
	  | (Gvdecl d, Gvdecl d') -> 
        if (eq_vdecl d d') then () else failwith "not eq"
      | (Gefdecl f, Gefdecl f') ->
        if (eq_efdecl f f') then () else failwith "not eq"
      | (Gfdecl f, Gfdecl f') ->
        if (eq_fdecl f f') then () else failwith "not eq"
      | (Gcdecl c, Gcdecl c') ->
        if (eq_cdecl c c') then () else failwith "not eq"
	  | _ -> failwith "not eq"
      ) p p';
    true
  with
    | _ -> false

let unop_info (uop: 'a unop) : 'a =
  match uop with
    | Neg i -> i
    | Lognot i -> i
    | Not i -> i

let binop_info (bop: 'a binop) : 'a =
  match bop with
      Plus i -> i
    | Times i -> i
    | Minus i -> i
    | Eq i -> i
    | Neq i -> i
    | Lt i -> i
    | Lte i -> i
    | Gt i -> i
    | Gte i -> i
    | And i -> i
    | Or i -> i
    | IAnd i -> i
    | IOr i -> i
    | Shl i -> i
    | Shr i -> i
    | Sar i -> i

let const_info (c: 'a const) : 'a =
  match c with
    | Cnull i -> i
    | Cbool (i, _) -> i
    | Cint (i, _) -> i
    | Cstring (i, _) -> i

let rec exp_info (e: exp) : Range.t =
  let get_last_exp_info es : Range.t option =
    match (List.rev es) with
      | [] -> None
      | e::_ -> Some (exp_info e)
  in
  match e with
      Const c -> const_info c
    | This i -> mk_parse_range i i
    | New (_ty,e1, _, e2) -> mk_parse_range (exp_info e1) (exp_info e2)
    | Ctor ((i, _), es) -> 
      begin match (get_last_exp_info es) with
	    | None -> i
	    | Some i' -> mk_parse_range i i'
      end
    | LhsOrCall lc -> lhs_or_call_info lc
    | Binop (bop, _e1, e2) -> mk_parse_range (binop_info bop) (exp_info e2) 
    | Unop (uop, e1) -> mk_parse_range (unop_info uop) (exp_info e1) 

and get_last_exp_info es : Range.t option =
    match (List.rev es) with
      | [] -> None
      | e::_ -> Some (exp_info e)

and path_info p : Range.t =
  match p with
    | ThisId (i, _) -> i
    | PathId (lc, (i, _)) -> mk_parse_range (lhs_or_call_info lc) i

and lhs_info (l: Range.t lhs) : Range.t =
  match l with
      Var (i, _) -> i
    | Path p -> path_info p
    | Index (lc, e) -> mk_parse_range (lhs_or_call_info lc) (exp_info e)

and lhs_or_call_info lc : Range.t =
  match lc with
    | Lhs l -> lhs_info l
    | Call c -> call_info c

and call_info c : Range.t =
  match c with
    | Func ((i, _), es) -> 
        begin match (get_last_exp_info es) with
	  | None -> i
	  | Some i' -> mk_parse_range i i'
        end
    | SuperMethod ((i, _), es) -> 
        begin match (get_last_exp_info es) with
	  | None -> i
	  | Some i' -> mk_parse_range i i'
        end
    | PathMethod (p, es) -> 
        let i = path_info p in
        begin match (get_last_exp_info es) with
	  | None -> i
	  | Some i' -> mk_parse_range i i'
        end

let init_info (i: Range.t init) : Range.t =
  match i with
    | Iexp e -> exp_info e
    | Iarray (r, _) -> r

let cinits_info (is: Range.t cinits) : Range.t =
  match is with
    | [] -> Range.ghost
    | ((r, _), i)::_ -> mk_parse_range r (init_info i)

let ast_of_int32 i : Range.t Ast.exp =
  Ast.Const ((Ast.Cint (Range.ghost, i) ))

let ast_of_int i   =
  Ast.Const ((Ast.Cint (Range.ghost, Int32.of_int i) ))

let ast_of_bool b = 
  Ast.Const (Ast.Cbool (Range.norange, b))


    
                       *)
