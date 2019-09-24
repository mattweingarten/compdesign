let rec fold (f:'a -> 'b -> 'a) (acc:'a) (list:'b list) = match list with
	| [] -> acc
	| h::t -> let res = f acc h in
	  fold f res t;;

fold (fun x y -> match x with
	| "" -> y
	| _ -> x ^ ", " ^ y)
	"" ["1"; "2"; "3"; "4"];;
fold (fun x y -> x + y) 0 [1; 2; 3; 4];;