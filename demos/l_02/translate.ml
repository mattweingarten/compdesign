(* Translator from Simple to OCaml ---
 * Translate a simple imperative program into OCaml code by 
 * representing the OCaml program as a string.
 *)

;; open Simple

module OrderedVars = struct
  type t = var
  let compare = String.compare
end

module VSet = Set.Make(OrderedVars)
let (++) = VSet.union

(* 
  Calculate the set of variables mentioned in either an expression or a command. 
*)


let rec vars_of_exp (e:exp) : VSet.t =
  begin match e with
    | Var x -> VSet.singleton x
    | Add(e1, e2)
    | Mul(e1, e2)
    | Lt (e1, e2) ->
      (vars_of_exp e1) ++ (vars_of_exp e2)
    | Lit _ -> VSet.empty
  end

let rec vars_of_cmd (c:cmd) :VSet.t =
  begin match c with
    | Skip -> VSet.empty
    | Assn(x, e) -> (VSet.singleton x) ++ (vars_of_exp e)
    | IfNZ(e, c1, c2) ->
      (vars_of_exp e) ++
      (vars_of_cmd c1) ++
      (vars_of_cmd c2)
    | WhileNZ(e, c) ->
      (vars_of_exp e) ++
      (vars_of_cmd c)
    | Seq(c1, c2) ->
      (vars_of_cmd c1) ++
      (vars_of_cmd c2)
  end


(* 
  The translation invariants are guided by the _types_ of the operations:

  - variables are global state, so they become mutable references
  - expressions denote integers
  - commands denote imperative actions of type unit

  [[ X ]] : int ref

  [[ exp ]] : int

  [[ cmd ]] : unit
*)



let trans_var (x:var) : string =
  "v_" ^ x

let rec trans_exp (e:exp) : string =
  let trans_op (e1:exp) (e2:exp) (op:string) =
    Printf.sprintf "(%s %s %s)"
      (trans_exp e1) op (trans_exp e2)
  in
  
  begin match e with
    | Var x -> "!" ^ (trans_var x)
    | Add(e1, e2) -> trans_op e1 e2 "+"
    | Mul(e1, e2) -> trans_op e1 e2 "*"
    | Lt (e1, e2) ->
      Printf.sprintf "(if %s then 1 else 0)"
      (trans_op e1 e2 "<")
    | Lit l -> string_of_int l
  end

let rec trans_cmd (c:cmd) : string =
  begin match c with
    | Skip -> "()"
    | Assn(x, e) ->
      Printf.sprintf "%s := %s"
        (trans_var x) (trans_exp e)
    | IfNZ(e, c1, c2) ->
      Printf.sprintf "if %s <> 0 then (%s) else (%s)" (trans_exp e) (trans_cmd c1) (trans_cmd c2)
    | WhileNZ(e, c) ->
      Printf.sprintf "while %s <> 0 do\n %s done"
        (trans_exp e) (trans_cmd c)
    | Seq(c1, c2) ->
      Printf.sprintf "%s;\n%s"
        (trans_cmd c1) (trans_cmd c2)
  end

let trans_prog (c:cmd) : string =
  let vars = vars_of_cmd c in
  let decls =
    VSet.fold (fun x s ->
        Printf.sprintf "let %s = ref 0\n%s\n"
          (trans_var x) s)
      vars
      ""
  in
  Printf.sprintf "module Program = struct\n %s let run () = \n%s\nend"
  decls (trans_cmd c)

(* do some testing using the factorial code: Simple.factorial *) 
let _ = 
  Printf.printf ("%s\n") (trans_prog factorial) 

