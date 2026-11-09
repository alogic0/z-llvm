target triple = "x86_64-unknown-linux-gnu"
declare i64 @undefined_select_clobber(i64)
declare ptr @undefined_select_pointer_clobber(ptr)

define i64 @undefined_select_1(i64 %a, i64 %b, i64 %flag, ptr %out) {
entry:
 %input = trunc i64 %a to i1
 %condition = icmp ne i64 %flag, 0
 %left = select i1 %condition, i1 undef, i1 %input
 %right = select i1 %condition, i1 %input, i1 poison
 %chosen = select i1 %condition, i1 %right, i1 %left
 %wide = zext i1 %chosen to i64
 store i64 %wide, ptr %out, align 1
 %returned = call i64 @undefined_select_clobber(i64 %wide)
 %result = xor i64 %returned, %b
 ret i64 %result
}

define i64 @undefined_select_8(i64 %a, i64 %b, i64 %flag, ptr %out) {
entry:
 %input = trunc i64 %a to i8
 %condition = icmp ne i64 %flag, 0
 %left = select i1 %condition, i8 undef, i8 %input
 %right = select i1 %condition, i8 %input, i8 poison
 %chosen = select i1 %condition, i8 %right, i8 %left
 %wide = zext i8 %chosen to i64
 store i64 %wide, ptr %out, align 1
 %returned = call i64 @undefined_select_clobber(i64 %wide)
 %result = xor i64 %returned, %b
 ret i64 %result
}

define i64 @undefined_select_16(i64 %a, i64 %b, i64 %flag, ptr %out) {
entry:
 %input = trunc i64 %a to i16
 %condition = icmp ne i64 %flag, 0
 %left = select i1 %condition, i16 undef, i16 %input
 %right = select i1 %condition, i16 %input, i16 poison
 %chosen = select i1 %condition, i16 %right, i16 %left
 %wide = zext i16 %chosen to i64
 store i64 %wide, ptr %out, align 1
 %returned = call i64 @undefined_select_clobber(i64 %wide)
 %result = xor i64 %returned, %b
 ret i64 %result
}

define i64 @undefined_select_32(i64 %a, i64 %b, i64 %flag, ptr %out) {
entry:
 %input = trunc i64 %a to i32
 %condition = icmp ne i64 %flag, 0
 %left = select i1 %condition, i32 undef, i32 %input
 %right = select i1 %condition, i32 %input, i32 poison
 %chosen = select i1 %condition, i32 %right, i32 %left
 %wide = zext i32 %chosen to i64
 store i64 %wide, ptr %out, align 1
 %returned = call i64 @undefined_select_clobber(i64 %wide)
 %result = xor i64 %returned, %b
 ret i64 %result
}

define i64 @undefined_select_64(i64 %a, i64 %b, i64 %flag, ptr %out) {
entry:
 %condition = icmp ne i64 %flag, 0
 %left = select i1 %condition, i64 undef, i64 %a
 %right = select i1 %condition, i64 %a, i64 poison
 %chosen = select i1 %condition, i64 %right, i64 %left
 store i64 %chosen, ptr %out, align 1
 %returned = call i64 @undefined_select_clobber(i64 %chosen)
 %result = xor i64 %returned, %b
 ret i64 %result
}

define i64 @undefined_select_128(i64 %a, i64 %b, i64 %flag, ptr %out) {
entry:
 %low = zext i64 %a to i128
 %high = zext i64 %b to i128
 %shifted = shl i128 %high, 64
 %input = or i128 %low, %shifted
 %condition = icmp ne i64 %flag, 0
 %left = select i1 %condition, i128 undef, i128 %input
 %right = select i1 %condition, i128 %input, i128 poison
 %chosen = select i1 %condition, i128 %right, i128 %left
 store i128 %chosen, ptr %out, align 1
 %upper = lshr i128 %chosen, 64
 %lo = trunc i128 %chosen to i64
 %hi = trunc i128 %upper to i64
 %fold = xor i64 %lo, %hi
 %returned = call i64 @undefined_select_clobber(i64 %fold)
 %result = xor i64 %returned, %b
 ret i64 %result
}

define ptr @undefined_select_pointer(ptr %input, ptr %neighbor, i64 %flag, ptr %out) {
entry:
 %condition = icmp ne i64 %flag, 0
 %left = select i1 %condition, ptr undef, ptr %input
 %right = select i1 %condition, ptr %input, ptr poison
 %chosen = select i1 %condition, ptr %right, ptr %left
 %returned = call ptr @undefined_select_pointer_clobber(ptr %chosen)
 store ptr %returned, ptr %out, align 1
 ret ptr %returned
}
