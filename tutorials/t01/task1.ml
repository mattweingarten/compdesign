let rec ackermann (m:int) (n:int) : int =
	if m = 0 				then n+1
	else if n = 0 	then ackermann (m-1) 1
	else 				 		ackermann (m-1) (ackermann m (n-1));;

print_int (ackermann 1 2);; (* 4 *)
