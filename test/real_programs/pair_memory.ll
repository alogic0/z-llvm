target triple = "x86_64-unknown-linux-gnu"
declare i64 @pair_memory_mutate(ptr, i64)

define i64 @pair_memory_capture(ptr %src, ptr %dst, i64 %marker) {
entry:
 %v = load i128, ptr %src, align 1
 %low = trunc i128 %v to i64
 %noise = call i64 @pair_memory_mutate(ptr %src, i64 %marker)
 store i128 %v, ptr %dst, align 1
 %shift = lshr i128 %v, 64
 %high = trunc i128 %shift to i64
 %sum = xor i64 %low, %high
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define i64 @pair_memory_overlap(ptr %src, ptr %dst, i64 %marker) {
entry:
 %v = load i128, ptr %src, align 1
 store i128 %v, ptr %dst, align 1
 %low = trunc i128 %v to i64
 %shift = lshr i128 %v, 64
 %high = trunc i128 %shift to i64
 %sum = xor i64 %low, %high
 %result = xor i64 %sum, %marker
 ret i64 %result
}

define i64 @pair_memory_phi(ptr %a, ptr %b, ptr %dst, i64 %marker) {
entry:
 %x = load i128, ptr %a, align 1
 %y = load i128, ptr %b, align 1
 %flag = and i64 %marker, 1
 %cond = icmp eq i64 %flag, 0
 br i1 %cond, label %left, label %right
left:
 %l = add i128 %x, %y
 br label %join
right:
 %r = sub i128 %x, %y
 br label %join
join:
 %v = phi i128 [ %l, %left ], [ %r, %right ]
 %noise = call i64 @pair_memory_mutate(ptr %a, i64 %marker)
 store i128 %v, ptr %dst, align 1
 %low = trunc i128 %v to i64
 %shift = lshr i128 %v, 64
 %high = trunc i128 %shift to i64
 %sum = xor i64 %low, %high
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define void @pair_memory_literal(ptr %dst) {
entry:
 store i128 -170141183460469231713240559642174554111, ptr %dst, align 1
 ret void
}

define i64 @pair_memory_stack_capture(ptr %src, ptr %dst, i64 %marker) {
entry:
 %slot = alloca i128, align 16
 %input = load i128, ptr %src, align 1
 store i128 %input, ptr %slot, align 16
 %v = load i128, ptr %slot, align 16
 %noise = call i64 @pair_memory_mutate(ptr %slot, i64 %marker)
 store i128 %v, ptr %dst, align 1
 %low = trunc i128 %v to i64
 %shift = lshr i128 %v, 64
 %high = trunc i128 %shift to i64
 %sum = xor i64 %low, %high
 %result = xor i64 %sum, %noise
 ret i64 %result
}
