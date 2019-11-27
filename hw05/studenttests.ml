open Assert
open Astlib
open Tctxt
open Gradedtests
(* 16923229, Simon Rodoni
   17921537, Matthew Weingarten *)


(*
  A = {x=INT}
  B = {x=INT;y=INT}
  ---> B <: A

  C = {a=A}
  D = {b=B;z=Int}
  E = {b=B;a=A}

  --> E <: C

  --> D !<: C (eventhough B<:A)
*)
let create_tctxt () : Tctxt.t=
  let c1 = Tctxt.empty in
  let c2 = add_struct c1 "A" [{fieldName="x";ftyp=TInt}] in
  let c3 = add_struct c2 "B" [{fieldName="x";ftyp=TInt};{fieldName="y";ftyp=TInt}] in
  let c4 = add_struct c3 "C" [{fieldName="a";ftyp=TRef(RStruct "A")}] in
  let c5 = add_struct c4 "D" [{fieldName="b";ftyp=TRef(RStruct "B")};{fieldName="z";ftyp=TInt}] in
  let c6 = add_struct c5 "E" [{fieldName="b";ftyp=TRef(RStruct "B")};{fieldName="a";ftyp=TRef(RStruct "A")}] in
  c6

let test_for_subtype c t1 t2 cond =
  Printf.sprintf "Check if %s is subtype of %s:\n" (string_of_ty t1) (string_of_ty t2),
  (fun () ->
    if (Typechecker.subtype c t1 t2 = cond) then ()
    else failwith "FAIL")

let unit_tests = [
  test_for_subtype (create_tctxt ()) (TRef(RStruct "E")) (TRef(RStruct "C")) true;
  test_for_subtype (create_tctxt ()) (TRef(RStruct "D")) (TRef(RStruct "C")) false;
]

let triangle_test = [
  ("triangle.oat","","2");
]

let provided_tests : suite = [
  Test("Moodle tests:", unit_tests);
  Test("Moodle triangle test:", executed_oat_file triangle_test);
]
