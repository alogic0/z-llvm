target triple = "x86_64-unknown-linux-gnu"

define i64 @byte_copy_loop(ptr %d, ptr %s, i64 %n) {
entry:
  %empty = icmp eq i64 %n, 0
  br i1 %empty, label %done, label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %sp = getelementptr i8, ptr %s, i64 %i
  %v = load i8, ptr %sp, align 1
  %dp = getelementptr i8, ptr %d, i64 %i
  store i8 %v, ptr %dp, align 1
  %next = add i64 %i, 1
  %end = icmp eq i64 %next, %n
  br i1 %end, label %done, label %loop
done:
  ret i64 %n
}

define i64 @byte_sum_loop(ptr %s, i64 %n, i64 %seed) {
entry:
  %empty = icmp eq i64 %n, 0
  br i1 %empty, label %done, label %loop
done:
  %r = phi i64 [ %seed, %entry ], [ %total, %loop ]
  ret i64 %r
loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %sum = phi i64 [ %seed, %entry ], [ %total, %loop ]
  %p = getelementptr i8, ptr %s, i64 %i
  %v = load i8, ptr %p, align 1
  %wide = zext i8 %v to i64
  %total = add i64 %sum, %wide
  %next = add i64 %i, 1
  %end = icmp eq i64 %next, %n
  br i1 %end, label %done, label %loop
}

define i64 @byte_find_zero(ptr %s, i64 %n) {
entry:
  %empty = icmp eq i64 %n, 0
  br i1 %empty, label %missing, label %loop
found:
  ret i64 %i
missing:
  ret i64 %n
loop:
  %i = phi i64 [ 0, %entry ], [ %next, %advance ]
  %p = getelementptr i8, ptr %s, i64 %i
  %v = load i8, ptr %p, align 1
  %zero = icmp eq i8 %v, 0
  br i1 %zero, label %found, label %advance
advance:
  %next = add i64 %i, 1
  %end = icmp eq i64 %next, %n
  br i1 %end, label %missing, label %loop
}

define void @byte_fill_loop(ptr %d, i64 %n) {
entry:
  %empty = icmp eq i64 %n, 0
  br i1 %empty, label %done, label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %next, %loop ]
  %p = getelementptr i8, ptr %d, i64 %i
  store i8 231, ptr %p, align 1
  %next = add i64 %i, 1
  %end = icmp eq i64 %next, %n
  br i1 %end, label %done, label %loop
done:
  ret void
}
