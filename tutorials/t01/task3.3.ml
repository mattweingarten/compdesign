let rec fold (f:'a -> 'b -> 'a) (acc:'a) (list:'b list) = match list with
	| [] -> acc
	| h::t -> let res = f acc h in
	  fold f res t;;