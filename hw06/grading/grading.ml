(* SOLN *)
open Assert
open Arg

let grades_out = ref "grade.out"
let feedback_out = ref "feedback.txt"
let grading = ref false
let gen_tests = ref false

let get_sql_results (t:result test) =
  let num_passed cases = 
    List.fold_left (fun cnt (_,r) -> match r with Pass -> cnt + 1 | _ -> cnt) 0 cases in
    begin match t with
      | GradedTest (name,pts,cases) ->
	  let passed = num_passed cases in
	  let total = List.length cases in
            if total > 0 then
              let points_earned = ((float_of_int passed) /. (float_of_int total)) *. (float_of_int pts) in
		Some (name, points_earned)
            else
              failwith @@ Printf.sprintf "CIS341 Error: Graded test %s with no cases" name
      | Test(_name, _cases) -> None
    end

let outcome_to_sql (o:outcome):string = 
  let helper str (t:result test) =
    begin match (get_sql_results t) with
      | Some (probname, pts) -> str ^ "\n" ^ 
          (Printf.sprintf "%1.f|0.0|%s%!" pts probname)
      | None -> str
    end
  in List.fold_left helper "" o

let grade_tests suite ex () =
  let _ = grading := true in
  (* UNCOMMENT ONCE WE GET TO THE COMPILER *)
  (*
  let _ = Driver.opt_ast := true in
  let _ = Driver.opt_ll := true in
  let _ = Driver.opt_x86 := true in
  *)
  let o = run_suite suite in
  let feedback_out = open_out !feedback_out in
  let grades_out = open_out !grades_out in
  Printf.fprintf stdout "Grading...\n";   
  flush stdout;
  Printf.fprintf grades_out "%s\n" (outcome_to_sql o);
  close_out grades_out;
  Printf.fprintf feedback_out "%s\n" (outcome_to_string o);
  close_out feedback_out;
  raise ex

let grading_args suite ex = [
  ("-gen-tests", Set gen_tests, "turn on parse and compile test generation");
  ("-scores", Set_string grades_out, "set the output sql file - default = grade.sql");
  ("-feedback", Set_string feedback_out, "set the output txt file - default = grade.txt");
  ("--grade", Unit (grade_tests suite ex), "generate grade output from the test suite, ignoring other inputs\nmust be after sql config flags\ndo not use with --test");
]

(* STUBWITH *)
