let max' (x: 'a list) : 'a option =
	match x with
	| [] -> None
	| (h::t) -> Some(List.fold_left max  h t)