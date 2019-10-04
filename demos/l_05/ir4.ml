
module IR = struct
  
  type uid = string     (* Unique identifiers for temporaries. *)
  type var = string
  type lbl = string
  type fn_name = string
  
  (* "gensym" -- generate a new unique identifier *)
  let mk_uid : unit -> uid =
    let ctr = ref 0 in
    fun () -> let uid = !ctr in
      ctr := !ctr + 1;
      Printf.sprintf "tmp%d" !ctr
  
  
  (* operands *)
  type opn = 
    | Id of uid
    | Const of int64

  (* binary arithmetic operations *)
  type bop =
    | Add
    | Mul

  (* comparison operations *)
  type cmpop =
    | Eq
    | Lt
  
  (* instructions *)
  (* note that there is no nesting of operations! *)
  type insn =
    | Let of uid * bop * opn * opn
    | Load of uid * var
    | Store of var * opn
    | ICmp of uid * cmpop * opn * opn
    | Call of uid * fn_name * (opn list)
    | Alloca of uid
  
  type terminator =
    | Ret 
    | Br of lbl                (* unconditional branch *)
    | Cbr of opn * lbl * lbl   (* conditional branch *)

  (* Basic blocks *)
  type block = { insns: insn list; terminator: terminator }

  (* Control Flow Graph: a pair of an entry block and a set labeled blocks *)
  type cfg = block * (lbl * block) list

  (* A function declaration:  (In OCaml syntax: )
          let f arg1 arg2 arg3 = 
          let rec entry () = ...
          and block1 () = ...
          ...
          and blockM () = ...
          in entry ()
  *)
  type fdecl = { name: fn_name;  param : uid list; cfg : cfg }
  
  type program = {
    fdecls : fdecl list
  }

  module MLMeaning = struct
    let add = Int64.add
    let mul = Int64.mul
    let load (x : int64 ref) = (!x)
    let store o (x : int64 ref) = x := o
    let icmp cmpop x y = cmpop x y 

    let eq (x : int64) (y : int64) = x = y
    let lt x y = x < y

    let ret x = x

    let cbr cnd lbl1 lbl2 =
      if cnd then lbl1 () else lbl2 ()
    let br lbl = lbl ()

    let alloca () = ref 0L
    let call f x = f x
  end
  
end



