source_filename = "numeric_local_names.ll"
target datalayout = "e-p:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @numeric_external(i32)

; Merging later into entry moves %2 before %1 in the optimizer's IR.
define i32 @numeric_order(i32 %0) {
entry:
  br label %later
earlier:
  %1 = add i32 %2, 3
  ret i32 %1
later:
  %2 = xor i32 %0, 7
  br label %earlier
}

; Block labels consume the same numeric namespace as values.
define i32 @numeric_blocks(i32 %0) {
1:
  br label %4
2:
  %3 = add i32 %5, 3
  ret i32 %3
4:
  %5 = xor i32 %0, 7
  br label %2
}

define i32 @numeric_implicit(i32 %0) {
  %2 = add i32 %0, 1
  ret i32 %2
}

define i32 @numeric_loop(i32 %0) {
1:
  br label %2
2:
  %3 = phi i32 [ 0, %1 ], [ %6, %5 ]
  %4 = icmp ult i32 %3, %0
  br i1 %4, label %5, label %7
5:
  %6 = add i32 %3, 1
  br label %2
7:
  ret i32 %3
}

define i32 @numeric_call(i32 %0) {
entry:
  br label %later
earlier:
  %1 = add i32 %2, 3
  ret i32 %1
later:
  %2 = call i32 @numeric_external(i32 %0)
  br label %earlier
}

define i32 @numeric_switch(i32 %0) {
1:
  switch i32 %0, label %3 [
    i32 0, label %2
  ]
2:
  ret i32 7
3:
  ret i32 9
}
