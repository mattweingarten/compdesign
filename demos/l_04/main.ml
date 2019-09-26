open Compile

(* Example source program expressions --------------------------------------- *)

(* X1 + (X2 + (X3 + (X4  (X5 + (X6 + (X6 + (X7 + (X8 + 341)))))))) *)
let src1 : Compile.exp =
  (Add(Var "X1",
       Add(Var "X2",
           Add(Var "X3",
               Add(Var "X4",
                   Add(Var "X5",
                       Add(Var "X6",
                           Add(Var "X7",
                               Add(Var "X8", Const 341L)))))))))
 

(* X1 * (X2 * (X3 * (X4  (X5 * (X6 * (X6 * (X7 * (X8 * 341)))))))) *)
let src2 : Compile.exp =
  (Mul(Var "X1",
       Mul(Var "X2",
           Mul(Var "X3",
               Mul(Var "X4",
                   Mul(Var "X5",
                       Mul(Var "X6",
                           Mul(Var "X7",
                               Mul(Var "X8", Const 341L)))))))))


(* X8 * X8 *)
let src3 : Compile.exp =
  (Mul(Var "X8", Var "X8"))

(* - (X8 * X8) *) 
let src4 : Compile.exp =
  Neg(Mul(Var "X8", Var "X8"))

(* ((341 * X3) + -(X1 * X2)) + ((X4 * X5) + (X6 + X7)) * (src3 * src3)) *)
let src5 : Compile.exp =
  Add(
    Add(
      Mul(Const 341L, Var "X3"),
      Neg(Mul(Var "X1", Var "X2"))),
    Mul(
      Add(Mul(Var "X4", Var "X5"),
          Add(Var "X6", Var "X7")),
      Neg(Mul(src3, src3))
    )
  )


(* compilation -------------------------------------------------------------- *)

let src = src3

(* Resulting x86 program after compilation *)
let tgt : X86.prog = compile1 src

(* Output the resulting s file *)
let s = X86.string_of_prog tgt

;; print_string s
