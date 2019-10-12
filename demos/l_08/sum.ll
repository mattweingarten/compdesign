define i32 @sum(i32 %n) {
  %cmp = icmp eq i32 %n, 0
  br i1 %cmp, label %base_case, label %recursive_case

base_case:
  ret i32 0

recursive_case:
  %n_minus_one = sub i32 %n, 1
  %result = call i32 @sum(i32 %n_minus_one)
  %sum = add i32 %result, %n
  ret i32 %sum
}
