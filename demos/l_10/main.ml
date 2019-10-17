open Ast

module P = Parser

(* invoke the parser top level function using the generated
 * token function available in the lexer to create the 
 * token stream. 
 *)
let parse (filename:string) (buf : Lexing.lexbuf) : bexp =
  try
    Lexer.reset_lexbuf filename buf;
    P.toplevel Lexer.token buf
  with P.Error ->
    failwith (Printf.sprintf "Parse error at %s."
		(Range.string_of_range (Lexer.lex_range buf)))

let rec loop () : unit =
  let st = read_line () in 
    try
      let ast = parse "stdin" (Lexing.from_string st) in
      Printf.printf "Parsed (minimally parenthesized):\n  %s\n" (Ast.string_of_bexp ast);
      Ast.full_parens := true;
      Printf.printf "Parsed (fully parenthesized):\n  %s\n" (Ast.string_of_bexp ast);
      Ast.full_parens := false;
      loop ()
    with
      | Lexer.Lexer_error (r,m) ->
	  failwith (Printf.sprintf "Lexing error at %s: %s."
		      (Range.string_of_range r) m)
;;
loop ()


