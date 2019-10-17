(* olex.mll
 * 
 * Example of using a lexer generator to create a program.
 * 
 * To compile this program to an executable do:
 *   ocamlbuild olex.byte 
 *  or 
 *   ocamlbuild olex.native
 *
 * Ocamllex Tutorial:
 *   http://plus.kaist.ac.kr/~shoh/ocaml/ocamllex-ocamlyacc/ocamllex-tutorial/
 * Lexing:
 *   http://caml.inria.fr/pub/docs/manual-ocaml/libref/Lexing.html
 *)

(* header section *)
{  
  open Lexing
  open String

  let incr_linenum lexbuf =
    let pos = lexbuf.Lexing.lex_curr_p in
    lexbuf.Lexing.lex_curr_p <- { pos with
      Lexing.pos_lnum = pos.Lexing.pos_lnum + 1;
      Lexing.pos_bol = pos.Lexing.pos_cnum;
    }
    
  let unexpected_char c lexbuf =
    Printf.printf "Char %s is unexpected at (line:%d, column:%d).\n" 
                  (Char.escaped c) 
                  (lexeme_start_p lexbuf).pos_lnum
                  ((lexeme_start_p lexbuf).pos_cnum - (lexeme_start_p lexbuf).pos_bol + 1)
        
}

(* definitions section *)
let character = ['a'-'z''A'-'Z']
let digit = ['0'-'9']
let underscore = ['_']
let whitespace = [' ' '\t']
let regname = "rax" | "rbx" | "rcx" | "rdx" | "rbp" | "rsp" | "rpi" | "rdi"
            | "r8" | "r9" | "r10" | "r11" | "r12" | "r13" | "r14" | "r15"
            | "rip"

(* rules section *)
rule lex = parse
  | "if" 
      { Printf.printf "IF: %s\n" (lexeme lexbuf);
        lex lexbuf
      }
  | character (character|digit|underscore)*
      { Printf.printf "Ident: %s\n" (lexeme lexbuf);
        lex lexbuf
      }
  | digit+            
      { Printf.printf "Int: %s\n" (lexeme lexbuf);
        lex lexbuf
      }
  | '(' 
      { Printf.printf "LPAREN: %s\n" (lexeme lexbuf); 
        lex lexbuf 
      }
  | ')' 
      { Printf.printf "RPAREN: %s\n" (lexeme lexbuf); 
        lex lexbuf 
      }
  | whitespace+ 
      { lex lexbuf }
  | '"'[^'"']*'"'
      { Printf.printf "String: %s\n" (lexeme lexbuf); 
        lex lexbuf
      }
  | '\n' 
      { incr_linenum lexbuf; lex lexbuf }
  | (('-')?(digit+)) as disp 
    '(' '%' (regname as reg) ')' 
      {
        Printf.printf "IND: %s(%%%s)\n" 
                      disp
                      reg;
        lex lexbuf
      }
  | _ as c 
      { unexpected_char c lexbuf }
  | eof 
      { Printf.printf "Done.\n" }

(* trailer section *)
{
let _ = lex (Lexing.from_channel stdin)
}


