(* Implementation of a simple, command-oriented language. *)


(* grammar ------------------------------------------------------------------ *)
(*
 BNF grammar for this simple language:
  <exp> ::= 
         |  <X>
         |  <exp> + <exp>
         |  <exp> * <exp>
         |  <exp> < <exp>
         |  <integer contant>
         |  (<exp>)

  <cmd> ::= 
         |  skip
         |  <X> = <exp>
         |  ifNZ <exp> { <cmd> } else { <cmd> }
         |  whileNZ <exp> { <cmd> }
         |  <cmd>; <cmd>
*)

(* Abstract Syntax (AST) ---------------------------------------------------- *)

type var = string

type exp =
  | Var of var
  | Add of (exp * exp)
  | Mul of (exp * exp)
  | Lt  of (exp * exp)
  | Lit of int

type cmd =
  | Skip
  | Assn    of var * exp
  | IfNZ    of exp * cmd * cmd
  | WhileNZ of exp * cmd
  | Seq     of cmd * cmd



(* AST for Factorial Example ------------------------------------------------ *)
(*
        X = 6;
	ANS = 1;
	whileNZ (x) {
  		ANS = ANS * X;
  		X = X + -1;
	} 
 *)

let factorial : cmd =
  let x = "X" in
  let ans = "ANS" in
  Seq (Assn (x, Lit 6),
       Seq (Assn (ans, Lit 1),
            WhileNZ(Var x,
                    Seq (Assn(ans, Mul(Var ans, Var x)),
                         Assn(x, Add(Var x, Lit (-1)))))))

(* Interpreter -------------------------------------------------------------- *)

type state = var -> int

let rec interpret_exp (s:state) (e:exp) : int =
  match e with
  | Var x -> s x
  | Add (e1, e2) -> (interpret_exp s e1) + (interpret_exp s e2)
  | Mul (e1, e2) -> (interpret_exp s e1) * (interpret_exp s e2)
  | Lt  (e1, e2) -> if (interpret_exp s e1) < (interpret_exp s e2) then 1 else 0
  | Lit n -> n

let update s x v =
  fun y -> if x = y then v else s y

let rec interpret_cmd (s:state) (c:cmd) : state =
  match c with
  | Skip -> s
  | Assn (x, e1) ->
    let v = interpret_exp s e1 in
    update s x v
  | IfNZ (e1, c1, c2) ->
    if (interpret_exp s e1) = 0 then interpret_cmd s c2 else interpret_cmd s c1
  | WhileNZ (e, c) ->
    if (interpret_exp s e) = 0 then s else interpret_cmd s (Seq(c, WhileNZ (e, c)))
  | Seq (c1, c2) ->
    let s1 = interpret_cmd s c1 in
    interpret_cmd s1 c2
  
let init_state : state = fun _ -> 0
  
let main () =
  let s_ans = interpret_cmd init_state factorial in
  Printf.printf "ANS = %d\n" (s_ans "ANS")

(* let _ = main () *) 
;; main () 
