open Assert
open Hellocaml

(* These tests are provided by you -- they will be graded manually *)

(* You should also add additional test cases here to help you   *)
(* debug your program.                                          *)

let provided_tests : suite = [
  Test ("Student-Provided Tests For Problem 1-3", [
    ("case1", assert_eqf (fun () -> failwith "Problem 3 case1 test unimplemented") prob3_ans );
    ("case2", assert_eqf (fun () -> failwith "Problem 3 case2 test unimplemented") (prob3_case2 17) );
    ("case3", assert_eqf (fun () -> prob3_case3) 0);
  ]);
  
] 
