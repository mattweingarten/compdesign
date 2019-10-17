(* piglatin.mll
 * 
 * Example of using a lexer generator to create a program.
 * 
 * To compile this program to an executable do:
 * 
 *  ocamlbuild piglatin.native
 *)

{  
  open Lexing
  open String
}

let vowel = ['a''e''i''o''u''A''E''I''O''U']
let letter = ['a'-'z''A'-'Z']
let consonant = letter#vowel
let punctuation = ['.'',''!''\'''?''\t'' '';'':''"']

rule lex = parse
  | (consonant* as pre)(vowel as v)(letter* as post)  
      { 
        let word = lexeme lexbuf in
        let capital = (capitalize_ascii word) = word in
        let plword = lowercase_ascii ((make 1 v) ^ post ^
          if (length pre > 0) then (pre ^ "ay") else "yay")
        in
        (Printf.printf "%s" 
            (if capital then capitalize_ascii plword else plword));
        lex lexbuf
      }
  | '\n'            
      { print_newline () }
  | punctuation+ 
      { (Printf.printf "%s" (lexeme lexbuf)); lex lexbuf }

{
let rec main () = 
  try 
  let s = read_line () in
    lex (Lexing.from_string (s ^ "\n")) ;
    main ()
  with
      End_of_file -> exit 1
in
  main ()
}

