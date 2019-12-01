(* LLVMlite: A simplified subset of the LLVM IR *)

type uid = string                       (* Local identifiers  *)
type gid = string                       (* Global identifiers *)
type tid = string                       (* Named types        *)
type lbl = string                       (* Labels             *)

(* LLVM IR types *)
type ty =
  | Void                            (* mix of unit/bottom from C *)
  | I1 | I8 | I64                   (* integer types             *)
  | Ptr of ty                       (* t*                        *)
  | Struct of ty list               (* { t1, t2, ... , tn }      *)
  | Array of int * ty               (* [ NNN x t ]               *)
  | Fun of fty                      (* t1, ..., tn -> tr         *)
  | Namedt of tid                   (* named type aliases        *)

(* Function type: argument types and return type *)
and fty = ty list * ty 

(* Syntactic Values *)
type operand = 
  | Null            (* null pointer        *)
  | Const of int64  (* integer constant    *)
  | Gid   of gid    (* A global identifier *)
  | Id    of uid    (* A local identifier  *)

(* Type-annotated operands *)

(* Binary operations *)
type bop = Add | Sub | Mul | Shl | Lshr | Ashr | And | Or | Xor

(* Comparison Operators *)
type cnd = Eq | Ne | Slt | Sle | Sgt | Sge

(* Instructions *)
type insn =
  | Binop of bop * ty * operand * operand      (* bop ty %o1, %o2                    *)
  | Alloca of ty                               (* alloca ty                          *)
  | Load of ty * operand                       (* load ty %u                         *)
  | Store of ty * operand * operand            (* store ty %t, ty* %u                *)
  | Icmp of cnd * ty * operand * operand       (* icmp %s ty %s, %s                  *)
  | Call of ty * operand * (ty * operand) list (* fn(%1, %2, ...)                    *)
  | Bitcast of ty * operand * ty               (* bitcast ty1 %u to ty2              *)
  | Gep of ty * operand * operand list         (* getelementptr ty* %u, i64 %vi, ... *)

(* Block terminators *)
type terminator =
  | Ret of ty * operand option   (* ret i64 %s                     *)
  | Br of lbl                    (* br label %lbl                  *)
  | Cbr of operand * lbl * lbl   (* br i1 %s, label %l1, label %l2 *)

(* Basic blocks *)
type block = { insns: (uid * insn) list; terminator: uid * terminator }

(* Control Flow Graph: a pair of an entry block and a set labeled blocks *)
type cfg = block * (lbl * block) list

(* Function declarations *)
type fdecl = { fty: fty; param: uid list; cfg: cfg }

(* Initializers for global data *)
type ginit = 
  | GNull                     (* null literal             *)
  | GGid of gid               (* reference another global *)
  | GInt of int64             (* global integer value     *)
  | GString of string         (* constant global string   *)
  | GArray of gdecl list      (* global array             *)
  | GStruct of gdecl list     (* global struct            *)

(* Global declaration *)
and gdecl = ty * ginit
      
(* LLVMlite programs *)
type prog = 
  { tdecls: (tid * ty) list      (* named types *)
  ; gdecls: (gid * gdecl) list   (* global data *)
  ; fdecls: (gid * fdecl) list   (* code        *)
  ; edecls: (gid * ty) list      (* external declarations *)
  }

