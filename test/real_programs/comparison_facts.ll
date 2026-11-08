target triple = "x86_64-unknown-linux-gnu"
declare i64 @comparison_clobber(i64)

define i32 @same_direct(i64 %a, i64 %b) {
entry:
  %cmp = icmp samesign ult i64 %a, %b
  %result = zext i1 %cmp to i32
  ret i32 %result
}

define i32 @same_swapped(i64 %a, i64 %b) {
entry:
  %cmp = icmp samesign ult i64 %b, %a
  %result = zext i1 %cmp to i32
  ret i32 %result
}

define i64 @same_phi(i64 %a, i64 %b, i32 %choose) {
entry:
  %flag = icmp ne i32 %choose, 0
  br i1 %flag, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %x = phi i64 [ %a, %left ], [ %b, %right ]
  %y = phi i64 [ %b, %left ], [ %a, %right ]
  %cmp = icmp samesign ult i64 %x, %y
  %bit = zext i1 %cmp to i64
  %weight = mul i64 %x, 17
  %mix = xor i64 %weight, %y
  %result = add i64 %mix, %bit
  ret i64 %result
}

define i64 @same_call(i64 %a, i64 %b) {
entry:
  %first = icmp samesign ult i64 %a, %b
  %called = call i64 @comparison_clobber(i64 %a)
  %second = icmp samesign ult i64 %b, %a
  %one = zext i1 %first to i64
  %two = zext i1 %second to i64
  %weighted = mul i64 %two, 7
  %flags = add i64 %one, %weighted
  %mix = xor i64 %called, %b
  %result = add i64 %mix, %flags
  ret i64 %result
}

define i32 @same_load(ptr %input, ptr %output) {
entry:
  %next = getelementptr i8, ptr %input, i64 8
  %a = load i64, ptr %input, align 1
  %b = load i64, ptr %next, align 1
  %cmp = icmp samesign ult i64 %a, %b
  %bit = zext i1 %cmp to i32
  %mix = xor i64 %a, %b
  store i64 %mix, ptr %output, align 1
  ret i32 %bit
}

define i64 @same_pressure(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %x = xor i64 %a, %c
  %y = add i64 %b, %d
  %z = xor i64 %e, %f
  %called = call i64 @comparison_clobber(i64 %z)
  %cmp = icmp samesign ult i64 %a, %b
  %flag = zext i1 %cmp to i64
  %xy = add i64 %x, %y
  %cz = xor i64 %called, %z
  %cd = add i64 %c, %d
  %ef = xor i64 %e, %f
  %left = add i64 %xy, %cz
  %right = xor i64 %cd, %ef
  %mix = xor i64 %left, %right
  %result = add i64 %mix, %flag
  ret i64 %result
}
