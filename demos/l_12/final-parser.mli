(* The type of tokens. *)
type token = 
  | WHILE
  | TINT
  | STRING of (string)
  | STAR
  | SEMI
  | RPAREN
  | RETURN
  | RBRACE
  | PLUS
  | LPAREN
  | LBRACE
  | INT of (int64)
  | IF
  | IDENT of (string)
  | EQ
  | EOF
  | ELSE
  | DASH

(* This exception is raised by the monolithic API functions. *)
exception Error

(* The monolithic API. *)
val toplevel: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.prog)

