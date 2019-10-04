(* refactoring -------------------------------------------------------------- *)


module IR = struct

  (* unify var and fn_name as 'global identifiers' *)
  type uid = string     (* Unique identifiers for temporaries. *)
  type lbl = string
  type gid = string
  
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
  (* pull out the common 'uid' element from these constructors *)
  type insn =
    | Binop of bop * opn * opn     (* Rename let to binop *)
    | Load of gid
    | Store of gid * opn
    | ICmp of cmpop * opn * opn
    | Call of gid * (opn list)
    | Alloca 
  
  type terminator =
    | Ret 
    | Br of lbl                (* unconditional branch *)
    | Cbr of opn * lbl * lbl   (* conditional branch *)

  (* Basic blocks *)
  type block = { insns: (uid * insn) list; terminator: terminator }

  (* Control Flow Graph: a pair of an entry block and a set labeled blocks *)
  type cfg = block * (lbl * block) list


  type gdecl =
    | GInt of int64
  
  (* A function declaration:  (In OCaml syntax: )
          let f arg1 arg2 arg3 = 
          let rec entry () = ...
          and block1 () = ...
          ...
          and blockM () = ...
          in entry ()
  *)
  type fdecl = { param : uid list; cfg : cfg }
  
  type program = {
    gdecls : (gid * gdecl) list;
    fdecls : (gid * fdecl) list;
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



