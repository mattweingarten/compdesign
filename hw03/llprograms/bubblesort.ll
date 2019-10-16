@glist = global [10 x i64] [ i64 10, i64 4, i64 6, i64 2, i64 5, i64 1, i64 3, i64 9, i64 7, i64 8 ]

define i64 @is_sorted([10 x i64]* %list) {
  %i1 = add i64 0, 0
  %i2 = add i64 0, 1
  br label %check
check:
  %ptr1 = getelementptr [10 x i64], [10 x i64]* %list, i32 0, i64 %i1
  %ptr2 = getelementptr [10 x i64], [10 x i64]* %list, i32 0, i64 %i2
  %val1 = load i64, i64* %ptr1
  %val2 = load i64, i64* %ptr2
  %not = icmp sgt i64 %val1, %val2
  br i1 %not, label %true, label %false
true:
  ret i64 0
false: 
  %i1 = add i64 %i1, 1
  %i2 = add i64 %i2, 1
  %done = icmp eq i64 %i2, 10
  br i1 %done, label %fin, label %check
fin:
  ret i64 1
}

define i64 @bubblesort([10 x i64]* %list) {
  %i1 = add i64 0, 0
  %i2 = add i64 0, 1
  br label %sort
sort:
  %ptr1 = getelementptr [10 x i64], [10 x i64]* %list, i32 0, i64 %i1
  %ptr2 = getelementptr [10 x i64], [10 x i64]* %list, i32 0, i64 %i2
  %val1 = load i64, i64* %ptr1
  %val2 = load i64, i64* %ptr2
  %should = icmp sgt i64 %val1, %val2
  br i1 %should, label %swap, label %cont
swap:
  store i64 %val1, i64* %ptr2
  store i64 %val2, i64* %ptr1
  br label %cont
cont:
  %i1 = add i64 %i1, 1
  %i2 = add i64 %i2, 1
  %end = icmp eq i64 %i2, 10
  br i1 %end, label %check_sorted, label %sort
check_sorted:
  %sorted = call i64 @is_sorted([10 x i64]* @glist)
  %i1 = add i64 0, 0
  %i2 = add i64 0, 1
  br i1 %sorted, label %end, label %sort
end:
  ret i64 1
}

define i64 @main(i64 %argc, i8** %arcv) {
  %x = call i64 @bubblesort([10 x i64]* @glist)
  ret i64 %x
}