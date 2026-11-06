target triple = "x86_64-unknown-linux-gnu"
declare i64 @aligned_stack_fill(ptr, ptr, i64, i64, i64)

define i64 @aligned_stack_32(i64 %seed) {
entry:
 %p = alloca [3 x i8], align 32
 %q = alloca [3 x i8], align 32
 %noise = call i64 @aligned_stack_fill(ptr %p, ptr %q, i64 3, i64 32, i64 %seed)
 %p_last = getelementptr i8, ptr %p, i64 2
 %q_last = getelementptr i8, ptr %q, i64 2
 %a = load i8, ptr %p, align 1
 %b = load i8, ptr %q, align 1
 %c = load i8, ptr %p_last, align 1
 %d = load i8, ptr %q_last, align 1
 %aa = zext i8 %a to i64
 %bb = zext i8 %b to i64
 %cc = zext i8 %c to i64
 %dd = zext i8 %d to i64
 %ab = add i64 %aa, %bb
 %cd = add i64 %cc, %dd
 %sum = add i64 %ab, %cd
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define i64 @aligned_stack_64(i64 %seed) {
entry:
 %p = alloca [17 x i8], align 64
 %q = alloca [17 x i8], align 64
 %noise = call i64 @aligned_stack_fill(ptr %p, ptr %q, i64 17, i64 64, i64 %seed)
 %p_last = getelementptr i8, ptr %p, i64 16
 %q_last = getelementptr i8, ptr %q, i64 16
 %a = load i8, ptr %p, align 1
 %b = load i8, ptr %q, align 1
 %c = load i8, ptr %p_last, align 1
 %d = load i8, ptr %q_last, align 1
 %aa = zext i8 %a to i64
 %bb = zext i8 %b to i64
 %cc = zext i8 %c to i64
 %dd = zext i8 %d to i64
 %ab = add i64 %aa, %bb
 %cd = add i64 %cc, %dd
 %sum = add i64 %ab, %cd
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define i64 @aligned_stack_128(i64 %seed) {
entry:
 %p = alloca [65 x i8], align 128
 %q = alloca [65 x i8], align 128
 %noise = call i64 @aligned_stack_fill(ptr %p, ptr %q, i64 65, i64 128, i64 %seed)
 %p_last = getelementptr i8, ptr %p, i64 64
 %q_last = getelementptr i8, ptr %q, i64 64
 %a = load i8, ptr %p, align 1
 %b = load i8, ptr %q, align 1
 %c = load i8, ptr %p_last, align 1
 %d = load i8, ptr %q_last, align 1
 %aa = zext i8 %a to i64
 %bb = zext i8 %b to i64
 %cc = zext i8 %c to i64
 %dd = zext i8 %d to i64
 %ab = add i64 %aa, %bb
 %cd = add i64 %cc, %dd
 %sum = add i64 %ab, %cd
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define i64 @aligned_stack_256(i64 %seed) {
entry:
 %p = alloca [129 x i8], align 256
 %q = alloca [129 x i8], align 256
 %noise = call i64 @aligned_stack_fill(ptr %p, ptr %q, i64 129, i64 256, i64 %seed)
 %p_last = getelementptr i8, ptr %p, i64 128
 %q_last = getelementptr i8, ptr %q, i64 128
 %a = load i8, ptr %p, align 1
 %b = load i8, ptr %q, align 1
 %c = load i8, ptr %p_last, align 1
 %d = load i8, ptr %q_last, align 1
 %aa = zext i8 %a to i64
 %bb = zext i8 %b to i64
 %cc = zext i8 %c to i64
 %dd = zext i8 %d to i64
 %ab = add i64 %aa, %bb
 %cd = add i64 %cc, %dd
 %sum = add i64 %ab, %cd
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define i64 @aligned_stack_1024(i64 %seed) {
entry:
 %p = alloca [257 x i8], align 1024
 %q = alloca [257 x i8], align 1024
 %noise = call i64 @aligned_stack_fill(ptr %p, ptr %q, i64 257, i64 1024, i64 %seed)
 %p_last = getelementptr i8, ptr %p, i64 256
 %q_last = getelementptr i8, ptr %q, i64 256
 %a = load i8, ptr %p, align 1
 %b = load i8, ptr %q, align 1
 %c = load i8, ptr %p_last, align 1
 %d = load i8, ptr %q_last, align 1
 %aa = zext i8 %a to i64
 %bb = zext i8 %b to i64
 %cc = zext i8 %c to i64
 %dd = zext i8 %d to i64
 %ab = add i64 %aa, %bb
 %cd = add i64 %cc, %dd
 %sum = add i64 %ab, %cd
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define i64 @aligned_stack_4096(i64 %seed) {
entry:
 %p = alloca [257 x i8], align 4096
 %q = alloca [257 x i8], align 4096
 %noise = call i64 @aligned_stack_fill(ptr %p, ptr %q, i64 257, i64 4096, i64 %seed)
 %p_last = getelementptr i8, ptr %p, i64 256
 %q_last = getelementptr i8, ptr %q, i64 256
 %a = load i8, ptr %p, align 1
 %b = load i8, ptr %q, align 1
 %c = load i8, ptr %p_last, align 1
 %d = load i8, ptr %q_last, align 1
 %aa = zext i8 %a to i64
 %bb = zext i8 %b to i64
 %cc = zext i8 %c to i64
 %dd = zext i8 %d to i64
 %ab = add i64 %aa, %bb
 %cd = add i64 %cc, %dd
 %sum = add i64 %ab, %cd
 %result = xor i64 %sum, %noise
 ret i64 %result
}
