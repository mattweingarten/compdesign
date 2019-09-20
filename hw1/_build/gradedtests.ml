open Assert
open Hellocaml

(* Test suite for hellocaml.ml *)

(* This code is mostly based on a course held at *)
(* University of Pennsylvania (CIS341) by Steve Zdancewic. *)

(* Author: Steve Zdancewic *)
(* Modified by: Manuel Rigger *)

(* Do NOT modify this file -- we will overwrite it     *)
(* with our own version when testing your code.        *)

(* These tests will be used to grade your assignment *)

(*** Part 1 Tests ***)
let part1_tests : suite = [

  (* assert_eq asserts that the two values are equal *)
  GradedTest ("Problem1-1", 3, [
    ("pieces", assert_eq pieces 8);

  (* assert_eqf f v
   * asserts that applying a unit-accepting function f
   * returns the value v *)
    ("cube0", assert_eqf (fun () -> cube 0) 0);
    ("cube1", assert_eqf (fun () -> cube 1) 1);
    ("cube2", assert_eqf (fun () -> cube 2) 8);
    ("cube3", assert_eqf (fun () -> cube (-1)) (-1));
  ]);



  GradedTest ("Problem1-2", 3, [
    ("centimes_of1", assert_eqf (fun () -> centimes_of 0 0) 0);
    ("centimes_of2", assert_eqf (fun () -> centimes_of 1 1) 101);
    ("centimes_of3", assert_eqf (fun () -> centimes_of 50 5) 550);
  ]);

  GradedTest ("Problem1-3", 3, [
  ]);
]

(*** Part 2 Tests ***)
let part2_tests : suite = [
  GradedTest ("Problem2-1", 3, [
    ("third_of_three1", assert_eqf (fun () -> third_of_three triple) "some string");
    ("third_of_three2", assert_eqf (fun () -> third_of_three (1,2,3)) 3);
    ("third_of_three3", assert_eqf (fun () -> third_of_three ((),"a",false)) false);
  ]);

  GradedTest ("Problem2-1Manual", 3, [
  ]);

  GradedTest ("Problem2-2", 5,
    let id (x:int) : int = x in
    let const3 (x:string) : int = 3 in [
    ("compose_pair1", assert_eqf (fun () -> compose_pair (id, const3) "a") 3);
    ("compose_pair2", assert_eqf (fun () -> compose_pair (fst, pair_up) "a") "a");
    ("compose_pair3", assert_eqf (fun () -> compose_pair (double, fst) (pair_up 5)) 10);
  ]);
]

(*** Part 3 Tests ***)
let part3_tests : suite = [
  GradedTest ("Problem3-1", 5, [
    ("list_to_mylist1", assert_eqf (fun () -> list_to_mylist []) Nil);
    ("list_to_mylist2", assert_eqf (fun () -> list_to_mylist [1]) (Cons(1,Nil)));
    ("list_to_mylist3", assert_eqf (fun () -> list_to_mylist ["a";"b"]) (Cons("a",Cons("b",Nil))));
    ("list_to_mylist4", assert_eqf (fun () -> mylist_to_list (list_to_mylist [1;2;3;4;5])) [1;2;3;4;5]);
  ]);

  GradedTest ("Problem3-2", 5, [
    ("append1", assert_eqf (fun () -> append [] []) []);
    ("append2", assert_eqf (fun () -> append [] [1]) [1]);
    ("append3", assert_eqf (fun () -> append [1] []) [1]);
    ("append4", assert_eqf (fun () -> append [1] [1]) [1;1]);
    ("append5", assert_eqf (fun () -> append [1;2] [3]) [1;2;3]);
    ("append6", assert_eqf (fun () -> append [1] [2;3]) [1;2;3]);
    ("append7", assert_eqf (fun () -> append [true] [false]) [true;false]);
  ]);

  GradedTest ("Problem3-3", 5, [
    ("rev1", assert_eqf (fun () -> rev []) []);
    ("rev2", assert_eqf (fun () -> rev [1]) [1]);
    ("rev3", assert_eqf (fun () -> rev [1;2]) [2;1]);
    ("rev4", assert_eqf (fun () -> rev ["a";"b"]) ["b";"a"]);
  ]);

  GradedTest ("Problem3-4", 5, [
    ("rev_t1", assert_eqf (fun () -> rev_t []) []);
    ("rev_t2", assert_eqf (fun () -> rev_t [1]) [1]);
    ("rev_t3", assert_eqf (fun () -> rev_t [1;2]) [2;1]);
    ("rev_t4", assert_eqf (fun () -> rev_t ["a";"b"]) ["b";"a"]);
  ]);

  GradedTest ("Problem3-4Manual", 5, [
  ]);

  GradedTest ("Problem3-5", 5, [
    ("insert1", assert_eqf (fun () -> insert 1 []) [1]);
    ("insert2", assert_eqf (fun () -> insert 1 [1]) [1]);
    ("insert3", assert_eqf (fun () -> insert 1 [2]) [1;2]);
    ("insert4", assert_eqf (fun () -> insert 1 [0]) [0;1]);
    ("insert5", assert_eqf (fun () -> insert 1 [0;2]) [0;1;2]);
    ("insert6", assert_eqf (fun () -> insert "b" ["a";"c"]) ["a";"b";"c"]);
  ]);

  GradedTest ("Problem3-6", 5, [
    ("union1", assert_eqf (fun () -> union [] []) []);
    ("union2", assert_eqf (fun () -> union [1] []) [1]);
    ("union3", assert_eqf (fun () -> union [] [1]) [1]);
    ("union4", assert_eqf (fun () -> union [1] [1]) [1]);
    ("union5", assert_eqf (fun () -> union [1] [2]) [1;2]);
    ("union6", assert_eqf (fun () -> union [2] [1]) [1;2]);
    ("union7", assert_eqf (fun () -> union [1;3] [0;2]) [0;1;2;3]);
    ("union8", assert_eqf (fun () -> union [0;2] [1;3]) [0;1;2;3]);
  ]);
]


(*** Part 4 Tests ***)



let part4_tests : suite = [
  GradedTest ("Problem4-1", 5, [
    ("vars_of1", assert_eqf (fun () -> vars_of e1) []);
    ("vars_of2", assert_eqf (fun () -> vars_of e2) ["x"]);
    ("vars_of3", assert_eqf (fun () -> vars_of e3) ["x"; "y"]);
  ]);

  GradedTest ("Problem4-2", 5, [
    ("string_of1", assert_eqf (fun () -> string_of e1) "(2 * 3)");
    ("string_of2", assert_eqf (fun () -> string_of e2) "(x + 1)");
    ("string_of3", assert_eqf (fun () -> string_of e3) "(y * ((x + 1) * -((x + 1))))");
  ]);

  GradedTest ("Problem4-3", 5, [
    ("lookup1", assert_eqf (fun () -> lookup "x" ctxt1) 3L);
    ("lookup2", assert_eqf (fun () -> lookup "x" ctxt2) 2L);
    ("lookup3", assert_eqf (fun () -> lookup "y" ctxt2) 7L);
    ("lookup4", (fun () -> try ignore (lookup "y" ctxt1); failwith "bad lookup" with Not_found -> ()));
    ("lookup5", assert_eqf (fun () -> lookup "x" [("x", 1L);("x", 2L)]) 1L);
  ]);

  GradedTest ("Problem4-4", 5, [
    ("interpret1", assert_eqf (fun () -> interpret ctxt1 e1) 6L);
    ("interpret2", assert_eqf (fun () -> interpret ctxt1 e2) 4L);
    ("interpret3", (fun () -> try ignore (interpret ctxt1 e3); failwith "bad interpret" with Not_found -> ()));
  ]);

  GradedTest ("Problem4-4harder", 5, [
  ]);

  GradedTest ("Problem4-5", 5, [
    ("optimize1", assert_eqf (fun () -> optimize (Add(Const 3L, Const 4L))) (Const 7L));
    ("optimize2", assert_eqf (fun () -> optimize (Mult(Const 0L, Var "x"))) (Const 0L));
    ("optimize3", assert_eqf (fun () -> optimize (Add(Const 3L, Mult(Const 0L, Var "x")))) (Const 3L));
  ]);

  GradedTest ("Problem4-5harder", 5, [
  ]);

  GradedTest ("Problem4-5hardest", 5, [
  ]);

  GradedTest ("Problem5", 5, [
  ]);
]

let graded_tests : suite =
  part1_tests @
  part2_tests @
  part3_tests @
  part4_tests
