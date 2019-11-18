open Assert
open X86
open Driver
open Ll
open Backend

(* Do NOT modify this file -- we will overwrite it with our *)
(* own version when we test your project.                   *)

(* These tests will be used to grade your assignment *)

let fdecl_of_path path =
  Platform.verb @@ Printf.sprintf "* processing file: %s\n" path;
  let ll_ast = parse_ll_file path in
  match ll_ast.Ll.fdecls with
  | [_, fdecl] -> fdecl
  | _ -> failwith "test expected one fdecl"


let exec_e2e_ast ll_ast args extra_files =
  let output_path = !Platform.output_path in
  let dot_s_file = Platform.gen_name output_path "test" ".s" in
  let exec_file = Platform.gen_name output_path "exec" "" in
  let asm_ast = Backend.compile_prog ll_ast in
  let asm_str = X86.string_of_prog asm_ast in
  let _ = Driver.write_file dot_s_file asm_str in
  let _ = Platform.link (dot_s_file::extra_files) exec_file in
  let result = Driver.run_executable args exec_file in
  let _ = Platform.sh (Printf.sprintf "rm -f %s %s" dot_s_file exec_file) Platform.ignore_error in
  let _ = Platform.verb @@ Printf.sprintf "** Executable exited with: %d\n" result in
  Int64.of_int result
  

let exec_e2e_file path args =
  let ast = Driver.parse_ll_file path in
  exec_e2e_ast ast args []

let io_test path args =
  let ll_ast = Driver.parse_ll_file path in
  let output_path = !Platform.output_path in
  let dot_s_file = Platform.gen_name output_path "test" ".s" in
  let exec_file = Platform.gen_name output_path "exec" "" in
  let tmp_file = Platform.gen_name output_path "tmp" ".txt" in  
  let asm_ast = Backend.compile_prog ll_ast in
  let asm_str = X86.string_of_prog asm_ast in
  let _ = Driver.write_file dot_s_file asm_str in
  let _ = Platform.link (dot_s_file::["cinterop.c"]) exec_file in
  let args = String.concat " " args in
  let result = Driver.run_program args exec_file tmp_file in
  let _ = Platform.sh (Printf.sprintf "rm -f %s %s %s" dot_s_file exec_file tmp_file) Platform.ignore_error in
  let _ = Platform.verb @@ Printf.sprintf "** Executable output:\n%s\n" result in
  result

let c_link_test c_files path args =
  let ll_ast = Driver.parse_ll_file path in
  let output_path = !Platform.output_path in
  let dot_s_file = Platform.gen_name output_path "test" ".s" in
  let exec_file = Platform.gen_name output_path "exec" "" in
  let asm_ast = Backend.compile_prog ll_ast in
  let asm_str = X86.string_of_prog asm_ast in
  let _ = Driver.write_file dot_s_file asm_str in
  let _ = Platform.link (dot_s_file::c_files) exec_file in
  let args = String.concat " " args in
  let result = Driver.run_executable args exec_file in
  let _ = Platform.sh (Printf.sprintf "rm -f %s %s" dot_s_file exec_file) Platform.ignore_error in
    Int64.of_int result

let oat_file_test path args =
  let () = Platform.verb @@ Printf.sprintf "** Processing: %s\n" path in
  
  let output_path = !Platform.output_path in
  let dot_ll_file = Platform.gen_name output_path "test" ".ll" in
  let exec_file = Platform.gen_name output_path "exec" "" in
  let tmp_file = Platform.gen_name output_path "tmp" ".txt" in  

  let oat_ast = parse_oat_file path in
  Typechecker.typecheck_program oat_ast;
  let ll_ast = Frontend.cmp_prog oat_ast in
  let ll_str = Driver.string_of_ll_ast path ll_ast in
  let () = write_file dot_ll_file ll_str in
  let () = Platform.link (dot_ll_file::["runtime.c"]) exec_file in

  let result = Driver.run_program args exec_file tmp_file in
  let () = Platform.sh (Printf.sprintf "rm -f %s %s %s" dot_ll_file exec_file tmp_file) Platform.ignore_error in
  let () = Platform.verb @@ Printf.sprintf "** Executable output:\n%s\n" result in
  result

let oat_tc_ok_file_test path =
  let _ = Platform.verb @@ Printf.sprintf "** OAT Typechecker OK Processing: %s\n" path in
  let oat_ast = parse_oat_file path in
  let _= Typechecker.typecheck_program oat_ast in
  ()

let oat_tc_err_file_test path err =
  let _ = Platform.verb @@ Printf.sprintf "** OAT Typechecker Error Processing: %s\n" path in
  let oat_ast = parse_oat_file path in
  try 
    let _ = Typechecker.typecheck_program oat_ast in
    failwith @@ Printf.sprintf "Expected type error: %s" err
  with
  | Typechecker.TypeError s ->
    if s = err then () else
      failwith @@ Printf.sprintf "Expected type error: %s but got %s" err s

let executed tests =
  List.map (fun (fn, ans) ->
      fn, assert_eqf (fun () -> exec_e2e_file fn "") ans)
    tests

let executed_oat_file tests =
  List.map (fun (path, args, ans) ->
      (path ^ " args: " ^ args), assert_eqf (fun () -> oat_file_test path args) ans)
    tests

let executed_tc_ok_file tests =
  List.map (fun path ->
      ("typechecking: " ^ path, fun () -> oat_tc_ok_file_test path)) tests

let executed_tc_err_file tests =
  List.map (fun (path, err) ->
      ("typechecking: " ^ path, fun () -> oat_tc_err_file_test path err)) tests

  

let executed_io tests =
  List.map (fun (fn, args, ans) ->
      (fn ^ ":" ^ (String.concat " " args)), assert_eqf (fun () -> io_test fn args) ans)
    tests

let executed_c_link tests =
  List.map (fun (c_file, fn, args, ans) ->
      (fn ^ ":" ^ (String.concat " " args)), assert_eqf (fun () -> c_link_test c_file fn args) ans)
    tests

let typecheck path () =
  let () = Platform.verb @@ Printf.sprintf "** Processing: %s\n" path in
  let oat_ast = parse_oat_file path in
  Typechecker.typecheck_program oat_ast

let typecheck_error (a : assertion) () =
  try a (); failwith "Should have a type error" with Typechecker.TypeError s -> ()

let typecheck_correct (a : assertion) () =
  try a () with Typechecker.TypeError s -> failwith "Should not have had a type error"


let typecheck_file_error tests =
  List.map (fun p -> p, typecheck_error (typecheck p)) tests

let typecheck_file_correct tests =
  List.map (fun p -> p, typecheck_correct (typecheck p)) tests

let unit_tests = [
  "subtype_stringQ_stringQ",
   (fun () ->
       if Typechecker.subtype Tctxt.empty (TNullRef RString) (TNullRef RString) then ()
       else failwith "should not fail")                                                                                     
; ("no_subtype_stringQ_stringQ",
   (fun () ->
       if Typechecker.subtype Tctxt.empty (TNullRef RString) (TRef RString) then
         failwith "should not succeed" else ())
  )
]


let hw4_easiest_tests = [
  ("atprograms/easyrun1.oat", "", "17");
  ("atprograms/easyrun2.oat", "", "35");
  ("atprograms/easyrun3.oat", "", "73");
  ("atprograms/easyrun4.oat", "", "6");
  ("atprograms/easyrun5.oat", "", "212");
  ("atprograms/easyrun6.oat", "", "9");
  ("atprograms/easyrun7.oat", "", "23");
  ("atprograms/easyrun8.oat", "", "160");
  ("atprograms/easyrun9.oat", "", "236");
]

let hw4_globals_tests = [
  ("atprograms/globals1.oat", "", "42");
  ("atprograms/globals2.oat", "", "17");
  ("atprograms/globals3.oat", "", "17");
  ("atprograms/globals4.oat", "", "5");
  ("atprograms/globals5.oat", "", "17");
  ("atprograms/globals6.oat", "", "15");
]

let hw4_path_tests = [
 ("atprograms/path1.oat", "", "17");
 ("atprograms/path2.oat", "", "35");
 ("atprograms/path3.oat", "", "3");
 ("atprograms/arrayargs1.oat", "", "17");
 ("atprograms/arrayargs2.oat", "", "17");
 ("atprograms/arrayargs3.oat", "", "34");
]

let hw4_easy_tests = [
    ("atprograms/run26.oat", "", "0");
    ("atprograms/run27.oat", "", "99");
    ("atprograms/run28.oat", "", "18");
    ("atprograms/run29.oat", "", "1");
    ("atprograms/run30.oat", "", "9");
    ("atprograms/run31.oat", "", "9");
    ("atprograms/run13.oat", "", "1");
    ("atprograms/run32.oat", "", "33");
    ("atprograms/run21.oat", "", "99");
    ("atprograms/run33.oat", "", "1");
    ("atprograms/run34.oat", "", "66");
    ("atprograms/run38.oat", "", "31");
    ("atprograms/run39.oat", "a", "2");
    ("atprograms/run40.oat", "", "8");
    ("atprograms/run41.oat", "", "3");
    ("atprograms/run42.oat", "", "2");
    ("atprograms/run49.oat", "", "abc0");
    ("atprograms/run50.oat", "", "abcde0");
    ("atprograms/run60.oat", "", "85");
    ("atprograms/run61.oat", "", "3410");
]

let hw4_medium_tests = [
  ("atprograms/fact.oat", "", "1200");
  ("atprograms/run1.oat", "", "153");
  ("atprograms/run2.oat", "", "6");
  ("atprograms/run8.oat", "", "2");
  ("atprograms/run9.oat", "", "4");
  ("atprograms/run10.oat", "", "5");
  ("atprograms/run11.oat", "", "7");
  ("atprograms/run14.oat", "", "16");
  ("atprograms/run15.oat", "", "19");
  ("atprograms/run16.oat", "", "13");
  ("atprograms/run22.oat", "", "abc0");
  ("atprograms/run23.oat", "", "1230");
  ("atprograms/run25.oat", "", "nnn0");
  ("atprograms/run46.oat", "", "420");
  ("atprograms/run47.oat", "", "3");
  ("atprograms/run48.oat", "", "11");
  ("atprograms/lib4.oat", "", "53220");
  ("atprograms/lib5.oat", "", "20");
  ("atprograms/lib6.oat", "", "56553");
  ("atprograms/lib7.oat", "", "53");
  ("atprograms/lib8.oat", "", "Hello world!0");
  ("atprograms/lib9.oat", "a b c d", "abcd5");
  ("atprograms/lib11.oat", "", "45");
  ("atprograms/lib14.oat", "", "~}|{zyxwvu0");
  ("atprograms/lib15.oat", "123456789", "456780");
]

let hw4_hard_tests = [
("atprograms/fac.oat", "", "120");
("atprograms/qsort.oat", "", "kpyf{shomfhkmopsy{255");
("atprograms/bsort.oat", "", "y}xotnuw notuwxy}255");
("atprograms/msort.oat", "", "~}|{zyxwvu uvwxyz{|}~ 0");
("atprograms/msort2.oat", "", "~}|{zyxwvu uvwxyz{|}~ 0");
("atprograms/selectionsort.oat", "", "01253065992000");
("atprograms/matrixmult.oat", "", "19 16 13 23 \t5 6 7 6 \t19 16 13 23 \t5 6 7 6 \t0");
]

let hw4_old_student_tests = [
    ("atprograms/binary_search.oat", "", "Correct!0")
  ; ("atprograms/xor_shift.oat", "", "838867572\n22817190600")
  ; ("atprograms/sieve.oat", "", "25")
  ; ("atprograms/count_sort.oat", "", "AFHZAAEYC\nAAACEFHYZ0")
  ; ("atprograms/determinant_size2.oat", "", "94")
  ; ("atprograms/fibo.oat", "", "0")
  ; ("atprograms/bubble_sort.oat", "", "1")
  ; ("atprograms/heap.oat", "", "1")
  ; ("atprograms/binary_gcd.oat", "", "3")
  ; ("atprograms/lfsr.oat", "", "TFTF FFTT0")
  ; ("atprograms/gnomesort.oat", "", "01253065992000")
  ; ("atprograms/josh_joyce_test.oat", "", "0")
  ; ("atprograms/conquest.oat", "", "My name is Jeff...\nCharizard is the BEST Pokemon ever!!!11")
  ; ("atprograms/gcd.oat", "", "16")
  ; ("atprograms/lcs.oat", "", "OAT0")
  ; ("atprograms/insertion_sort.oat", "", "42")
  ; ("atprograms/maxsubsequence.oat", "", "107")
]

let hw4_type_error_tests = [
  "atprograms/run3.oat"
; "atprograms/run5.oat"
; "atprograms/run35.oat"
; "atprograms/run43.oat"
; "atprograms/run44.oat"
; "atprograms/run45.oat"
]    


let typecheck_equality_tests = [
    "hw5programs/tc_eq1.oat"
  ; "hw5programs/tc_eq2.oat"
  ]

let struct_tests = [
("hw5programs/compile_assign_struct.oat", "", "16");
("hw5programs/compile_basic_struct.oat", "", "7");
("hw5programs/compile_global_struct.oat", "", "254");
("hw5programs/compile_nested_struct.oat", "", "10");
("hw5programs/compile_return_struct.oat", "", "0");
("hw5programs/compile_struct_array.oat", "", "15");
("hw5programs/compile_struct_fptr.oat", "", "7");
("hw5programs/compile_various_fields.oat", "", "hello253"); 
]

let fptr_tests = [
  ("hw5programs/compile_array_fptr.oat", "", "2");
  ("hw5programs/compile_func_argument.oat", "", "4");
  ("hw5programs/compile_global_fptr.oat", "", "7");
  ("hw5programs/compile_global_fptr_unordered.oat", "", "2");
  ("hw5programs/compile_scall_fptr.oat", "", "4");
  ("hw5programs/compile_var_fptr.oat", "", "1");
  ("hw5programs/compile_local_fptr.oat", "", "5");
  ("hw5programs/compile_function_shadow.oat", "", "12");
  ("hw5programs/compile_global_struct_fptr.oat", "", "20");
  ("hw5programs/compile_builtin_argument.oat", "", "abab0");    
]

let typecheck_subtyping_tests =
  [ "hw5programs/tc_subtyping1.oat"
  ; "hw5programs/tc_subtyping2.oat"
  ; "hw5programs/tc_subtyping3.oat"
  ; "hw5programs/tc_subtyping4.oat"
  ; "hw5programs/tc_subtyping5.oat"
  ; "hw5programs/tc_subtyping6.oat"
  ; "hw5programs/tc_subtyping7.oat"
  ; "hw5programs/tc_subtyping8.oat"
  ; "hw5programs/tc_subtyping9.oat"            
  ]

let typecheck_subtyping_error_tests =
  [ "hw5programs/tc_subtyping_err1.oat"
  ; "hw5programs/tc_subtyping_err2.oat"
  ; "hw5programs/tc_subtyping_err3.oat"
  ; "hw5programs/tc_subtyping_err4.oat"
  ; "hw5programs/tc_subtyping_err5.oat"
  ; "hw5programs/tc_subtyping_err6.oat"        
  ; "hw5programs/tc_subtyping_err7.oat"
  ; "hw5programs/tc_subtyping_err8.oat"            
  ]
  

let typecheck_statement_error_tests =
  [ "hw5programs/tc_error_early_return.oat";
    "hw5programs/tc_error_early_return_void.oat";
    "hw5programs/tc_error_return_wrong.oat";
    "hw5programs/tc_error_while_nonbool.oat";
    "hw5programs/tc_error_while.oat";
    "hw5programs/tc_error_if_nonbool.oat";
    "hw5programs/tc_error_if.oat";
    "hw5programs/tc_error_for.oat";
    "hw5programs/tc_error_void.oat";
    "hw5programs/tc_error_assign_void.oat";
    "hw5programs/tc_error_scall_nonvoid.oat";
  ]

let typecheck_correct_statement_tests =
  [ "hw5programs/tc_correct_while.oat";
    "hw5programs/tc_correct_for.oat";
    "hw5programs/tc_correct_if.oat";
    "hw5programs/tc_correct_void.oat"
  ]

let typecheck_error_expression_tests =
  [ "hw5programs/tc_error_binop1.oat";
    "hw5programs/tc_error_binop2.oat";
    "hw5programs/tc_error_binop3.oat";
    "hw5programs/tc_error_call1.oat";
    "hw5programs/tc_error_call2.oat";
    "hw5programs/tc_error_unop1.oat";
    "hw5programs/tc_error_array1.oat";
    "hw5programs/tc_error_array2.oat";
    "hw5programs/tc_error_null.oat";
  ]

let typecheck_error_struct_tests = 
  [ "hw5programs/tc_error_struct_proj.oat";
    "hw5programs/tc_error_struct1.oat";
    "hw5programs/tc_error_struct2.oat";
    "hw5programs/tc_error_struct3.oat";
    "hw5programs/tc_error_struct4.oat";
    "hw5programs/tc_error_struct_dup.oat";
    "hw5programs/tc_error_struct.oat";
    "hw5programs/tc_error_dupstruct.oat";
    "hw5programs/tc_error_struct_unbound.oat";
  ]

let typecheck_error_global_tests =
  [ "hw5programs/tc_error_global_dup.oat";
    "hw5programs/tc_error_global.oat";
    "hw5programs/tc_error_func_redeclaration.oat";
    "hw5programs/tc_error_func_assign.oat";
    "hw5programs/tc_error_overwrite.oat";
    "hw5programs/tc_error_global_fptr_scope.oat";
    "hw5programs/tc_error_function_no_shadow.oat";
    "hw5programs/tc_correct_null.oat";
  ]

let typecheck_correct_other_tests =
  [ "hw5programs/tc_correct_array.oat";
    "hw5programs/tc_correct_call.oat";
    "hw5programs/tc_correct_fptr.oat";
    "hw5programs/tc_correct_global.oat";
    "hw5programs/tc_correct_struct.oat";
    "hw5programs/tc_correct_struct_fptr.oat";
    "hw5programs/tc_correct_void.oat";
    "hw5programs/tc_correct_local_redeclaration.oat";
    "hw5programs/tc_correct_fptr_array.oat";
  ]

let typecheck_error_null_not_null_tests =
  hw4_type_error_tests

  
let fptr_tests = [
  ("hw5programs/compile_array_fptr.oat", "", "2");
  ("hw5programs/compile_func_argument.oat", "", "4");
  ("hw5programs/compile_global_fptr.oat", "", "7");
  ("hw5programs/compile_global_fptr_unordered.oat", "", "2");
  ("hw5programs/compile_scall_fptr.oat", "", "4");
  ("hw5programs/compile_var_fptr.oat", "", "1");
  ("hw5programs/compile_local_fptr.oat", "", "5");
  ("hw5programs/compile_function_shadow.oat", "", "12");
  ("hw5programs/compile_global_struct_fptr.oat", "", "20");
  ("hw5programs/compile_builtin_argument.oat", "", "abab0");    
]


let new_tests = [
  ("hw5programs/ifq1.oat", "", "4");
  ("hw5programs/ifq2.oat", "", "5");
  ("hw5programs/ifq3.oat", "", "6");
  ("hw5programs/ifq4.oat", "", "4");
  ("hw5programs/ifq5.oat", "", "4");
  ("hw5programs/run44fixed.oat", "", "hello0");  
  ("hw5programs/length1.oat", "", "5");
]

let tc_ok_tests = [
  "hw5programs/tc_struct_ok.oat"
; "hw5programs/tc_func_ret_ok.oat"
; "hw5programs/tc_func_arg_ok.oat"
; "hw5programs/tc_ifq1.oat"
; "atprograms/tc_ok1.oat"
; "atprograms/tc_ok2.oat"
; "atprograms/tc_ok4.oat"
; "atprograms/tc_ok5.oat"
; "atprograms/tc_ok6.oat"
; "atprograms/tc_ok7.oat"
; "atprograms/tc_ok8.oat"
; "hw5programs/tc_arrow.oat"
; "hw5programs/tc_arrow_null.oat"
; "hw5programs/tc_arrow_null_rec.oat"
]

let tc_err_tests = [
  "hw5programs/tc_null_array_err.oat"
; "hw5programs/tc_struct_err.oat"
; "hw5programs/tc_func_ret_err.oat"
; "hw5programs/tc_func_arg_err.oat"
; "hw5programs/tc_array_err.oat"
; "hw5programs/tc_struct_field_err.oat"
; "hw5programs/tc_recursive_struct_err.oat"
; "hw5programs/tc_ifq_err1.oat"
]


let typecheck_tests : suite = [
  GradedTest("subtype unit tests", 1, unit_tests);
  GradedTest("tc subtyping tests", 4, typecheck_file_correct typecheck_subtyping_tests);
  GradedTest("tc subtyping error tests", 4, typecheck_file_error typecheck_subtyping_error_tests);  
  GradedTest("tc equality tests", 4, typecheck_file_correct typecheck_equality_tests);
  GradedTest("tc statement error tests", 5, typecheck_file_error typecheck_statement_error_tests);
  GradedTest("tc statement correct tests", 5, typecheck_file_correct typecheck_correct_statement_tests);
  GradedTest("tc other correct tests", 5, typecheck_file_correct typecheck_correct_other_tests);
  GradedTest("tc null/not null error tests", 5, typecheck_file_error typecheck_error_null_not_null_tests);
  GradedTest("tc expression error tests", 5, typecheck_file_error typecheck_error_expression_tests);
  GradedTest("tc struct/global error tests", 5, typecheck_file_error (typecheck_error_struct_tests @ typecheck_error_global_tests));
  GradedTest("extra tc err tests", 5, typecheck_file_error tc_err_tests)
]

let hw5_tests : suite = [
  GradedTest("tc ok tests", 10, executed_tc_ok_file tc_ok_tests)
; GradedTest("new tests", 10, executed_oat_file new_tests)
; GradedTest("struct tests", 10, executed_oat_file struct_tests)
; GradedTest("fptr tests", 2, executed_oat_file fptr_tests)
]


let manual_tests : suite = [
    GradedTest ("Posted Moodle Test Case", 5,
              [("manually", assert_eq true false)]
    )
  ; GradedTest ("Performance Comparison", 5,
              [("manually", assert_eq true false)]
    )
  ]

let hw4_tests =
      hw4_easiest_tests
    @ hw4_globals_tests
    @ hw4_path_tests
    @ hw4_easy_tests
    @ hw4_medium_tests
    @ hw4_hard_tests
    @ hw4_old_student_tests

let functionality_tests : suite = [GradedTest("functionality tests from HW04", 10, executed_oat_file hw4_tests)]

let graded_tests : suite =
  typecheck_tests @
  hw5_tests @
  functionality_tests @
  manual_tests
