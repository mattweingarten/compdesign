(* IR1 development ---------------------------------------------------------- *)

(* This example corresponds to ir1.  It shows how we can "flatten" nested 
   expressions into a "let"-only subset of OCaml. 

   See the file ir1.ml for the implementation of this intermediate language.
*)

(* 
  Source language: simple arithmetic expressions with top-level immutable 
  variables X1 .. X8.

  example source program:   (1 + X4) + (3 + (X1 * 5) )

  The type translation of a source variable in the pure arithmetic langauge 
  is just an int64:
       [[X4]] : int64
*)


let (+.) = Int64.add
let ( *. ) = Int64.mul



let varX1 = 1L
let varX4 = 4L
let program : int64 =
  (1L +. varX4) +. (3L +. (varX1 *. 5L))


(* "denotation" functions encode the source-level operations as ML functions *)
let add = Int64.add
let mul = Int64.mul
let ret x = x           (* ret is there for uniformity *)

(* translation of the source expression into the let language *)
let program : int64 =
  let tmp1 = add 1L varX4 in
  let tmp2 = mul varX1 5L in
  let tmp3 = add 3L tmp2 in
  let tmp4 = add tmp1 tmp3 in
  ret tmp4 
  

(*   Exercise  *)
let program : int64 = (3L +. varX1) +. varX4

let program : int64 =
  let tmp1 = add 3L varX1 in
  let tmp2 = add tmp1 varX4 in
  ret tmp2






(* IR2 development ---------------------------------------------------------- *)

(* This example corresponds to ir2.  It shows how we translate imperative
   features into the IR by extending our 'let' notion.

   See the file ir2.ml for the implementation of this intermediate language.
*)


(*
  Source language: simple imperative language  with top-level mutable 
  variables X1 .. X8 and straight-line imperative code with assignment
  sequencing and skip:

  Example source program:

   X1 := (1 + X4) + (3 + (X1 * 5) ) ;
   Skip ;
   X2 := X1 * X1 ;


  The type translation of a source variable is now a reference:
     [[X1]] : int64 ref

  Expressions still denote syntactic values, but commands denote unit 
  computations:
     [[exp]] : opn  (syntactic value)
     [[cmd]] : unit
*)


let varX1 = ref 0L
let varX2 = ref 0L
let varX4 = ref 0L

(* "denotation" functions encode the source-level operations as ML functions *)
let load x = !x
let store o x = x := o

(* translation of the source expression into the simple imperative language *)
let program : unit =
  let tmp0 = load  varX4 in
  let tmp1 = add   1L tmp0 in
  let tmp2 = load  varX1 in
  let tmp3 = mul   tmp2 5L in
  let tmp4 = add   3L tmp3 in
  let tmp5 = add   tmp1 tmp4 in
  let _    = store tmp5 varX1 in
  let tmp6 = load  varX1 in
  let tmp7 = load  varX1 in 
  let tmp8 = mul   tmp6 tmp7 in
  let _    = store tmp8 varX2 in
  ()








(* IR3 development ---------------------------------------------------------- *)

(* This example corresponds to ir3.  From the low-level view, this IR adds
   labeled blocks and jumps.  The resulting datastructure is a kind of 
   control-flow graph.

   From the high-level point of view, we translate control-flow
   features into stylized OCaml by introducing mutually-recursive "functions"
   that are always in tail-call position.  Such functions correspond to jumps.

   See the file ir3.ml for the implementation of this intermediate language.
*)


(*  Example source program:

    X2 := X1 + X2;
    IFNZ X2 THEN {
      X1 := X1 + 1
    } ELSE {
      X2 := X1
    } ; 
    X2 := X2 * X1

*)



(*  (1) Identify the relevant parts of the control flow:

entry:
    X2 := X1 + X2;
    IFNZ X2 THEN

branch1:
      X1 := X1 + 1

    ELSE
branch2:
      X2 := X1

merge:
    X2 := X2 * X1

*)


(*  (2) Make control-flow transfers explicit:

entry:
    X2 := X1 + X2;
    IFNZ X2 THEN branch1 () ELSE branch2 ()

branch1:
      X1 := X1 + 1;
      merge ()


branch2:
      X2 := X1;
      merge ()

merge:
    X2 := X2 * X1;
    ret ()
*)



(*  (3) Translate the straight-line code as before.
  
entry:
    let tmp1 = load X1 in
    let tmp2 = load X2 in
    let tmp3 = add tmp1 tmp2 in
    let _ = store tmp3 X2 in
    let tmp4 = load x2 in

      <<CHOICE: HOW TO HANDLE CONDITIONALS?>> 
      ** Option 1: fold together conditional test with branch:
           if nz tmp4 branch1 branch2      

      ** Option 2: add a 'boolean' type to the target language:
         let tmp5 = icmp eq tmp 0L in    (* Note: tmp5 has type 'bool' *)
         cbr tmp5 branch1 branch2         

branch1:
    let tmp5 = load X1 in
    let tmp6 = add tmp5 1L in
    let _ = store tmp6 X1 in
      br merge 


branch2:
    let tmp7 = load X1 in
    let _ = store tmp 7 X2 in
      br merge

merge:
    let tmp8 = load X2 in
    let tmp9 = load X1 in
    let tmp10 = mul tmp8 tmp9 in
    let _ = store tmp10 X2 in
    ret ()
*)

let eq (x : int64) (y : int64) = x = y
let lt x y = x < y
let icmp cmpop x y = cmpop x y 

let cbr cnd lbl1 lbl2 =
  if cnd then lbl1 () else lbl2 ()

let br lbl = lbl ()

let program1 () = 
  let rec entry () =
    let tmp1 = load varX1 in
    let tmp2 = load varX2 in
    let tmp3 = add tmp1 tmp2 in
    let _    = store tmp3 varX2 in
    let tmp4 = load varX1 in
    let tmp5 = icmp eq tmp4 0L in    (* Note: tmp5 has type 'bool' *)
    cbr tmp5 branch2 branch1         
      
  and branch1 () =
    let tmp5 = load varX1 in
    let tmp6 = add tmp5 1L in
    let _    = store tmp6 varX1 in
    br merge 
      
  and branch2 () =
    let tmp7 = load varX1 in
    let _    = store tmp7 varX2 in
    br merge 
      
  and merge () =
    let tmp8  = load varX2 in
    let tmp9  = load varX1 in
    let tmp10 = mul tmp8 tmp9 in
    let _     = store tmp10 varX2 in
    ret ()
  in
  entry ()



(* One more example: everybody's favorite factorial command: 

     X1 := 6;
     X2 := 1;
     WhileNZ X1 DO
       X2 := X2 * X1;
       X1 := X1 + (-1);
     DONE
*)

let program2 () =
  let rec entry () =
    let _ = store 6L varX1 in
    let _ = store 1L varX2 in
    br loop 

  and loop () =
    let tmp1 = load varX1 in
    let tmp2 = icmp eq 0L tmp1 in
    cbr tmp2 merge body

  and body () =
    let tmp3 = load varX2 in
    let tmp4 = load varX1 in
    let tmp5 = mul tmp3 tmp4 in
    let _ = store tmp5 varX2 in
    let tmp6 = load varX1 in
    let tmp7 = add tmp6 (-1L) in
    let _ = store tmp7 varX1 in
    br loop 

  and merge () =
    ret ()
  in
  entry ()
    



(* IR4 development ---------------------------------------------------------- *)

(* What about top-level functions? 
    - calls
    - local storage
*)

(* (Hypothetical) Source:

   int64 square(int64 x) {
     x = x + 1;
     return (x * x);
   }

   void caller() {
     int x = 3;
     int y = square(x);
     print ( y + x );
   }
*)




(* Call-by-value or call by reference? *)

(* alloca : unit -> int64 ref *)

let alloca () =
  ref 0L

let call f x = f x
let print (x:int64) = Printf.printf "%s\n" (Int64.to_string x)

let square (arg : int64) : int64 =
  let rec entry () =
    let tmp_x = alloca () in
    
    let _ = store arg tmp_x in
    let tmp1 = load tmp_x in
    let tmp2 = load tmp_x in
    let tmp3 = mul tmp1 tmp2 in
    ret tmp3
  in
  entry()

let caller () : unit =
  let rec entry () =
    let tmp_x = alloca () in
    let _     = store 3L tmp_x in
    let tmp_y = alloca () in
    let tmp1 = load tmp_x in
    let tmp2 = call square tmp1 in
    let _    = store tmp2 tmp_y in
    let tmp3 = load tmp_x in
    let tmp4 = load tmp_y in
    let tmp5 = add tmp3 tmp4 in
    let _ = call print tmp5 in
    ret ()
  in
  entry ()

(*

int64 square (arg : int64) {
entry:
     %tmp_x = alloca () 
    
     _ = store arg %tmp_x 
     %tmp1 = load %tmp_x 
     %tmp2 = load %tmp_x 
     %tmp3 = mul %tmp1 %tmp2 
    ret %tmp3

}




let caller () : unit =
  let rec entry () =
    let tmp_x = alloca () in
    let _ = store 3L tmp_x in
    let tmp_y = alloca () in
    let tmp1 = load tmp_x in
    let tmp2 = call square tmp1 in
    let _ = store tmp2 tmp_y in
    let tmp3 = load tmp_x in
    let tmp4 = load tmp_y in
    let tmp5 = add tmp3 tmp4 in
    let _ = call print tmp5 in
    ret ()
}
*)


