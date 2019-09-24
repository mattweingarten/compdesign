type arithm_ast =
	 Int of int
	| Add of arithm_ast * arithm_ast
	| Mul of arithm_ast * arithm_ast;;

type visit_order = Prefix | Infix | Postfix;;