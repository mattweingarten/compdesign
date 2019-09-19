(* 
 *  OCaml datatypes that we use to represent
 *  a simple, imperative programming language. 
 *)

(*
 *
 * Recall the BNF grammar for this simple language:
 *
 *  <exp> ::= 
 *         |  <X>
 *         |  <exp> + <exp>
 *         |  <exp> * <exp>
 *         |  <exp> < <exp>
 *         |  <integer contant>
 *         |  (<exp>)
 *
 *  <cmd> ::= 
 *         |  skip
 *         |  <X> = <exp>
 *         |  ifNZ <exp> { <cmd> } else { <cmd> }
 *         |  whileNZ <exp> { <cmd> }
 *         |  <cmd>; <cmd>
 *
 *)

type var = string

(* Abstract syntax of arithmetic expressions *)
type exp =
  | Var of var
  | Add of exp * exp
  | Mul of exp * exp
  | Lt  of exp * exp
  | Lit of int

let arith : exp = Mul(Lit 3, Add(Lit 4, Lit 5))

(* Abstract syntax of commands *)
type cmd =
  | Skip
  | Assn of var * exp
  | IfNZ of exp * cmd * cmd
  | WhileNZ of exp * cmd
  | Seq     of cmd * cmd

let factorial : cmd =
  let x = "X" in
  let ans = "ANS" in
  Seq(Assn(x, Lit 6),
  Seq(Assn(ans, Lit 1),
      WhileNZ(Var x,
              Seq(Assn(ans, Mul(Var ans, Var x)),
                  Assn(x,   Add(Var x, Lit (-1) ))))))

let rec skips (n:int) (c:cmd) : cmd =
  if n = 0 then c else skips (n-1) (Seq(Skip, c))

let rec loop : cmd =
  WhileNZ (Lit 1, Skip)


(* Interpreter -------------------------------------------------------------- *)

type state = var -> int

let update (f:(var -> int)) (x:var) (v:int) : (var -> int) =
  fun y -> if y=x then v else f y

(*
let update : type a b. (a -> b) -> a -> b -> (a -> b) =
  fun f x v y -> if y=x then v else f y
 *)
                                
let rec interpret_exp (s:state) (e:exp) : int =
  begin match e with
    | Var x -> s x
    | Add(e1, e2) -> (interpret_exp s e1) + (interpret_exp s e2)
    | Mul(e1, e2) -> (interpret_exp s e1) * (interpret_exp s e2)
    | Lt(e1, e2)  -> if (interpret_exp s e1) < (interpret_exp s e2) then 1 else 0
    | Lit i -> i
  end


let rec interpret_cmd (s:state) (c:cmd) : state =
  begin match c with
    | Skip -> s

    (* | Assn(x, e) -> update s x (interpret_exp s e) *)
    | Assn(x, e) -> update s x @@ interpret_exp s e

    | IfNZ(e, c1, c2) ->
      if (interpret_exp s e) <> 0
      then interpret_cmd s c1
      else interpret_cmd s c2 

    | WhileNZ(e, c) -> interpret_cmd s (IfNZ(e, Seq(c, WhileNZ(e, c)), Skip))

    | Seq(c1, c2) ->
      let s1 = interpret_cmd s c1 in
      interpret_cmd s1 c2
  end


(* optimizations ------------------------------------------------------------ *)

let rec optimize_cmd (c:cmd) : cmd = 
  match c with
  | Assn(x, Var y) -> if x = y then Skip else c
  | Assn(_, _) -> c
  | WhileNZ (Lit 0, c) -> Skip
  | WhileNZ(Lit _, c) -> loop
  | WhileNZ(e, c) -> WhileNZ(e, optimize_cmd c)
  | Skip -> Skip
  | IfNZ(Lit 0, c1, c2) -> optimize_cmd c2
  | IfNZ(Lit _, c1, c2) -> optimize_cmd c1
  | IfNZ(e, c1, c2) -> IfNZ(e, optimize_cmd c1, optimize_cmd c2)
  | Seq(c1, c2) ->
    begin match (optimize_cmd c1, optimize_cmd c2) with
      | (Skip, c2') -> c2'
      | (c1', Skip) -> c1'
      | (c1', c2') -> Seq(c1', c2')
    end

(*
let init_state : state = fun _ -> 0
  
let _ =
  let s_ans = interpret_cmd init_state (optimize_cmd factorial) in 
  Printf.printf "ANS = %d\n" (s_ans "ANS")
 *)
