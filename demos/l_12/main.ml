open Arg

let process_imp_ast path file imp_ast =
  Driver.print_imp file imp_ast

let process_imp_file path file =
  let _ = Printf.sprintf "* processing file: %s\n" path in
  let imp_ast = Driver.parse_imp_file path in
  process_imp_ast path file imp_ast

let process_file path =
  let basename, ext = Platform.path_to_basename_ext path in
  begin match ext with
    | "imp" -> process_imp_file path basename
    | _ -> failwith @@ Printf.sprintf "found unsupported file type: %s" path
  end

let process_files files =
  List.iter process_file files

let args = [  ] 

let files = ref []

let _ =
    Arg.parse args (fun filename -> files := filename :: !files)
      "CIS 341 main test harness\n\
       USAGE: ./main.native [options] <files>\n\
       see README for details about using the compiler";
    process_files !files
