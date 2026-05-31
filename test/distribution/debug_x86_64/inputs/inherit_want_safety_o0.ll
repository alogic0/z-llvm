source_filename = "inherit_want_safety"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@entry = alias i64 (), ptr @inherit_want_safety.entry

define private i64 @inherit_want_safety.entry() unnamed_addr #0 align 1 {
  %1 = alloca i64, align 8
  %2 = alloca i64, align 8
  store i64 0, ptr %2, align 8
  %3 = load i64, ptr %2, align 8
  %4 = add nuw i64 %3, 1
  store i64 %4, ptr %2, align 8
  %5 = load i64, ptr %2, align 8
  %6 = icmp eq i64 %5, 0
  br i1 %6, label %8, label %11

7:
  br label %14

8:
  %9 = load i64, ptr %2, align 8
  %10 = add nuw i64 %9, 1
  store i64 %10, ptr %2, align 8
  br label %7

11:
  br label %7

12:
  store i64 0, ptr %1, align 8
  %13 = load i64, ptr %2, align 8
  br label %24

14:
  %15 = load i64, ptr %2, align 8
  %16 = icmp eq i64 %15, 0
  br i1 %16, label %18, label %21

17:
  br label %14

18:
  %19 = load i64, ptr %2, align 8
  %20 = add nuw i64 %19, 1
  store i64 %20, ptr %2, align 8
  br label %17

21:
  br label %12

22:
  %23 = load i64, ptr %2, align 8
  switch i64 %23, label %39 [
  ]

24:
  %25 = load i64, ptr %1, align 8
  %26 = icmp ult i64 %25, %13
  br i1 %26, label %29, label %32

27:
  %28 = add nuw i64 %25, 1
  store i64 %28, ptr %1, align 8
  br label %24

29:
  %30 = load i64, ptr %2, align 8
  %31 = add nuw i64 %30, 1
  store i64 %31, ptr %2, align 8
  br label %27

32:
  br label %22

33:
  %34 = load i64, ptr %2, align 8
  %35 = add nuw i64 %34, 1
  store i64 %35, ptr %2, align 8
  %36 = load i64, ptr %2, align 8
  %37 = load i64, ptr %2, align 8
  %38 = add nuw i64 %37, 1
  store i64 %38, ptr %2, align 8
  ret i64 %36

39:
  %40 = load i64, ptr %2, align 8
  %41 = add nuw i64 %40, 1
  store i64 %41, ptr %2, align 8
  br label %33
}

attributes #0 = { nounwind uwtable }
