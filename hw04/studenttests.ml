open Ast
open Astlib
open Assert
open Driver
open Gradedtests

(* These tests are provided by you -- they will be graded manually *)

(* You should also add additional test cases here to help you   *)
(* debug your program.                                          *)

let provided_tests : suite = [
  GradedTest("levenstein test", 5, executed_oat_file [
      ("atprograms/levenshtein.oat", "", "1442500");
    ]);
] 


let graded_tests : suite = provided_tests
