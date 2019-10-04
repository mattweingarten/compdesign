let rec fibo i =
	assert(i >= 0);
	Printf.printf "called with %d\n" i;
	match i with
	| 0 | 1 -> i
	| _ -> (fibo i -1) + (fibo i -2);;
