define i32 @cse_sibling(ptr %p, i1 %cond) {
entry:
  store i32 1, ptr %p
  br i1 %cond, label %left, label %right
left:
  store i32 2, ptr %p
  ret i32 2
right:
  %x = load i32, ptr %p
  ret i32 %x
}

define i32 @cse_join(ptr %p, i1 %cond) {
entry:
  store i32 1, ptr %p
  br i1 %cond, label %left, label %right
left:
  store i32 2, ptr %p
  br label %join
right:
  br label %join
join:
  %x = load i32, ptr %p
  ret i32 %x
}

define i32 @cse_loop(ptr %p, i32 %n) {
entry:
  store i32 1, ptr %p
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %x = load i32, ptr %p
  store i32 2, ptr %p
  %next = add i32 %i, 1
  %done = icmp eq i32 %next, %n
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %x
}

define i8 @signed_div() {
entry:
  %t = trunc i32 -2 to i8
  %x = sdiv i8 %t, 2
  ret i8 %x
}

define i8 @signed_rem() {
entry:
  %x = srem i8 253, 2
  ret i8 %x
}

define i128 @wide_mul() {
entry:
  %x = mul i128 18446744073709551616, 18446744073709551616
  ret i128 %x
}

define i128 @wide_add() {
entry:
  %x = add i128 170141183460469231731687303715884105727, 1
  ret i128 %x
}

define i128 @wide_sub() {
entry:
  %x = sub i128 -170141183460469231731687303715884105728, 1
  ret i128 %x
}

define i64 @unsigned_spelling_mul() {
entry:
  %x = mul i64 18446744073709551615, 18446744073709551615
  ret i64 %x
}

define i32 @licm_counter(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %next = add i32 %i, 1
  %done = icmp eq i32 %next, %n
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %next
}

define i32 @licm_load(ptr %p, i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %q = getelementptr i32, ptr %p, i32 %i
  %x = load i32, ptr %q
  %next = add i32 %i, 1
  %done = icmp eq i32 %next, %n
  br i1 %done, label %exit, label %loop
exit:
  store i32 99, ptr %p
  ret i32 %x
}


declare i32 @optimizer_observe(i32, i32)

define i32 @sccp_loop_argument(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %v = call i32 @optimizer_observe(i32 %i, i32 7)
  %next = add i32 %i, 1
  %done = icmp eq i32 %next, %n
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %v
}

define i32 @signed_compare_bitpattern() {
entry:
  %c = icmp slt i8 255, 0
  %r = zext i1 %c to i32
  ret i32 %r
}

define i32 @equal_compare_bitpattern() {
entry:
  %c = icmp eq i8 255, -1
  %r = zext i1 %c to i32
  ret i32 %r
}

define i32 @unsigned_compare_wide() {
entry:
  %c = icmp ugt i128 -1, 170141183460469231731687303715884105727
  %r = zext i1 %c to i32
  ret i32 %r
}

@escaped_cell = internal global i32 1
@escaped_pointer = global ptr @escaped_cell

define i32 @global_indirect_write(i32 %new) {
entry:
  %p = load ptr, ptr @escaped_pointer
  store i32 %new, ptr %p
  %v = load i32, ptr @escaped_cell
  ret i32 %v
}
