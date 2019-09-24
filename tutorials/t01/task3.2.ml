let rec concat' (list: string list) (acc:string) : string = match list with
	| [] -> acc
	| h::[] -> acc ^ h
	| h::t -> concat' t (acc ^ h ^ ", ");;
	

print_string (concat' ["1"; "2"; "3"] "");;