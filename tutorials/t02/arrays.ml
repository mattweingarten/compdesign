(* array creation *)
let arr1 = [|1;2;3 |];;
let arr2 = Array.make 3 0;; (* [|0;0;0|] *)
let arr3 = Array.init 3 (fun i -> i);; (* [|1;2;3|] *)

(* accessing arrays *)
let v1 = arr1.(0);; (* 1 *)
let v2 = arr1.(5);; (* Exception *)
arr1.(0) <- 4;;
let v3 = arr1.(0);; (* 4 *)

(* important arr functions *)
Array.length arr1;; (* 3 *)
Array.blit arr3 1 arr2 0 2;;
arr3;; (* [|0; 1; 2|] *) 