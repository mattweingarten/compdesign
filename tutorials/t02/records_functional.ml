type person = {
	name : string;
	hobbies : string list;
};;

let manuel = {
	name = "manuel";
	hobbies = ["hiking"; "table tennis"]	
};;

let print_person (p: person) =
	print_string @@ "name: " ^ p.name ^ "\n";
	print_string @@ "hobbies: " ^ String.concat ", " p. hobbies ^ "\n";;

let add_hobby hobby p =
	{
		name = p.name; (* p with *)
		hobbies = hobby :: p.hobbies;
	};;

let manuel' = add_hobby "compilers" manuel;;
print_person manuel'