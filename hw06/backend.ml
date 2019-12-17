(* ll ir compilation -------------------------------------------------------- *)
open Ll
open Llutil
open X86
open Datastructures
open Cfg

(* allocated llvmlite function bodies --------------------------------------- *)

module Alloc = struct




(* X86 locations *)
type loc =
  | LVoid               (* no storage *)
  | LReg of X86.reg     (* x86 register *)
  | LStk of int         (* a stack slot offset from %rbp (not a byte offset!)*)
  | LLbl of X86.lbl     (* an assembler label *)

type operand =
  | Null
  | Const of int64
  | Gid of X86.lbl
  | Loc of loc

type insn =
  | ILbl of loc
  | PMov of (loc * ty * operand) list
  | Binop of loc * bop * ty * operand * operand
  | Alloca of loc * ty
  | Load of loc * ty * operand
  | Store of ty * operand * operand
  | Icmp of loc * Ll.cnd * ty * operand * operand
  | Call of loc * ty * operand * (ty * operand) list
  | Bitcast of loc * ty * operand * ty
  | Gep of loc * ty * operand * operand list
  | Ret of ty * operand option
  | Br of loc
  | Cbr of operand * loc * loc

let str_loc = function
  | LVoid  -> "LVoid"
  | LReg r  -> X86.string_of_reg r
  | LStk n -> Printf.sprintf "LStk %d" n
  | LLbl l -> l

let str_operand = function
  | Null -> "null"
  | Const x -> "Const _"
  | Gid l -> l
  | Loc l -> str_loc l


module LocSet = Set.Make (struct type t = loc let compare = compare end)
module UidSet = Datastructures.UidS

type fbody = (insn * LocSet.t) list

let map_operand f g : Ll.operand -> operand = function
  | Null -> Null
  | Const i -> Const i
  | Gid x -> Gid (g x)
  | Id u -> Loc (f u)

let map_insn f g : uid * Ll.insn -> insn =
  let mo = map_operand f g in function
  | x, Binop (b,t,o,o') -> Binop (f x, b,t,mo o,mo o')
  | x, Alloca t         -> Alloca (f x, t)
  | x, Load (t,o)       -> Load (f x, t, mo o)
  | _, Store (t,o,o')   -> Store (t, mo o, mo o')
  | x, Icmp (c,t,o,o')  -> Icmp (f x, c, t, mo o, mo o')
  | x, Call (t,o,args)  -> Call (f x, t, mo o, List.map (fun (t,o) -> t, mo o) args)
  | x, Bitcast (t,o,t') -> Bitcast (f x, t, mo o, t')
  | x, Gep (t,o,is)     -> Gep (f x, t, mo o, List.map mo is)

let map_terminator f g : uid * Ll.terminator -> insn =
  let mo = map_operand f g in function
  | _, Ret (t,None)   -> Ret (t, None)
  | _, Ret (t,Some o) -> Ret (t, Some (mo o))
  | _, Br l           -> Br (f l)
  | _, Cbr (o,l,l')   -> Cbr (mo o,f l,f l')

let map_lset f (s:UidSet.t) : LocSet.t =
  UidSet.fold (fun x t -> LocSet.add (f x) t) s LocSet.empty

let of_block (f:Ll.uid -> loc) (g:Ll.gid -> X86.lbl) (live:uid -> UidSet.t) (b:Ll.block) : fbody =
  List.map (fun (u,i) ->
      (* Uncomment this to enable verbose debugging output... *)
      (* Platform.verb @@ Printf.sprintf "  * of_block: %s live = %s\n" u (UidSet.to_string (live u)); *)
      map_insn f g (u,i), map_lset f @@ live u) b.insns
  @ let x,t = b.term in
    [map_terminator f g (x,t), map_lset f @@ live x]

let of_lbl_block f g live (l,b:Ll.lbl * Ll.block) : fbody =
  (ILbl (f l), map_lset f @@ live l)::of_block f g live b

let of_cfg (f:Ll.uid -> loc) (g:Ll.gid -> X86.lbl) (live:uid -> UidSet.t) (e,bs:Ll.cfg) : fbody =
  List.(flatten @@ of_block f g live e :: map (of_lbl_block f g live) bs)

end

module LocSet = Alloc.LocSet
module UidSet = Alloc.UidSet

let str_locset (lo:LocSet.t) : string =
  String.concat " " (List.map Alloc.str_loc (LocSet.elements lo))


(* streams of x86 instructions ---------------------------------------------- *)

type x86elt =
  | I of X86.ins
  | L of (X86.lbl * bool)

type x86stream = x86elt list

let lift : X86.ins list -> x86stream =
  List.rev_map (fun i -> I i)

let ( >@ ) x y = y @ x
let ( >:: ) x y = y :: x

let prog_of_x86stream : x86stream -> X86.prog =
  let rec loop p iis = function
    | [] -> (match iis with [] -> p | _ -> failwith "stream has no initial label")
    | (I i)::s' -> loop p (i::iis) s'
    | (L (l,global))::s' -> loop ({ lbl=l; global; asm=Text iis }::p) [] s'
  in loop [] []


(* locals and layout -------------------------------------------------------- *)

(* The layout for this version of the backend is slightly more complex
   than we saw earlier.  It consists of
     - uid_loc a function that maps LL uids to their target x86 locations
     - the number of bytes to be allocated on the stack due to spills
*)

type layout =
  { uid_loc : uid -> Alloc.loc
  ; spill_bytes : int
  }

(* The liveness analysis will return the set of variables that are live at
   a given program point, as specified by the uid. *)
type liveness = uid -> UidSet.t

(* The set of all caller-save registers available for register allocation *)
let caller_save : LocSet.t =
  [ Rdi; Rsi; Rdx; Rcx; R09; R08; Rax; R10; R11 ]
  |> List.map (fun r -> Alloc.LReg r) |> LocSet.of_list

(* excludes Rbp, Rsp, and Rip, since they have special meanings
   The current backend does not use callee-save registers except in
   the special case of through registers.  It uses R15 as a function
   pointer, but ensures that it is saved/restored.
*)
let callee_save : LocSet.t =
  [ Rbx; R12; R13; R14; R15 ]
  |> List.map (fun r -> Alloc.LReg r) |> LocSet.of_list

let arg_reg : int -> X86.reg option = function
  | 0 -> Some Rdi
  | 1 -> Some Rsi
  | 2 -> Some Rdx
  | 3 -> Some Rcx
  | 4 -> Some R08
  | 5 -> Some R09
  | n -> None

let arg_loc (n:int) : Alloc.loc =
  match arg_reg n with
  | Some r -> Alloc.LReg r
  | None -> Alloc.LStk (n-4)

let alloc_fdecl (layout:layout) (liveness:liveness) (f:Ll.fdecl) : Alloc.fbody =
  let dst  = List.map layout.uid_loc f.f_param in
  let tdst = List.combine (fst f.f_ty) dst in
  let movs = List.mapi (fun i (t,x) -> x, t, Alloc.Loc (arg_loc i)) tdst in
    (Alloc.PMov movs, LocSet.of_list dst)
  :: Alloc.of_cfg layout.uid_loc Platform.mangle liveness f.f_cfg

(* compiling operands  ------------------------------------------------------ *)

let compile_operand : Alloc.operand -> X86.operand =
  let open Alloc in function
  | Null -> Asm.(~$0)
  | Const i -> Asm.(Imm (Lit i))
  | Gid l -> Asm.(~$$l)
  | Loc LVoid -> failwith "compiling uid without location"
  | Loc (LStk i) -> Asm.(Ind3 (Lit (Int64.of_int @@ i * 8), Rbp))
  | Loc (LReg r) -> Asm.(~%r)
  | Loc (LLbl l) -> Asm.(Ind1 (Lbl l))

let emit_mov (src:X86.operand) (dst:X86.operand) : x86stream =
  let open X86 in match src, dst with
  | Imm (Lbl l), Reg _ -> lift Asm.[ Leaq, [Ind3 (Lbl l, Rip); dst ] ]
  | Imm (Lbl l), _     -> lift Asm.[ Leaq, [Ind3 (Lbl l, Rip); ~%Rax ]
                                   ; Movq, [~%Rax; dst ] ]
  | Reg r, Reg r' when r = r' -> []
  | Reg _, _ -> lift Asm.[ Movq, [src; dst] ]
  | _, Reg _ -> lift Asm.[ Movq, [src; dst] ]
  | _, _     -> lift Asm.[ Pushq, [src]; Popq,  [dst] ]


(* compiling parallel moves ------------------------------------------------- *)

(* Compiles a parallel move instruction into a sequence of moves, pushing and
   popping values to the stack when there are not enough registers to directly
   shuffle the sources to the targets. It uses liveness information to simply
   not move dead operands.

   The PMov instruction is used at the beginning of a function declaration to
   move the incoming arguments to their destination uids/registers.
   compile_pmov is directly used when compiling a function call to move
   the arguments.

   Inputs:
      live - the liveness information
      ol   - a list of triples of the form (dest, type, src)

   Note: the destinations are assumed to be distinct, but might also be sources

   Outputs:
      an x86 instruction stream that (efficiently) moves each src to its
      destination

   The algorithm works like this:
      1. Filter out the triples in which srcs are dead or already in the right
          place. (none of those need to be moved)

   Then do a recursive algorithm that processes the remaining list of triples:
      2. See if there are triples of the form (dest, type, src) where dest
         is not also source in some other triple.  For each such triple we can
         directly move the src to its dest (which won't "clobber" some other
         source).  These are the "ready" moves.

      3. If there are no "ready" moves to make (i.e. every destination is also
         a source of some other triple), we pick the first triple, push its
         src to the stack, recursively process the remaining list, and then
         pop the stack into the destination.

        ol          ol'          2           2             3           2
      x <- y      x <- y       w <- x     MOV x, w      MOV x, w     MOV x, w
      y <- y  ==>         ==>  ------ ==> -------- ==>  PUSH y   ==> PUSH y
      w <- x      w <- x       x <- y     x <- y        y <- z       MOV z, y
      y <- z      y <- z       y <- z     y <- z        POP x        POP x

*)

let compile_pmov live (ol:(Alloc.loc * Ll.ty * Alloc.operand) list) : x86stream =
  let open Alloc in
  let module OpSet = Set.Make (struct type t = operand let compare = compare end) in

  (* Filter the moves to keep the needed ones:
     The operands that actually need to be moved are those that are
         - not in the right location already, and
         - still live                                                         *)
  let ol' = List.filter (fun (x, _, o) -> Loc x <> o && LocSet.mem x live) ol in

  let rec loop outstream ol =
    (* Find the _set_ of all sources that still need to be moved. *)
    let srcs = List.fold_left (fun s (_, _, o) -> OpSet.add o s) OpSet.empty ol in
    match List.partition (fun (x, _, o) -> OpSet.mem (Loc x) srcs) ol with
    | [], [] -> outstream

    (* when no moves are ready to be emitted, push onto stack *)
    | (x,_,o)::ol', [] ->
       let os = loop (outstream >:: I Asm.( Pushq, [compile_operand o]))
                     ol' in
       os >:: I Asm.( Popq, [compile_operand (Loc x)] )

    (* when some destination of a move is not also a source *)
    | ol', ready ->
       loop (List.fold_left (fun os (x,_,o) ->
                 os >@ emit_mov (compile_operand o) (compile_operand (Loc x))) outstream ready)
            ol'
  in
  loop [] ol'


(* compiling call  ---------------------------------------------------------- *)

let compile_call live (fo:Alloc.operand) (os:(ty * Alloc.operand) list) : x86stream =
  let oreg, ostk, _ =
    List.fold_left (fun (oreg, ostk, i) (t, o) ->
        match arg_reg i with
        | Some r -> (Alloc.LReg r, t, o)::oreg, ostk, i+1
        | None -> oreg, o::ostk, i+1
      ) ([], [], 0) os in
  let nstack = List.length ostk in
  let live' = LocSet.of_list @@ List.map (fun (r,_,_) -> r) oreg in
  lift (List.map (fun o -> Pushq, [compile_operand o]) ostk)
  >@ compile_pmov (LocSet.union live live') oreg
  >:: I Asm.( Callq, [compile_operand fo] )
  >@ lift (if nstack <= 0 then []
           else Asm.[ Addq, [~$(nstack * 8); ~%Rsp] ])


(* compiling getelementptr (gep)  ------------------------------------------- *)

let rec size_ty tdecls t : int =
  begin match t with
    | Void | I8 | Fun _ -> 0
    | I1 | I64 | Ptr _ -> 8 (* Target 64-bit only subset of X86 *)
    | Struct ts -> List.fold_left (fun acc t -> acc + (size_ty tdecls t)) 0 ts
    | Array (n, t) -> n * (size_ty tdecls t)
    | Namedt id -> size_ty tdecls (List.assoc id tdecls)
  end

(* Compute the size of the offset (in bytes) of the nth element of a region
   of memory whose types are given by the list. Also returns the nth type. *)
let index_into tdecls (ts:ty list) (n:int) : int * ty =
  let rec loop ts n acc =
    begin match (ts, n) with
      | (u::_, 0) -> (acc, u)
      | (u::us, n) -> loop us (n-1) (acc + (size_ty tdecls u))
      | _ -> failwith "index_into encountered bogus index"
    end
  in loop ts n 0

let imm_of_int (n:int) = Imm (Lit (Int64.of_int n))

let compile_getelementptr tdecls (t:Ll.ty) (o:Alloc.operand)
    (path: Alloc.operand list) : x86stream  =

  let rec loop ty path (code : x86stream) =
    match (ty, path) with
    | (_, []) -> code

    | (Struct ts, Alloc.Const n::rest) ->
       let (offset, u) = index_into tdecls ts (Int64.to_int n) in
       loop u rest @@ (
         code >:: I Asm.(Addq, [~$offset; ~%Rax])
       )

    | (Array(_, u), Alloc.Const n::rest) ->
       (* Statically calculate the offset *)
       let offset = (size_ty tdecls u) * (Int64.to_int n) in
       loop u rest @@ (
         code >:: I Asm.(Addq, [~$offset; ~%Rax])
       )

    | (Array(_, u), offset_op::rest) ->
      loop u rest @@ (
        code >@
        ([I Asm.(Movq, [~%Rax; ~%Rcx])] >@
         (emit_mov (compile_operand offset_op) (Reg Rax)) >@
         [I Asm.(Imulq, [imm_of_int @@ size_ty tdecls u; ~%Rax])] >@
         [I Asm.(Addq, [~%Rcx; ~%Rax])]
        )
      )

    | (Namedt t, p) -> loop (List.assoc t tdecls) p code

    | _ -> failwith "compile_gep encountered unsupported getelementptr data" in

  match t with
  | Ptr t -> loop (Array(0, t)) path (emit_mov (compile_operand o) (Reg Rax))
  | _ -> failwith "compile_gep got incorrect parameters"

(* compiling instructions within function bodies ---------------------------- *)


let compile_fbody tdecls (af:Alloc.fbody) : x86stream =
  let rec loop (af:Alloc.fbody) (outstream:x86stream) : x86stream =
    let cb = function
      | Ll.Add ->  Addq | Ll.Sub ->  Subq | Ll.Mul ->  Imulq
      | Ll.Shl ->  Shlq | Ll.Lshr -> Shrq | Ll.Ashr -> Sarq
      | Ll.And ->  Andq | Ll.Or ->   Orq  | Ll.Xor ->  Xorq in
    let cc = function
      | Ll.Eq  -> Set Eq | Ll.Ne  -> Set Neq | Ll.Slt -> Set Lt
      | Ll.Sle -> Set Le | Ll.Sgt -> Set Gt  | Ll.Sge -> Set Ge in
    let co = compile_operand in

    let open Alloc in
    match af with
    | [] -> outstream

    | (ILbl (LLbl l), _)::rest ->
       loop rest @@
         (outstream
          >:: L (l, false) )

    | (PMov ol, live)::rest ->
       loop rest @@
         ( outstream
           >@ compile_pmov live ol )

    | (Icmp (LVoid, _,_,_,_), _)::rest ->  loop rest outstream
    | (Binop (LVoid, _,_,_,_), _)::rest -> loop rest outstream
    | (Alloca (LVoid, _), _)::rest -> loop rest outstream
    | (Bitcast (LVoid, _,_,_), _)::rest -> loop rest outstream
    | (Load (LVoid, _,_), _)::rest -> loop rest outstream
    | (Gep (LVoid, _,_,_), _)::rest -> loop rest outstream

    | (Icmp (x, c,_,Loc (LReg o),o'), _)::rest ->
       loop rest @@
         ( outstream
           >@ lift Asm.[ Cmpq,       [co o'; ~%o]
                       ; cc c,       [co (Loc x)]
                       ; Andq,       [~$1; co (Loc x)] ] )


    | (Icmp (x, c,_,o,o'), _)::rest ->
       loop rest @@
         ( outstream
           >@ emit_mov (co o) (Reg Rax)
           >@ lift Asm.[ Cmpq,       [co o'; ~%Rax]
                       ; cc c,       [co (Loc x)]
                       ; Andq,       [~$1; co (Loc x)] ] )

    (* Shift instructions must use Rcx or Immediate as second arg *)
    | (Binop (x, bop,_,o,o'), _)::rest
      when (bop = Shl || bop = Lshr || bop = Ashr)
      ->
       loop rest @@
         ( outstream
           >@ emit_mov (co o) (Reg Rax)
           >@ emit_mov (co o') (Reg Rcx)
           >@ lift Asm.[ cb bop,     [~%Rcx; ~%Rax]
                       ; Movq,       [~%Rax; co (Loc x)] ] )

    | (Binop (LReg r, bop,_,o,o'), _)::rest
      when Loc (LReg r) = o' &&
        (bop = Add || bop = Mul || bop = And || bop = Or || bop = Xor) ->
      loop rest @@
         ( outstream
           >:: I Asm.( cb bop,       [co o; ~%r] ) )


    | (Binop (LReg r, b,_,o,o'), _)::rest when Loc (LReg r) <> o' ->
       loop rest @@
         ( outstream
           >@ emit_mov (co o) (Reg r)
           >:: I Asm.( cb b,       [co o'; ~%r] ) )

    | (Binop (x, b,_,o,o'), _)::rest ->
       loop rest @@
         ( outstream
           >@ emit_mov (co o) (Reg Rax)
           >@ lift Asm.[ cb b,       [co o'; ~%Rax]
                       ; Movq,       [~%Rax; co (Loc x)] ] )

    | (Alloca (x, at), _)::rest ->
       loop rest @@
         ( outstream
           >@ lift Asm.[ Subq, [~$(size_ty tdecls at); ~%Rsp]
                       ; Movq, [~%Rsp; co (Loc x)] ] )


    | (Bitcast (x, _,o,_), _)::rest ->
       loop rest @@
         ( outstream
           >@ emit_mov (co o) (Reg Rax)
           >:: I Asm.( Movq, [~%Rax; co (Loc x)] ) )


    | (Load (LReg x, _, Loc (LReg src)), _)::rest ->
       loop rest @@
         ( outstream
           >:: I Asm.( Movq, [Ind2 src; ~%x] ) )

    | (Load (x, _, src), _)::rest ->
       loop rest @@
         ( outstream
           >@ emit_mov (co src) (Reg Rax)
           >@ lift Asm.[ Movq, [Ind2 Rax; ~%Rax]
                       ; Movq, [~%Rax; co (Loc x)] ] )

    | (Store (_,Loc (LReg src),Loc (LReg dst)), _)::rest ->
       loop rest @@
         ( outstream
           >:: I Asm.( Movq, [~%src; Ind2 dst] ) )

    | (Store (_,src,dst), _)::rest ->
       loop rest @@
         ( outstream
           >@ emit_mov (co src) (Reg Rax)
           >@ emit_mov (co dst) (Reg Rcx)
           >:: I Asm.( Movq, [~%Rax; Ind2 Rcx] ) )

    | (Gep (x, at,o,os), _)::rest ->
       loop rest @@
         ( outstream
           >@ compile_getelementptr tdecls at o os
           >:: I Asm.( Movq, [~%Rax; co (Loc x)] ) )

    | (Call (x, t,fo,os), live)::rest ->
      (* Corner: fo is Loc (LReg r) and r is used in the calling conventions.
         Then we use R15 to hold the function pointer, saving and restoring it,
         since it is a callee-save register.                                  *)
      let fptr_op, init_fp, restore_fp =
        begin match fo with
          | Loc (LReg (Rdi | Rsi | Rdx | Rcx | R08 | R09)) ->
            Loc (LReg R15),
            [I Asm.(Pushq, [~%R15])] >@ (emit_mov (co fo) (Reg R15)),
            [I Asm.(Popq, [~%R15])]
          | _ -> fo, [], []
        end
      in
      let () = Platform.verb @@ Printf.sprintf "call: %s live = %s\n"
          (str_operand fo) (str_locset live)
      in
       let save = LocSet.(elements @@ inter (remove x live) caller_save) in
       loop rest @@
       ( outstream
         >@ init_fp
         >@ lift (List.rev_map (fun x -> Pushq, [co (Loc x)]) save)
         >@ compile_call live fptr_op os
         >@ lift (List.map (fun x -> Popq, [co (Loc x)]) save)
         >@ restore_fp
         >@ (if t = Ll.Void || x = LVoid then []
             else lift Asm.[ Movq, [~%Rax; co (Loc x)] ]) )

    | (Ret (_,None), _)::rest ->
       loop rest @@
         ( outstream
           >@ lift Asm.[ Movq, [~%Rbp; ~%Rsp]
                       ; Popq, [~%Rbp]
                       ; Retq, [] ] )

    | (Ret (_,Some o), _)::rest ->
       loop rest @@
         ( outstream
           >@ emit_mov (co o) (Reg Rax)
           >@ lift Asm.[ Movq, [~%Rbp; ~%Rsp]
                       ; Popq, [~%Rbp]
                       ; Retq, [] ] )

    | (Br (LLbl l), _)::rest ->
       loop rest @@
         ( outstream
           >:: I Asm.( Jmp, [~$$l] ) )

    | (Cbr (Const i,(LLbl l1),(LLbl l2)), _)::rest ->
       loop rest @@
         ( outstream
           >:: (if i <> 0L
                then I Asm.( Jmp, [~$$l1] )
                else I Asm.( Jmp, [~$$l2] ) ) )

    | (Cbr (o,(LLbl l1),(LLbl l2)), _)::rest ->
       loop rest @@
         ( outstream
           >@ lift Asm.[ Cmpq,  [~$0; co o]
                       ; J Neq, [~$$l1]
                       ; Jmp,   [~$$l2] ] )

    | _ -> failwith "codegen failed to find instruction"
  in
  loop af []


(* compile_fdecl ------------------------------------------------------------ *)

(* Processes a function declaration by processing each of the subcomponents
   in turn:
     - first fold over the function parameters
     - then fold over the entry block
     - then fold over the subsequent blocks in their listed order
       To fold over a block:
           - fold over the label
           - then the instructions (in block order)
           - then the terminator

  See the examples no_reg_layout and greedy_layout for how to use this function.
*)
let fold_fdecl (f_param : 'a -> uid * Ll.ty -> 'a)
               (f_lbl  : 'a -> lbl -> 'a)
               (f_insn : 'a -> uid * Ll.insn -> 'a)
               (f_term : 'a -> uid * Ll.terminator -> 'a)
               (init:'a) (f:Ll.fdecl) : 'a =
  let fold_params ps a =
    List.fold_left f_param a ps in
  let fold_block {insns; term} a =
    f_term (List.fold_left f_insn a insns) term in
  let fold_lbl_block (l,blk) a =
    fold_block blk (f_lbl a l) in
  let fold_lbl_blocks bs a =
    List.fold_left (fun a b -> fold_lbl_block b a) a bs in
  let entry,bs = f.f_cfg in
  init
  |> fold_params (List.combine f.f_param (fst f.f_ty))
  |> fold_block entry
  |> fold_lbl_blocks bs


(* no layout ---------------------------------------------------------------- *)
(* This register allocation strategy puts all uids into stack
   slots. It does not use liveness information.
*)
let insn_assigns : Ll.insn -> bool = function
  | Ll.Call (Ll.Void, _, _) | Ll.Store _ -> false
  | _ -> true

let no_reg_layout (f:Ll.fdecl) (_:liveness) : layout =
  let lo, n_stk =
    fold_fdecl
      (fun (lo, n) (x, _) -> (x, Alloc.LStk (- (n + 1)))::lo, n + 1)
      (fun (lo, n) l -> (l, Alloc.LLbl (Platform.mangle l))::lo, n)
      (fun (lo, n) (x, i) ->
        if insn_assigns i
        then (x, Alloc.LStk (- (n + 1)))::lo, n + 1
        else (x, Alloc.LVoid)::lo, n)
      (fun a _ -> a)
      ([], 0) f in
  { uid_loc = (fun x -> List.assoc x lo)
  ; spill_bytes = 8 * n_stk
  }

(* greedy layout ------------------------------------------------------------ *)
(* This example register allocation strategy puts the first few uids in
   available registers and spills the rest. It uses liveness information to
   recycle available registers when their current value becomes dead.

   There is a corner case where we might have to try to allocate a location
   but there is a live variable who's location is unknown!  (This can happen
   in a loop... see gcd_euclidean.ll for an example.)  In that case, we
   should just spill attempt to avoid conflicts.
*)

let greedy_layout (f:Ll.fdecl) (live:liveness) : layout =
  let n_arg = ref 0 in
  let n_spill = ref 0 in

  let spill () = (incr n_spill; Alloc.LStk (- !n_spill)) in

  (* Allocates a destination location for an incoming function parameter.
     Corner case: argument 3, in Rcx occupies a register used for other
     purposes by the compiler.  We therefore always spill it.
  *)
  let alloc_arg () =
    let res =
      match arg_loc !n_arg with
      | Alloc.LReg Rcx -> spill ()
      | x -> x
    in
    incr n_arg; res
  in
  (* The available palette of registers.  Excludes Rax and Rcx *)
  let pal = LocSet.(caller_save
                    |> remove (Alloc.LReg Rax)
                    |> remove (Alloc.LReg Rcx)
                   )
  in

  (* Allocates a uid greedily based on liveness information *)
  let allocate lo uid =
    let loc =
    try
      let used_locs =
        UidSet.fold (fun y -> LocSet.add (List.assoc y lo)) (live uid) LocSet.empty
      in
      let available_locs = LocSet.diff pal used_locs in
      LocSet.choose available_locs
    with
    | Not_found -> spill ()
    in
    Platform.verb @@ Printf.sprintf "allocated: %s <- %s\n" (Alloc.str_loc loc) uid; loc
  in

  let lo =
    fold_fdecl
      (fun lo (x, _) -> (x, alloc_arg())::lo)
      (fun lo l -> (l, Alloc.LLbl (Platform.mangle l))::lo)
      (fun lo (x, i) ->
        if insn_assigns i
        then (x, allocate lo x)::lo
        else (x, Alloc.LVoid)::lo)
      (fun lo _ -> lo)
      [] f in
  { uid_loc = (fun x -> List.assoc x lo)
  ; spill_bytes = 8 * !n_spill
  }


(* better register allocation ----------------------------------------------- *)
(* TASK: Implement a (correct) register allocation strategy that
   outperforms the greedy layout strategy given above, assuming that
   the liveness information is calculated using the dataflow analysis
   from liveness.ml.

   Your implementation does _not_ necessarily have to do full-blown
   coalescing graph coloring as described in lecture.  You may choose
   a simpler strategy.  In particular, a non-coalescing graph coloring
   algorithm that uses some simple preference heuristics should be
   able to beat the greedy algorithm.

   To measure the effectiveness of your strategy, our testing infrastructure
   uses a simple heuristic to compare it with the 'greedy' strategy given above.

   QUALITY HEURISTIC:
   The 'quality score' of a register assignment for an x86 program is based
   on two things:
     - the total number of memory accesses, which is the sum of:
          - the number of Ind2 and Ind3 operands
          - the number of Push and Pop instructions

     - size(p) the total number of instructions in the x86 program

   Your goal for register allocation should be to minimize the number of
   memory operations and, secondarily, the overall size of the program.

   registers.ml provides some helper functions that you can use to
   get the size and total number of memory operations in a program.  It
   also provides a function that computes a histogram of the register usage,
   which can be helpful when testing your register allocator.

   To see whether your register assignment is better than the greedy one,
   we check:
      if #mem_ops(yours) < #mem_ops(greedy)  then yours is better
     otherwise if size(yours) < size(greedy) then yours is better
     otherwise greedy wins.

   Hints:
    - The Datastructures file provides a UidMap that can be used to
      create your interference graph.

    - It may be useful to understand how this version of the compiler
      deals with function calls (see compile_pmov) and what the
      greedy allocator does.

    - The compiler uses Rax and Rcx in its code generation, so they
      are _not_ generally available for your allocator to use.

      . other caller_save registers are freely available

      . if you want to use callee_save registers you might have to
        adjust the code generated by compile_fdecl to save/restore them.
*)


type graph = UidS.t UidM.t
type colors = int UidM.t
let better_layout (f:Ll.fdecl) (live:liveness) : layout =



let n_arg = ref 0 in

let arg_to_color (arg:int ref) :int =
  incr arg;
  if(!arg <= 8) then !arg else -1
in
let pal = LocSet.(caller_save
                  |> remove (Alloc.LReg Rax)
                  |> remove (Alloc.LReg Rcx)
                 )
in

let n = LocSet.cardinal pal in


let cfg = of_ast(f) in
let uids = LblM.fold(fun k d acc ->
            let uids = List.append (List.map(fun ins -> fst ins) d.insns) [fst d.term] in
                        List.append uids acc
                      ) cfg.blocks [] in

let colors0 = List.fold_left(fun map uid -> UidM.add uid 0 map) UidM.empty uids in
let colors =
      fold_fdecl
        (fun colors (x, _) -> UidM.add x (arg_to_color n_arg) colors)
        (fun colors l -> colors)
        (fun colors (x, i) -> colors)
        (fun colors _ -> colors)
        colors0 f in
  let create_graph() :graph  =
    let set = List.fold_left (fun acc uid -> UidS.union acc (live uid))  UidS.empty uids in
    let g = UidS.fold( fun elt acc -> UidM.add elt UidS.empty acc) set UidM.empty in
    g
  in
  let rec add_edges_to_graph (g:graph) :graph =
    List.fold_left(fun g0 uid  ->
      let set = live uid in
      UidS.fold(fun elt1 g1 ->
                 UidS.fold(fun elt2 g2 ->
                            if (elt1 = elt2) then g2 else
                            let old_set1 = UidM.find elt1 g2 in
                            let old_set2 = UidM.find elt2 g2 in
                            let new_set1 = UidS.add elt2 old_set1 in

                            let new_set2 = UidS.add elt1 old_set2 in
                            let new_g2 = UidM.add elt1 new_set1 g2 in
                            UidM.add elt2 new_set2 new_g2
                          ) set g1
               ) set g0
      ) g uids
  in

  let graph_to_string (g:graph) :string =
    let set_to_string (s:UidS.t) :string =
      UidS.fold(fun elt acc -> elt ^ " " ^  acc  ) s ""
    in
    UidM.fold(fun k set acc -> ( k ^ ":" ^ "{"  ^ (set_to_string set) ^ "}\n") ^ acc ) g ""
  in

  let colors_to_string (c:colors) :string =
    UidM.fold(fun k color acc -> k ^ ": " ^ (string_of_int color)^ "\n" ^ acc ^ "\n") c ""
  in


  let pick_node (g:graph) :(uid * UidS.t) option =
    (* let first = try UidM.find_first_opt (fun k -> (UidS.cardinal (UidM.find k g)) > n) g with Not_found -> None in
    begin match first with
      | None -> None
      | Some x ->
        let b =  UidM.fold(fun k elt curr ->
                            (* && ((UidS.cardinal elt) > 0) *)
                            let repl = ((UidS.cardinal elt) > (UidS.cardinal curr)) in
                            if repl then elt else curr
                          ) g (snd x) in
      Some (fst x , b)
    end *)
    try UidM.find_first_opt(fun k -> (UidS.cardinal (UidM.find k g)) < n) g with
     Not_found -> None
  in


  let add_node ((g,c):(graph * colors)) ((uid,edges):(uid * UidS.t)):graph * colors =
    (UidM.add uid edges g), c
  in
  let remove_node ((g,c):(graph * colors)) (uid:uid) :graph* colors =
    (UidM.remove uid g), c
  in
  let colored (g:graph) (c:colors) :bool =
    let uncolored_nodes = UidM.fold(fun k elt acc ->
                                    if (UidM.mem k c) then acc
                                    else acc + 1 ) g 0 in
   uncolored_nodes <= 1
  in

  let remove_node_and_edges (g:graph) (uid:uid) :graph =
    let g0 = UidM.remove uid g in
    UidM.map(fun set ->
              UidS.filter(fun elt -> elt != uid) set
            ) g0
  in

  let remove_node_with_edges ((g,c):(graph * colors)) (uid:uid) :graph* colors =
    let g0 = UidM.remove uid g in
    UidM.map(fun set ->
              UidS.filter(fun elt -> elt != uid) set
            ) g0 ,c
  in

  let add_node_and_edges ((g,c):(graph * colors)) ((uid,edges):(uid * UidS.t)):graph* colors  =
    let g0 = UidM.add uid edges g in
    UidM.mapi(fun k set  -> if (UidS.mem k edges) then UidS.add uid set else set) g0 ,c
  in
  (* let find_uncolored (g:graph) (c:colors) :uid =
    fst @@ try UidM.find_first (fun k -> (UidM.mem k c) = false ) g with
           Not_found -> failwith "Coudlnt find uncolored node"
  in *)


  let spill_value (g:graph) (uid:uid):int =
    (* let in_loop(): bool =
    fold_fdecl
      (fun b (_, _) -> false || b)
      (fun b _ -> false || b)
      (fun b (x, i) -> false || b )
      (fun b _ -> false || b)
      false f
    in *)
    let get_ops_from_ins (ins:Ll.insn) :Ll.operand list =
      begin match ins with
        | Binop (_,_, op1,op2) | Store (_,op1,op2) | Icmp(_,_, op1,op2) -> [op1;op2]
        | Load (_,op)| Bitcast(_,op,_) -> [op]
        | Call (_,op,ops_t) -> op::(List.map(fun i -> snd i) ops_t)
        | Gep (_, op,ops) -> op::ops
        | _ -> []
      end
    in
    let count_ins (ins: Ll.insn): int =
      List.fold_left(fun acc op ->
          begin match op with
            | Null | Const _ -> acc
            | Id id | Gid id -> if (id = uid) then acc + 1 else acc
          end
          ) 0 (get_ops_from_ins ins)
    in
    let degree = UidS.cardinal (try UidM.find uid g with Not_found ->
                      failwith ("Didnt find " ^ uid ^
                      " in graph when looking for ideal spill node.")) in

    let count_times_called =
      fold_fdecl
        (fun acc (_, _) -> acc)
        (fun acc _ -> acc)
        (fun acc (x, i) -> count_ins i )
        (fun acc _ -> acc)
        0 f in
    degree
  in


  (*TODO choose better node to spill*)
  let find_spill_node (g:graph): uid =
    let first_uid =
      try fst @@ UidM.find_first(fun k -> UidS.cardinal (UidM.find k g) >= n) g
      with Not_found -> failwith "trying to spill when not necessary" in

    let best_uid = UidM.fold (fun key value acc ->
                if((spill_value g key) > (spill_value g acc)) then key else acc
              ) g first_uid in
    (* Printf.printf "\n Here is spill value of best uid(spilled) %s: %d\n"  best_uid (spill_value g best_uid); *)
    best_uid
  in




  let color_spill (c:colors) (uid:uid) :colors =
      UidM.add uid (-1) c
  in

  let card_color (c:colors) (col:int) :int =
    UidM.fold(fun key elt acc -> if elt = col then acc + 1 else acc) c 0
  in


  let choose_color1 (g:graph)(c:colors) (uid:uid) :int =
    let nb = try  UidM.find uid g with Not_found -> failwith "This shouldnt happen (finding node i just added)" in
    let av_col = List.init n (fun x -> x + 1) in
    try List.find(fun col -> UidS.for_all(fun elt -> (try UidM.find elt c with Not_found -> 0) != col) nb ) av_col
              with Not_found -> failwith "coudlnt find a color to fill in"
  in

  let choose_color (g:graph)(c:colors) (uid:uid) :int =
    let nb = try  UidM.find uid g with Not_found -> failwith "This shouldnt happen (finding node i just added)" in
    let all_col = List.init n (fun x -> x + 1) in
    let av_col = List.filter(fun col -> UidS.for_all(fun elt -> (try UidM.find elt c with Not_found -> 0) != col) nb ) all_col in
    let first = try List.hd av_col with Failure _ -> failwith "Couldnt find a color to fill in" in
    List.fold_left (fun curr col ->
                      let repl = (card_color c col) > (card_color c curr) in
                      if repl then col else curr
                   ) first av_col
  in

  let add_color ((g,c):(graph * colors)) (uid:uid) :graph * colors =

    let new_c = choose_color g c uid in
    (g, (UidM.add uid new_c c))
  in
  let rec color_graph ((g,c):(graph * colors))   :graph * colors =
    if (UidM.is_empty g ) then (g,c) else
    (* if (colored g c) then (g,c) else *)

    if ((pick_node g) = None) then
              let s = find_spill_node g in
              let g_new = remove_node_and_edges g s in
              let c_new = color_spill c s in
              color_graph(g_new,c_new)
    else
              let (name,edges) = begin match (pick_node g) with | Some x -> x
              | None -> failwith "failed to catch a spill" end in
              add_color (add_node_and_edges (color_graph((remove_node_with_edges (g,c) name))) (name,edges)) name
              (* add_color (add_node (color_graph((remove_node (g,c) name))) (name,edges)) name *)
  in


  let create_layout (c:colors) :layout  =
    let n_spill = ref 0 in
    let spill () = (incr n_spill; Alloc.LStk (- !n_spill)) in
    let col_to_loc (col:int) :Alloc.loc =
      begin match col with
        | -1 -> spill()
        | 0 -> Alloc.LVoid
        | 1 -> Alloc.LReg (Rdi)
        | 2 -> Alloc.LReg (Rsi)
        | 3 -> Alloc.LReg (Rdx)
        | 4 -> Alloc.LReg (Rcx)
        | 5 -> Alloc.LReg (R08)
        | 6 -> Alloc.LReg (R09)
        | 7 -> Alloc.LReg (R10)
        | 8 -> Alloc.LReg (R11)
        | _ -> failwith "Graph coloring algorithm assigned more colors then we have registers"
      end
    in
    let uid_ass = List.map(fun(uid,col) -> (uid,(col_to_loc col))) (UidM.bindings c) in
    let fun_uid_ass x = try List.assoc x uid_ass with
    Not_found -> failwith ("Trying to map uid to location that isnt in colors") in
    let lo =
      fold_fdecl
        (fun lo (x, _) -> (x, fun_uid_ass x)::lo) (*This is for function param*)
        (fun lo l -> (l, Alloc.LLbl (Platform.mangle l))::lo) (*This is for lablels*)
        (fun lo (x, i) -> (*This is for insns*)
          if insn_assigns i
          then (x, fun_uid_ass x)::lo
          else (x, Alloc.LVoid)::lo)
        (fun lo _ -> lo)  (*term?*)
        [] f in
    (*TODO precolor args to correct registers*)
    { uid_loc = (fun x -> try List.assoc x lo with Not_found -> failwith ("No location assignment for this uid" ^ x))
    ; spill_bytes = 8 * !n_spill
    }
  in


  let g1 = create_graph() in
  let g = add_edges_to_graph(g1) in
  let g_after_color,final_colors = color_graph (g, colors) in
(* 
  Printf.printf "\nGRAPH REGALLOC\n---------------\n%s\n" (graph_to_string g);
  Printf.printf "\nGRAPH AFTER SPILL\n---------------\n%s\n" (graph_to_string g_after_color);
  Printf.printf "\nColor assignments\n-------------\n%s\n" (colors_to_string final_colors); *)

  (* let random_uid = fst @@ UidM.find_first(fun k -> true) g in
  Printf.printf "\nSpill value of uid %s: %d\n" random_uid (spill_value g random_uid); *)
  let lo = create_layout final_colors in

  lo



(* register allocation options ---------------------------------------------- *)
(* A trivial liveness analysis that conservatively says that every defined
   uid is live across every edge. *)
let trivial_liveness (f:Ll.fdecl) : liveness =
  let s =
    fold_fdecl
      (fun s (x, _) -> UidSet.add x s)
      (fun s _ -> s)
      (fun s (x, i) -> if insn_assigns i then UidSet.add x s else s)
      (fun s _ -> s)
      UidSet.empty f in
  fun _ -> s

let liveness_fn : (Ll.fdecl -> liveness) ref =
  ref trivial_liveness

let layout_fn : (Ll.fdecl -> liveness -> layout) ref =
  ref no_reg_layout

let set_liveness name =
  liveness_fn := match name with
  | "trivial" -> trivial_liveness
  | "dataflow" -> Liveness.get_liveness
  | _ -> failwith "impossible arg"

let set_regalloc name =
  layout_fn := match name with
  | "none"   -> no_reg_layout
  | "greedy" -> greedy_layout
  | "better" -> better_layout
  | _ -> failwith "impossible arg"

(* Compile a function declaration using the chosen liveness analysis
   and register allocation strategy. *)
let compile_fdecl tdecls (g:gid) (f:Ll.fdecl) : x86stream =
  let liveness = !liveness_fn f in
  let layout = !layout_fn f liveness in
  let afdecl = alloc_fdecl layout liveness f in
  [L (Platform.mangle g, true)]
  >@ lift Asm.[ Pushq, [~%Rbp]
              ; Movq,  [~%Rsp; ~%Rbp] ]
  >@ (if layout.spill_bytes <= 0 then [] else
      lift Asm.[ Subq,  [~$(layout.spill_bytes); ~%Rsp] ])
  >@ (compile_fbody tdecls afdecl)

(* compile_gdecl ------------------------------------------------------------ *)

let rec compile_ginit = function
  | GNull      -> [Quad (Lit 0L)]
  | GGid gid   -> [Quad (Lbl (Platform.mangle gid))]
  | GInt c     -> [Quad (Lit c)]
  | GString s  -> [Asciz s]
  | GArray gs
  | GStruct gs -> List.(flatten @@ map compile_gdecl gs)

and compile_gdecl (_, g) = compile_ginit g

(* compile_prog ------------------------------------------------------------- *)

let compile_prog {tdecls; gdecls; fdecls} : X86.prog =
  let g = fun (lbl, gdecl) -> Asm.data (Platform.mangle lbl) (compile_gdecl gdecl) in
  let f = fun (name, fdecl) -> prog_of_x86stream @@ compile_fdecl tdecls name fdecl in
  (List.map g gdecls) @ List.(flatten @@ map f fdecls)
