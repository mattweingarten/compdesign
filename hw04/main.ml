open Ll
open Arg
open Assert
open Driver

(* testing harness ---------------------------------------------------------- *)
exception Ran_tests
let suite = ref (Studenttests.provided_tests @ Gradedtests.graded_tests)

let execute_tests () =
  let outcome = run_suite !suite in
  Printf.printf "%s\n" (outcome_to_string outcome);
  raise Ran_tests


(* command-line arguments --------------------------------------------------- *)
let args =
  [ ("--test", Unit execute_tests, "run the test suite, ignoring other file inputs")
  ; ("-op", Set_string Platform.output_path, "set the path to the output files directory  [default='output']")
  ; ("-o", Set_string executable_filename, "set the name of the resulting executable [default='a.out']")    
  ; ("-S", Clear assemble, "stop after generating .s files; do generate .o files")
  ; ("-c", Clear link, "stop after generating .o files; do not generate executables")
  ; ("--interpret-ll", Set interpret_ll, "runs each LL program through the LL interpreter")
  ; ("--print-ll", Set print_ll_flag, "prints the program LL code")
  ; ("--print-x86", Set print_x86_flag, "prints the program's assembly code")
  ; ("--clang", Set clang, "compiles to assembly using clang, not the 341 backend")
  ; ("--execute-x86", Set execute_x86, "run the resulting executable file")
  ; ("--print-ast", Set print_ast_flag , "print the program's AST as ML code")
  ; ("--print-oat", Set print_oat_flag , "print the program's OAT code")
  ; ("-v", Unit Platform.enable_verbose, "enables more verbose compilation output")
  ] 


(* Files found on the command line *)
let files = ref []

let main () =
  Platform.configure_os ();
  Platform.create_output_dir ();
  try
    Arg.parse args (fun filename -> files := filename :: !files)
      "main test harness\n\
       USAGE: ./main.native [options] <files>\n\
       see README for details about using the compiler";
    
    process_files !files

  with Ran_tests -> 
    ()

;; main ()
