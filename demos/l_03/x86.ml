(* assembler syntax --------------------------------------------------------- *)

type lbl = string

type quad = int64

type imm = Lit of quad
         | Lbl of lbl

(* arguments: rdi, rsi, rdx, rcx, r08, r09
   callee-save rbx, rbp, r12-r15 *)
type reg = Rip
         | Rax | Rbx | Rcx | Rdx | Rsi | Rdi | Rbp | Rsp
         | R08 | R09 | R10 | R11 | R12 | R13 | R14 | R15

type operand = Imm of imm            (* immediate *)
             | Reg of reg            (* register *)
             | Ind1 of imm           (* indirect: displacement *)
             | Ind2 of reg           (* indirect: (%reg) *)
             | Ind3 of (imm * reg)   (* indirect: displacement(%reg) *)

type opcode = Movq | Pushq | Popq
            | Leaq
            | Incq | Decq | Negq | Notq
            | Addq | Subq | Imulq | Xorq | Orq | Andq
            | Shlq | Sarq | Shrq
            | Cmpq
            | Jmp | Je | Jne | Jg | Jge | Jl | Jle
            | Callq | Retq

type ins = opcode * operand list              
              

type 'a labled = { lbl: lbl; global: bool; value: 'a }

type data = Asciz of string
          | Quad of imm

type asm = { text_asm : ins list labled list
           ; data_asm : data labled list
           }


(* pretty printing ----------------------------------------------------------- *)

let string_of_reg : reg -> string = function
  | Rip -> "%rip"
  | Rax -> "%rax" | Rbx -> "%rbx" | Rcx -> "%rcx" | Rdx -> "%rdx"
  | Rsi -> "%rsi" | Rdi -> "%rdi" | Rbp -> "%rbp" | Rsp -> "%rsp"
  | R08 -> "%r8"  | R09 -> "%r9"  | R10 -> "%r10" | R11 -> "%r11"
  | R12 -> "%r12" | R13 -> "%r13" | R14 -> "%r14" | R15 -> "%r15"

let string_of_lbl (l:lbl) : string = l

let string_of_imm : imm -> string = function
  | Lit i -> Int64.to_string i
  | Lbl l -> string_of_lbl l

let string_of_operand : operand -> string = function
  | Imm i -> "$" ^ string_of_imm i
  | Reg r -> string_of_reg r
  | Ind1 i -> string_of_imm i
  | Ind2 r -> "(" ^ string_of_reg r ^ ")"
  | Ind3 (i, r) -> string_of_imm i ^ "(" ^ string_of_reg r ^ ")"

let string_of_jmp_operand : operand -> string = function
  | Imm i -> string_of_imm i
  | Reg r -> string_of_reg r
  | Ind1 i -> "*" ^ string_of_imm i
  | Ind2 r -> "*" ^ "(" ^ string_of_reg r ^ ")"
  | Ind3 (i, r) -> "*" ^ string_of_imm i ^ "(" ^ string_of_reg r ^ ")"

let string_of_opcode : opcode -> string = function
  | Movq -> "movq" | Pushq -> "pushq" | Popq -> "popq"
  | Leaq -> "leaq"
  | Incq -> "incq" | Decq -> "decq" | Negq -> "negq" | Notq -> "notq"
  | Addq -> "addq" | Subq -> "subq" | Imulq -> "imulq"
  | Xorq -> "xorq" | Orq -> "orq"  | Andq -> "andq"
  | Shlq -> "shlq" | Sarq -> "sarq" | Shrq -> "shrq"
  | Cmpq -> "cmpq"
  | Jmp -> "jmp" | Je -> "je" | Jne -> "jne" | Jg -> "jg" 
  | Jge -> "jge" | Jl -> "jl" | Jle -> "jle"
  | Callq -> "callq" | Retq -> "retq"

let string_of_ins (op, args: ins) : string =
  "\t" ^ string_of_opcode op ^ "\t" ^ String.concat ", " @@ 
  match op with
  | Jmp | Je | Jne | Jg | Jge | Jl | Jle | Callq -> List.map string_of_jmp_operand args
  | _                                            -> List.map string_of_operand args

let string_of_labled (f:'a -> string) (l:'a labled) : string =
  (if l.global then "\t.globl\t" ^ string_of_lbl l.lbl ^ "\n" else "")
  ^ string_of_lbl l.lbl ^ ":\n"
  ^ f l.value

let string_of_data : data -> string = function
  | Asciz s -> "\t.asciz\t" ^ "\"" ^ s ^ "\""
  | Quad i -> "\t.quad\t" ^ string_of_imm i

let string_of_asm (a:asm) : string =
  let map_concat_n f a = String.concat "\n" @@ List.map f a in
  "\t.text\n"
  ^ map_concat_n (string_of_labled @@ map_concat_n string_of_ins) a.text_asm
  ^ "\n\t.data\n"
  ^ map_concat_n (string_of_labled string_of_data) a.data_asm


(* examples ------------------------------------------------------------------ *)

module Asm = struct
    let (~$) i = Imm (Lit (Int64.of_int i))
    let (~$$) l = Imm (Lbl l)
    let (~%) r = Reg r

    let gquad l q = { lbl = l; global = true; value = Quad q }
    let block l is = { lbl = l; global = false; value = is }
    let gblock l is = { lbl = l; global = true; value = is }
end

let p0 = Asm.{ text_asm =
                 [ block "foo"
                         [ Xorq, [~%Rax; ~%Rax]
                         ; Movq, [~$100; ~%Rax]
                         ; Retq, []
                         ]
                 ; block "main" 
                         [ Xorq, [~%Rax; ~%Rax]
                         ; Movq, [Ind1 (Lbl "baz"); ~%Rax]
                         ; Retq, []
                         ]
                 ]
             ; data_asm = 
                 [ { lbl = "baz"; global = true; value = Quad (Lit 99L) }
                 ; { lbl = "quux"; global = true; value = Asciz "Hello, world!" }
                 ]
             }

let p1 n = Asm.{ text_asm =
                   [ gblock "_main"
                           [ Movq,  [~$1; ~%Rax]
                           ; Movq,  [~$n; ~%Rdi]
                           ]
                   ; block "loop"
                           [ Cmpq,  [~$0; ~%Rdi]
                           ; Je,    [~$$"exit"]
                           ; Imulq, [~%Rdi; ~%Rax]
                           ; Decq,  [~%Rdi]
                           ; Jmp,   [~$$"loop"]
                           ]
                   ; block "exit"
                           [ Retq,  [] 
                           ]
                   ]
               ; data_asm = []
               }

let p2 n = Asm.{ text_asm =
                   [ block "fac"
                           [ Movq,  [~%Rsi; ~%Rax]
                           ; Cmpq,  [~$1; ~%Rdi]
                           ; Je,    [~$$"exit"]
                           ; Imulq, [~%Rdi; ~%Rsi]
                           ; Decq,  [~%Rdi]
                           ; Callq, [~$$"fac"]
                           ]
                   ; block "exit"
                           [ Retq,  [] ]
                   ; gblock "_program"
                           [ Movq,  [~$n; ~%Rdi]
                           ; Movq,  [~$1; ~%Rsi]
                           ; Callq, [~$$"fac"]
                           ; Retq,  []
                           ]
                   ]
               ; data_asm = []
               }
