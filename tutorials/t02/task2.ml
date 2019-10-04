let rec bin_search (arr: 'a array) (elem: 'a) (left:int) (right:int) : int =
	assert (left >= 0 && right < Array.length arr);
	if left > right then
		raise Not_found
	else
		let mid = (left + right) / 2 in
		if arr.(mid) > elem then
			bin_search arr elem left (mid - 1)
		else if elem > arr.(mid) then
			bin_search arr elem (mid+1) right
		else 
				(assert(arr.(mid) = elem); mid);;

let arr = Array.init 10 (fun _ -> Random.int 100);;
Array.sort compare arr;;
print_int @@ bin_search arr arr.(5) 0 @@ Array.length arr -1;; (* 5 *)
bin_search arr 101 0 @@ Array.length arr - 1;; (* Exception: Not_found *)
