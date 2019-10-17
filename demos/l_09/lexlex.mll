{
  (* Header: will be exported directly into the generated .ml file *)

  open Lexing
  open String

(* Define the datatype of tokens *)
type token =
  | Int    of int64
  | Ident  of string
  | LPAREN
  | RPAREN
  | LPARENSTAR
  | STAR
  | STARRPAREN
  | IF
  (* ... other cases here *)

let print_token t = 
  begin match t with
    | Int x   -> (Printf.printf "Int %Ld\n%!" x)
    | Ident s -> (Printf.printf "Ident  %s\n%!" s)
    | IF      -> (Printf.printf "IF\n%!")
    | LPAREN  -> (Printf.printf "LPAREN\n%!")
    | RPAREN  -> (Printf.printf "RPAREN\n%!")
    | LPARENSTAR -> (Printf.printf "LPARENSTAR\n%!")
    | STAR    -> (Printf.printf "STAR\n%!" )
    | STARRPAREN -> (Printf.printf "STARRPAREN\n%!")
  end

  exception Lex_error of char

  let acc = ref [] 
  let emit t = acc := t::(!acc) 
    
}

let character = ['a'-'z''A'-'Z']
let digit = ['0'-'9']
let underscore = ['_']
let whitespace = [' ' '\t' '\n' '\r']
let identifier =  character (character|digit|underscore)*

rule lex = parse
  | "if"   
      { emit IF; lex lexbuf }

  | identifier
      { 
	emit (Ident (lexeme lexbuf));
	lex lexbuf 
      }

  | '('
      { 
	emit LPAREN;
	lex lexbuf 
      }

  | ')'
      { 
	emit RPAREN;
	lex lexbuf 
      }

  | '*'
      { 
	emit STAR;
	lex lexbuf 
      }

  | "(*"
      { 
	emit LPARENSTAR;
	lex lexbuf 
      }

  | "*)"
      { 
	emit STARRPAREN;
	lex lexbuf 
      }

  | whitespace+
      { lex lexbuf }

  | digit+
      { 
	emit (Int (Int64.of_string (lexeme lexbuf)));
	lex lexbuf 
      }

  | _ as c 
      { raise (Lex_error c) }

  | eof
      { List.rev (!acc) }

{
  (* Footer: will be exported directly into the generated .ml file, after
     the lexing code *)

  let _ =
  try
    List.iter print_token (lex (from_channel stdin))
  with
    | Lex_error c -> Printf.printf "Char %s is unexpected.\n" (Char.escaped c)
}
