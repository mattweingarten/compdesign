(** Alias Analysis *)

open Ll
open Datastructures

(* The lattice of abstract pointers ----------------------------------------- *)
module SymPtr = struct
  type t =
    | MayAlias (* uid names a pointer that may be aliased *)
    | Unique (* uid is the unique name for a pointer *)
    | UndefAlias

  (* uid is not in scope or not a pointer *)

  let compare : t -> t -> int = Pervasives.compare

  let join t1 t2 =
    match (t1, t2) with
    | UndefAlias, UndefAlias -> UndefAlias
    | Unique, Unique -> Unique
    | UndefAlias, Unique | Unique, UndefAlias -> Unique
    | _ -> MayAlias

  let to_string = function
    | MayAlias -> "MayAlias"
    | Unique -> "Unique"
    | UndefAlias -> "UndefAlias"
end

(* The analysis computes, at each program point, which UIDs in scope are a unique name
   for a stack slot and which may have aliases *)
type fact = SymPtr.t UidM.t

(* flow function across Ll instructions ------------------------------------- *)
(* TASK: complete the flow function for alias analysis.

   - After an alloca, the defined UID is the unique name for a stack slot
   - A pointer returned by a load, call, bitcast, or GEP may be aliased
   - A pointer passed as an argument to a call, bitcast, GEP, or store
     may be aliased
   - Other instructions do not define pointers

*)
let add_op t op d =
  match (t, op) with Ptr _, Id id -> UidM.add id SymPtr.MayAlias d | _ -> d

let add_ptr t u d =
  match t with Ptr _ -> UidM.add u SymPtr.MayAlias d | _ -> d

let add_ptr2 t u d =
  match t with Ptr (Ptr _) -> UidM.add u SymPtr.MayAlias d | _ -> d

let insn_flow ((u, i) : uid * insn) (d : fact) : fact =
  match i with
  | Ll.Alloca t -> UidM.add u SymPtr.Unique d
  | Ll.Load (t, _) -> add_ptr2 t u d
  | Ll.Call (t, _, ops) ->
      let d' = add_ptr t u d in
      let fold acc (ty, o) = add_op ty o acc in
      List.fold_left fold d' ops
  | Ll.Bitcast (t1, op, t2) ->
      let d' = add_ptr t2 u d in
      add_op t1 op d'
  | Ll.Gep (t, op, _) ->
      let d' = UidM.add u SymPtr.MayAlias d in
      add_op (Ptr t) op d'
  | Ll.Store (t, o1, o2) -> add_op t o2 d
  | _ -> UidM.add u SymPtr.UndefAlias d

(* The flow function across terminators is trivial: they never change alias info *)
let terminator_flow t (d : fact) : fact = d

(* module for instantiating the generic framework --------------------------- *)
module Fact = struct
  type t = fact

  let forwards = true

  let insn_flow = insn_flow

  let terminator_flow = terminator_flow

  (* UndefAlias is logically the same as not having a mapping in the fact. To
       compare dataflow facts, we first remove all of these *)
  let normalize : fact -> fact = UidM.filter (fun _ v -> v != SymPtr.UndefAlias)

  let compare (d : fact) (e : fact) : int =
    UidM.compare SymPtr.compare (normalize d) (normalize e)

  let to_string : fact -> string =
    UidM.to_string (fun _ v -> SymPtr.to_string v)

  (* TASK: complete the "combine" operation for alias analysis.

       The alias analysis should take the join over predecessors to compute the
       flow into a node. You may find the UidM.merge function useful.

       It may be useful to define a helper function that knows how to take the
       join of two SymPtr.t facts.
  *)
  let combine (ds : fact list) : fact =
    let join_ptr k a b =
      match (a, b) with
      | x, None | None, x -> x
      | Some x, Some y -> Some (SymPtr.join x y)
    in
    let fold acc m = UidM.merge join_ptr acc m in
    List.fold_left fold UidM.empty ds
end

(* instantiate the general framework ---------------------------------------- *)
module Graph = Cfg.AsGraph (Fact)
module Solver = Solver.Make (Fact) (Graph)

(* expose a top-level analysis operation ------------------------------------ *)
let analyze (g : Cfg.t) : Graph.t =
  (* the analysis starts with every node set to bottom (the map of every uid
     in the function to UndefAlias *)
  let init l = UidM.empty in

  (* the flow into the entry node should indicate that any pointer parameter
     to the function may be aliased *)
  let alias_in =
    List.fold_right
      (fun (u, t) ->
        match t with Ptr _ -> UidM.add u SymPtr.MayAlias | _ -> fun m -> m)
      g.Cfg.args UidM.empty
  in
  let fg = Graph.of_cfg init alias_in g in
  Solver.solve fg
