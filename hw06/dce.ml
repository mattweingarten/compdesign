open Ll
(** Dead Code Elimination  *)

open Datastructures

(* expose a top-level analysis operation ------------------------------------ *)
(* TASK: This function should optimize a block by removing dead instructions
   - lb: a function from uids to the live-OUT set at the
     corresponding program point
   - ab: the alias map flowing IN to each program point in the block
   - b: the current ll block

   Note:
     Call instructions are never considered to be dead (they might produce
     side effects)

     Store instructions are not dead if the pointer written to is live _or_
     if some alias of that pointer is live.

     Other instructions are dead if the value they compute is not live.

   Hint: Consider using List.filter
 *)
let dce_block (lb : uid -> Liveness.Fact.t) (ab : uid -> Alias.fact)
    (b : Ll.block) : Ll.block =
  let is_live i id = UidS.mem i (lb id) in
  let insns = b.insns in
  let filter (id, insn) =
    match insn with
    | Call _ -> true
    | Store (_, _, op) ->
        let ptr_id, is_global =
          match op with
          | Id id -> (id, false)
          | Gid id -> (id, true)
          | _ -> failwith "not writing to pointer"
        in
        let may_alias =
          UidM.filter (fun k d -> d = Alias.SymPtr.MayAlias) (ab id)
        in
        let fold k _ a =
          a || try is_live k ptr_id with Not_found -> is_live k id
        in
        let alias_live = UidM.fold fold may_alias false in
        is_live ptr_id id || alias_live || is_global
    | _ -> is_live id id
  in
  let new_insns = List.filter filter insns in
  { insns = new_insns; term = b.term }

let run (lg : Liveness.Graph.t) (ag : Alias.Graph.t) (cfg : Cfg.t) : Cfg.t =
  LblS.fold
    (fun l cfg ->
      let b = Cfg.block cfg l in

      (* compute liveness at each program point for the block *)
      let lb = Liveness.Graph.uid_out lg l in

      (* compute aliases at each program point for the block *)
      let ab = Alias.Graph.uid_in ag l in

      (* compute optimized block *)
      let b' = dce_block lb ab b in
      Cfg.add_block l b' cfg)
    (Cfg.nodes cfg) cfg
