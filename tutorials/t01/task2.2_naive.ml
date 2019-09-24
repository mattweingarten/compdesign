type arithm_ast =
	 Int of int
	| Add of arithm_ast * arithm_ast
	| Mul of arithm_ast * arithm_ast;;

type visit_order = Prefix | Infix | Postfix;;

let rec as_string (exp:arithm_ast) (order:visit_order) : string =
	match exp with
	| Int i -> string_of_int i
	| Add (x, y) ->
	  begin match order with
		| Prefix -> "+" ^ (as_string x order) ^ " " ^ (as_string y order)
		| Infix -> "(" ^ (as_string x order) ^ "+" ^ (as_string y order) ^ ")"
		| Postfix -> (as_string x order) ^ " " ^ (as_string y order) ^ "+"
	  end
  | Mul (x, y) ->
	  begin match order with
		| Prefix -> "*" ^ (as_string x order) ^ " " ^ (as_string y order)
		| Infix -> "(" ^ (as_string x order) ^ "*" ^ (as_string y order) ^ ")"
		| Postfix -> (as_string x order) ^ " " ^ (as_string y order) ^ "*"
	  end;;

let e = Add((Int 5), (Mul (Int 3,  Int 7)));;
print_endline (as_string e Postfix);;