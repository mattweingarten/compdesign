define i64 @branches(i64 %n) {
  %1 = alloca i64
  store i64 %n, i64* %1
  %2 = load i64, i64* %1
  br label %start
start:
  %3 = icmp sgt i64 %2, 0
  br i1 %3, label %br1, label %exit
exit:
  ret i64 %2 
br1:
  %4 = icmp sgt i64 %2, 1
  br i1 %4, label %br2, label %rec
br2:
  %5 = icmp sgt i64 %2, 2
  br i1 %5, label %br3, label %rec
br6:
  %6 = icmp sgt i64 %2, 6
  br i1 %6, label %br7, label %rec
br5:
  %7 = icmp sgt i64 %2, 5
  br i1 %7, label %br6, label %rec
br3:
  %8 = icmp sgt i64 %2, 3
  br i1 %8, label %br4, label %rec
br4:
  %9 = icmp sgt i64 %2, 4
  br i1 %9, label %br5, label %rec
br7:
  br label %rec
rec:
  %10 = sub i64 %2, 1
  %11 = call i64 @branches(i64 %10)
  ret i64 %11
}

define i64 @main(i64 %argc, i8** %arcv) {
  %1 = call i64 @branches(i64 7)
  ret i64 %1
}