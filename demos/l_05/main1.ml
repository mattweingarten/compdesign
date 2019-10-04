open Ir1

let p  = SRC.example
let ir = Compile.compile p
let s  = IR.pp_program ir    


let varX1 = 1L
let varX2 = 2L
let varX3 = 3L
let varX4 = 4L
let varX5 = 5L
let varX6 = 6L
let varX7 = 7L
let varX8 = 8L
  
;
print_string p;
print_string "\n";
print_string s;
print_string "\n"

