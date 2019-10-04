type person = {
	mutable name : string;
	mutable hobbies : string list;
};;

let manuel = {
	name = "manuel";
	hobbies = ["hiking"; "table tennis"]	
};;

let print_person (p: person) =
	print_string @@ "name: " ^ p.name ^ "\n";
	print_string @@ "hobbies: " ^ String.concat ", " p. hobbies ^ "\n";;

let add_hobby hobby p =
	p.hobbies <- hobby :: p.hobbies;;

add_hobby "compilers" manuel;;
print_person manuel;;