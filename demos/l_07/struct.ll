; ModuleID = 'struct.c'
source_filename = "struct.c"
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.14.0"

%struct.Rect = type { %struct.Point, %struct.Point, %struct.Point, %struct.Point }
%struct.Point = type { i64, i64 }

@.str = private unnamed_addr constant [72 x i8] c"RECT: = ll(%llu, %llu), lr(%llu, %llu), ul(%llu, %llu), ur(%llu, %llu)\0A\00", align 1
@.str.1 = private unnamed_addr constant [12 x i8] c"mk_square2\0A\00", align 1
@.str.2 = private unnamed_addr constant [23 x i8] c"sizeof(int64_t) = %lu\0A\00", align 1
@.str.3 = private unnamed_addr constant [28 x i8] c"sizeof(struct Point) = %lu\0A\00", align 1
@.str.4 = private unnamed_addr constant [11 x i8] c"size: %lu\0A\00", align 1
@.str.5 = private unnamed_addr constant [11 x i8] c"mk_square\0A\00", align 1

; Function Attrs: noinline nounwind optnone ssp
define void @mk_square(%struct.Rect* noalias sret, i64, i64, i64) #0 {
  %5 = alloca %struct.Point, align 8
  %6 = alloca i64, align 8
  %7 = bitcast %struct.Point* %5 to { i64, i64 }*
  %8 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %7, i32 0, i32 0
  store i64 %1, i64* %8, align 8
  %9 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %7, i32 0, i32 1
  store i64 %2, i64* %9, align 8
  store i64 %3, i64* %6, align 8
  %10 = getelementptr inbounds %struct.Point, %struct.Point* %5, i32 0, i32 0
  store i64 3, i64* %10, align 8
  %11 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 0
  %12 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 1
  %13 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 2
  %14 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 3
  %15 = bitcast %struct.Point* %14 to i8*
  %16 = bitcast %struct.Point* %5 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %15, i8* align 8 %16, i64 16, i1 false)
  %17 = bitcast %struct.Point* %13 to i8*
  %18 = bitcast %struct.Point* %14 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %17, i8* align 8 %18, i64 16, i1 false)
  %19 = bitcast %struct.Point* %12 to i8*
  %20 = bitcast %struct.Point* %13 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %19, i8* align 8 %20, i64 16, i1 false)
  %21 = bitcast %struct.Point* %11 to i8*
  %22 = bitcast %struct.Point* %12 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %21, i8* align 8 %22, i64 16, i1 false)
  %23 = load i64, i64* %6, align 8
  %24 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 1
  %25 = getelementptr inbounds %struct.Point, %struct.Point* %24, i32 0, i32 0
  %26 = load i64, i64* %25, align 8
  %27 = add nsw i64 %26, %23
  store i64 %27, i64* %25, align 8
  %28 = load i64, i64* %6, align 8
  %29 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 2
  %30 = getelementptr inbounds %struct.Point, %struct.Point* %29, i32 0, i32 1
  %31 = load i64, i64* %30, align 8
  %32 = add nsw i64 %31, %28
  store i64 %32, i64* %30, align 8
  %33 = load i64, i64* %6, align 8
  %34 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 3
  %35 = getelementptr inbounds %struct.Point, %struct.Point* %34, i32 0, i32 0
  %36 = load i64, i64* %35, align 8
  %37 = add nsw i64 %36, %33
  store i64 %37, i64* %35, align 8
  %38 = load i64, i64* %6, align 8
  %39 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 3
  %40 = getelementptr inbounds %struct.Point, %struct.Point* %39, i32 0, i32 1
  %41 = load i64, i64* %40, align 8
  %42 = add nsw i64 %41, %38
  store i64 %42, i64* %40, align 8
  ret void
}

; Function Attrs: argmemonly nounwind
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1) #1

; Function Attrs: noinline nounwind optnone ssp
define void @mk_square2(%struct.Point*, i64, %struct.Rect*) #0 {
  %4 = alloca %struct.Point*, align 8
  %5 = alloca i64, align 8
  %6 = alloca %struct.Rect*, align 8
  store %struct.Point* %0, %struct.Point** %4, align 8
  store i64 %1, i64* %5, align 8
  store %struct.Rect* %2, %struct.Rect** %6, align 8
  %7 = load %struct.Rect*, %struct.Rect** %6, align 8
  %8 = getelementptr inbounds %struct.Rect, %struct.Rect* %7, i32 0, i32 1
  %9 = load %struct.Rect*, %struct.Rect** %6, align 8
  %10 = getelementptr inbounds %struct.Rect, %struct.Rect* %9, i32 0, i32 2
  %11 = load %struct.Rect*, %struct.Rect** %6, align 8
  %12 = getelementptr inbounds %struct.Rect, %struct.Rect* %11, i32 0, i32 3
  %13 = load %struct.Rect*, %struct.Rect** %6, align 8
  %14 = getelementptr inbounds %struct.Rect, %struct.Rect* %13, i32 0, i32 0
  %15 = load %struct.Point*, %struct.Point** %4, align 8
  %16 = bitcast %struct.Point* %14 to i8*
  %17 = bitcast %struct.Point* %15 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %16, i8* align 8 %17, i64 16, i1 false)
  %18 = bitcast %struct.Point* %12 to i8*
  %19 = bitcast %struct.Point* %14 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %18, i8* align 8 %19, i64 16, i1 false)
  %20 = bitcast %struct.Point* %10 to i8*
  %21 = bitcast %struct.Point* %12 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %20, i8* align 8 %21, i64 16, i1 false)
  %22 = bitcast %struct.Point* %8 to i8*
  %23 = bitcast %struct.Point* %10 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 8 %22, i8* align 8 %23, i64 16, i1 false)
  %24 = load i64, i64* %5, align 8
  %25 = load %struct.Rect*, %struct.Rect** %6, align 8
  %26 = getelementptr inbounds %struct.Rect, %struct.Rect* %25, i32 0, i32 1
  %27 = getelementptr inbounds %struct.Point, %struct.Point* %26, i32 0, i32 0
  %28 = load i64, i64* %27, align 8
  %29 = add nsw i64 %28, %24
  store i64 %29, i64* %27, align 8
  %30 = load i64, i64* %5, align 8
  %31 = load %struct.Rect*, %struct.Rect** %6, align 8
  %32 = getelementptr inbounds %struct.Rect, %struct.Rect* %31, i32 0, i32 3
  %33 = getelementptr inbounds %struct.Point, %struct.Point* %32, i32 0, i32 0
  %34 = load i64, i64* %33, align 8
  %35 = add nsw i64 %34, %30
  store i64 %35, i64* %33, align 8
  %36 = load i64, i64* %5, align 8
  %37 = load %struct.Rect*, %struct.Rect** %6, align 8
  %38 = getelementptr inbounds %struct.Rect, %struct.Rect* %37, i32 0, i32 3
  %39 = getelementptr inbounds %struct.Point, %struct.Point* %38, i32 0, i32 1
  %40 = load i64, i64* %39, align 8
  %41 = add nsw i64 %40, %36
  store i64 %41, i64* %39, align 8
  %42 = load i64, i64* %5, align 8
  %43 = load %struct.Rect*, %struct.Rect** %6, align 8
  %44 = getelementptr inbounds %struct.Rect, %struct.Rect* %43, i32 0, i32 2
  %45 = getelementptr inbounds %struct.Point, %struct.Point* %44, i32 0, i32 1
  %46 = load i64, i64* %45, align 8
  %47 = add nsw i64 %46, %42
  store i64 %47, i64* %45, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp
define void @print_rect(%struct.Rect* byval align 8) #0 {
  %2 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 0
  %3 = getelementptr inbounds %struct.Point, %struct.Point* %2, i32 0, i32 0
  %4 = load i64, i64* %3, align 8
  %5 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 0
  %6 = getelementptr inbounds %struct.Point, %struct.Point* %5, i32 0, i32 1
  %7 = load i64, i64* %6, align 8
  %8 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 1
  %9 = getelementptr inbounds %struct.Point, %struct.Point* %8, i32 0, i32 0
  %10 = load i64, i64* %9, align 8
  %11 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 1
  %12 = getelementptr inbounds %struct.Point, %struct.Point* %11, i32 0, i32 1
  %13 = load i64, i64* %12, align 8
  %14 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 2
  %15 = getelementptr inbounds %struct.Point, %struct.Point* %14, i32 0, i32 0
  %16 = load i64, i64* %15, align 8
  %17 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 2
  %18 = getelementptr inbounds %struct.Point, %struct.Point* %17, i32 0, i32 1
  %19 = load i64, i64* %18, align 8
  %20 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 3
  %21 = getelementptr inbounds %struct.Point, %struct.Point* %20, i32 0, i32 0
  %22 = load i64, i64* %21, align 8
  %23 = getelementptr inbounds %struct.Rect, %struct.Rect* %0, i32 0, i32 3
  %24 = getelementptr inbounds %struct.Point, %struct.Point* %23, i32 0, i32 1
  %25 = load i64, i64* %24, align 8
  %26 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([72 x i8], [72 x i8]* @.str, i32 0, i32 0), i64 %4, i64 %7, i64 %10, i64 %13, i64 %16, i64 %19, i64 %22, i64 %25)
  ret void
}

declare i32 @printf(i8*, ...) #2

; Function Attrs: noinline nounwind optnone ssp
define void @foo() #0 {
  %1 = alloca %struct.Point, align 8
  %2 = alloca %struct.Rect, align 8
  %3 = bitcast %struct.Point* %1 to i8*
  call void @llvm.memset.p0i8.i64(i8* align 8 %3, i8 0, i64 16, i1 false)
  call void @mk_square2(%struct.Point* %1, i64 1, %struct.Rect* %2)
  %4 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.1, i32 0, i32 0))
  call void @print_rect(%struct.Rect* byval align 8 %2)
  ret void
}

; Function Attrs: argmemonly nounwind
declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i1) #1

; Function Attrs: noinline nounwind optnone ssp
define i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca %struct.Point, align 8
  %3 = alloca %struct.Rect, align 8
  store i32 0, i32* %1, align 4
  %4 = getelementptr inbounds %struct.Point, %struct.Point* %2, i32 0, i32 0
  store i64 0, i64* %4, align 8
  %5 = getelementptr inbounds %struct.Point, %struct.Point* %2, i32 0, i32 1
  store i64 0, i64* %5, align 8
  %6 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([23 x i8], [23 x i8]* @.str.2, i32 0, i32 0), i64 8)
  %7 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([28 x i8], [28 x i8]* @.str.3, i32 0, i32 0), i64 16)
  %8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @.str.4, i32 0, i32 0), i64 40)
  %9 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @.str.5, i32 0, i32 0))
  %10 = bitcast %struct.Point* %2 to { i64, i64 }*
  %11 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %10, i32 0, i32 0
  %12 = load i64, i64* %11, align 8
  %13 = getelementptr inbounds { i64, i64 }, { i64, i64 }* %10, i32 0, i32 1
  %14 = load i64, i64* %13, align 8
  call void @mk_square(%struct.Rect* sret %3, i64 %12, i64 %14, i64 3)
  call void @print_rect(%struct.Rect* byval align 8 %3)
  call void @foo()
  ret i32 0
}

attributes #0 = { noinline nounwind optnone ssp "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind }
attributes #2 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cx16,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 10, i32 14]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"PIC Level", i32 2}
!3 = !{!"Apple clang version 11.0.0 (clang-1100.0.33.8)"}
