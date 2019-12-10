  open Ll
open Datastructures

(* The lattice of symbolic constants ---------------------------------------- *)
module SymConst =
  struct
    type t = NonConst           (* Uid may take on multiple values at runtime *)
           | Const of int64     (* Uid will always evaluate to const i64 or i1 *)
           | UndefConst         (* Uid is not defined at the point *)

    let compare s t =
      match (s, t) with
      | (Const i, Const j) -> Int64.compare i j
      | (NonConst, NonConst) | (UndefConst, UndefConst) -> 0
      | (NonConst, _) | (_, UndefConst) -> 1
      | (UndefConst, _) | (_, NonConst) -> -1

    let to_string : t -> string = function
      | NonConst -> "NonConst"
      | Const i -> Printf.sprintf "Const (%LdL)" i
      | UndefConst -> "UndefConst"


   let join x y =
    begin match x,y with
      | (Const a, Const b) -> if a = b then Some (Const(a))
                                       else Some (NonConst)
      | (_,UndefConst) | (UndefConst,_) -> Some (UndefConst)
      | _ -> Some (NonConst)
   end
  end

(* The analysis computes, at each program point, which UIDs in scope will evaluate
   to integer constants *)
type fact = SymConst.t UidM.t



(* flow function across Ll instructions ------------------------------------- *)
(* - Uid of a binop or icmp with const arguments is constant-out
   - Uid of a binop or icmp with an UndefConst argument is UndefConst-out
   - Uid of a binop or icmp with an NonConst argument is NonConst-out
   - Uid of stores and void calls are UndefConst-out
   - Uid of all other instructions are NonConst-out
 *)
let insn_flow (u,i:uid * insn) (d:fact) : fact =


  let eval_op (op:operand) :SymConst.t =
    begin match op with
      | Const x -> SymConst.Const x
      | Gid id | Id id -> let res =
        try UidM.find id d
        with Not_found ->
        (* failwith ("Constproperror: couldnt find this ID:" ^ id) *)
        SymConst.UndefConst
        in res
      | Null -> failwith "Cannot evaluate null in eval_op"
    end
  in


  let flow_function op x y :SymConst.t =
    let i =  eval_op x in
    let j = eval_op y in
    begin match (i,j) with
      | (SymConst.Const x, SymConst.Const y) -> SymConst.Const(op x y)
      | (_, SymConst.UndefConst) -> SymConst.UndefConst
      | (SymConst.UndefConst,_) -> SymConst.UndefConst
      | _ -> SymConst.NonConst
    end
  in

  (*TODO: optimization like mul with 0*)
  let bop_flow (bop:bop)(t:ty)(x: operand) (y:operand) :fact =
    let map_bop = begin match bop with
        | Add -> Int64.add
        | Sub -> Int64.sub
        | Mul -> Int64.mul
        | Shl ->  fun x y -> Int64.shift_left x (Int64.to_int y)
        | Ashr -> fun x y -> Int64.shift_right x (Int64.to_int y)
        | Lshr -> fun x y -> Int64.shift_right_logical x (Int64.to_int y)
        | And -> Int64.logand
        | Or -> Int64.logor
        | Xor -> Int64.logxor
      end
    in
    UidM.add u (flow_function map_bop x y) d
  in

  let icmp_flow (cnd:cnd)(t:ty)(x: operand) (y:operand) :fact=
    let cmp_op = begin match cnd with
      | Eq -> fun x y -> if (Int64.equal x y) then 1L else 0L
      | Ne ->  fun x y -> if (Int64.equal x y) then 0L else 1L
      | Slt -> fun x y -> if (Int64.compare x y) < 0 then 1L else 0L
      | Sle -> fun x y -> if (Int64.compare x y) <= 0 then 1L else 0L
      | Sgt -> fun x y -> if (Int64.compare x y) > 0 then 1L else 0L
      | Sge -> fun x y -> if (Int64.compare x y) >= 0 then 1L else 0L
    end
    in
    UidM.add u (flow_function cmp_op x y) d
  in

  begin match i with
    | Binop (bop,t,x,y) -> bop_flow bop t x y
    | Icmp (cnd,t,x,y) -> icmp_flow cnd t x y
    | Store _ -> UidM.add u (SymConst.UndefConst) d
    | Call (t,_,_) -> if (t = Void) then UidM.add u (SymConst.UndefConst) d
                                    else UidM.add u (SymConst.NonConst) d
    | _ -> UidM.add u (SymConst.NonConst) d
  end

(* The flow function across terminators is trivial: they never change const info *)
let terminator_flow (t:terminator) (d:fact) : fact = d

(* module for instantiating the generic framework --------------------------- *)
module Fact =
  struct
    type t = fact
    let forwards = true

    let insn_flow = insn_flow
    let terminator_flow = terminator_flow

    let normalize : fact -> fact =
      UidM.filter (fun _ v -> v != SymConst.UndefConst)

    let compare (d:fact) (e:fact) : int  =
      UidM.compare SymConst.compare (normalize d) (normalize e)

    let to_string : fact -> string =
      UidM.to_string (fun _ v -> SymConst.to_string v)

    (* The constprop analysis should take the join over predecessors to compute the
       flow into a node. You may find the UidM.merge function useful *)
    let combine (ds:fact list) : fact =
      let join_const k (x:SymConst.t option) (y:SymConst.t option) :SymConst.t option=
        begin match x, y with
          | None, x  -> x | x, None -> x
          | Some x, Some y -> SymConst.join x y
        end
      in
      let fold acc m = UidM.merge join_const acc m in
      List.fold_left fold UidM.empty ds
  end

(* instantiate the general framework ---------------------------------------- *)
module Graph = Cfg.AsGraph (Fact)
module Solver = Solver.Make (Fact) (Graph)

(* expose a top-level analysis operation ------------------------------------ *)
let analyze (g:Cfg.t) : Graph.t =
  (* the analysis starts with every node set to bottom (the map of every uid
     in the function to UndefConst *)
  let init l = UidM.empty in

  (* the flow into the entry node should indicate that any parameter to the
     function is not a constant *)
  let cp_in = List.fold_right
    (fun (u,_) -> UidM.add u SymConst.NonConst)
    g.Cfg.args UidM.empty
  in
  let fg = Graph.of_cfg init cp_in g in
  Solver.solve fg


(* run constant propagation on a cfg given analysis results ----------------- *)
(* HINT: your cp_block implementation will probably rely on several helper
   functions.                                                                 *)
let run (cg:Graph.t) (cfg:Cfg.t) : Cfg.t =
  let open SymConst in




  let cp_block (l:Ll.lbl) (cfg:Cfg.t) : Cfg.t =
    let b = Cfg.block cfg l in
    let cb = Graph.uid_out cg l in
    let get_sym (uid:uid) (id:uid) :SymConst.t =
      try UidM.find id (cb uid) with Not_found -> failwith ("cpblock: couldnt find ID: " ^ id)
    in
    let replace (uid:uid)(op:operand) :operand =
      begin match op with
        | Id id | Gid id ->
                    begin match get_sym uid id with
                      | SymConst.Const(x) -> Ll.Const(x)
                      | _ -> op
                    end
        | _ -> op
      end
    in

    let replace_list (uid:uid) (ops:operand list): operand list =
      List.map(fun op -> replace uid op) ops
    in

    let replace_insn ((id,i): (uid * insn)):(uid * insn) =
      let new_i = begin match i with
        | Binop (bop,t, op1,op2) -> Binop (bop,t, replace id (op1),replace id (op2))
        | Load (t, op) -> Load(t, replace id (op))
        | Store(t, op1,op2) -> Store(t, replace id (op1), replace id (op2))
        | Icmp(c,t,op1,op2) -> Icmp(c,t,replace id (op1),replace id (op2))
        | Call(t,op,args) -> Call(t,replace id (op),(List.map(fun(id2,op) -> (id2,replace id (op))) args))
        | Bitcast (t1, op, t2) -> Bitcast(t1,replace id (op),t2)
        | Gep (t,op,ops) -> Gep(t,replace id (op),replace_list id (ops))
        | _ -> i
      end in (id,new_i)
    in

    let rec replace_insns (insns:(uid * insn) list) :(uid * insn) list =
      begin match insns with
        | (uid, insn)::tail ->
            begin match get_sym uid uid with
              | SymConst.Const(_) -> List.append [] (replace_insns tail)
              | _ -> replace_insn(uid,insn) :: (replace_insns tail)
            end
        | [] -> []
      end
    in
    let replace_term ((id,term) : (uid * terminator)) :(uid * terminator) =
      begin match term with
        | Ret (t,o) -> begin match o with
                          | None -> (id,term)
                          | Some op ->(id, Ret(t,Some(replace id op)))
                       end
        | Br _ -> (id,term)
        | Cbr (op, l1, l2) -> (id, Cbr(replace id op, l1,l2))
      end
    in
    let new_block = {insns=(replace_insns b.insns);term=(replace_term b.term)} in
    let temp = LblM.remove l (cfg.blocks) in
    {
      blocks= LblM.add l new_block (cfg.blocks);
      preds=cfg.preds;
      ret_ty=cfg.ret_ty;
      args=cfg.args
    }
  in

  LblS.fold cp_block (Cfg.nodes cfg) cfg
