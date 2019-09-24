let rec concat (list: string list) : string = match list with
	| [] -> ""
	| h::[] -> h
	| h::t -> h ^ ", " ^ (concat t);;

print_string (concat ["1"; "2"; "3"]);;