type arithm_ast =
	 Int of int
	| Add of arithm_ast * arithm_ast
	| Mul of arithm_ast * arithm_ast;;

type visit_order = Prefix | Infix | Postfix;;

let op_as_string ast =
  match ast with
   | Add (_) -> "+"
   | Mul (_) -> "*"
   | _ -> raise Not_found

let rec as_string (exp:arithm_ast) (order:visit_order) : string =
	match exp with
	| Int i -> string_of_int i
	| Add (x, y) | Mul (x, y) -> let op = op_as_string(exp) in
	  begin match order with
		| Prefix -> op ^ (as_string x order) ^ " " ^ (as_string y order)
		| Infix -> "(" ^ (as_string x order) ^ op ^ (as_string y order) ^ ")"
		| Postfix -> (as_string x order) ^ " " ^ (as_string y order) ^ op
	end;;

let e = Add((Int 5), (Mul (Int 3,  Int 7)));;
print_endline (as_string e Postfix);;