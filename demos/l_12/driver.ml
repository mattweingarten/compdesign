open Printf

let print_banner s =
  let rec dashes n = if n = 0 then "" else "-"^(dashes (n-1)) in
  printf "%s %s\n%!" (dashes (79 - (String.length s))) s

let read_file (file:string) : string =
  let lines = ref [] in
  let channel = open_in file in
  try while true; do
      lines := input_line channel :: !lines
  done; ""
  with End_of_file ->
    close_in channel;
    String.concat "\n" (List.rev !lines)

let parse_imp_file filename =
  let lexbuf = read_file filename |> 
               Lexing.from_string
  in
  try
    Parser.toplevel Lexer.token lexbuf
  with
  | Parser.Error -> failwith @@ Printf.sprintf "Parse error at: %s"
      (Range.string_of_range (Range.lex_range lexbuf))
    

let print_imp file ll_ast =
    print_banner (file ^ ".imp");
    Astlib.print_prog ll_ast

let string_of_file (f:in_channel) : string =
  let rec _string_of_file (stream:string list) (f:in_channel) : string list=
    try 
      let s = input_line f in
      _string_of_file (s::stream) f
    with
      | End_of_file -> stream
  in 
    String.concat "\n" (List.rev (_string_of_file [] f))

