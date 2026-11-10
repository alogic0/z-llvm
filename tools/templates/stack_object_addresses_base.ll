define i64 @stack_window(ptr %out, i64 %value, i64 %offset, i64 %length, i64 %seed) {
entry:
 %slot = alloca i64, align 8
 store i64 %value, ptr %slot, align 8
 %start = getelementptr inbounds [1 x i8], ptr %slot, i64 %offset
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %start, i64 %length, i1 false)
 %read = load i64, ptr %slot, align 8
 %r = xor i64 %read, %seed
 ret i64 %r
}
define i64 @stack_move(ptr %out, ptr %input, i64 %offset, i64 %length, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 64, i1 false)
 %start = getelementptr i8, ptr %slot, i64 %offset
 %direction = trunc i64 %seed to i1
 br i1 %direction, label %forward, label %backward
forward:
 call void @llvm.memmove.p0.p0.i64(ptr %start, ptr %slot, i64 %length, i1 false)
 br label %exit
backward:
 call void @llvm.memmove.p0.p0.i64(ptr %slot, ptr %start, i64 %length, i1 false)
 br label %exit
exit:
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 64, i1 false)
 %r = xor i64 %seed, %length
 ret i64 %r
}
define i64 @stack_call_array(ptr %input, ptr %out, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 64, i1 false)
 %value = call i64 @stack_object_touch(ptr %slot, i64 %seed)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 64, i1 false)
 %r = xor i64 %value, %seed
 ret i64 %r
}
define i64 @stack_call_bool(ptr %input, ptr %out, i64 %seed) {
entry:
 %slot = alloca [16 x i32], align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 64, i1 false)
 %value = call i1 @stack_object_predicate(ptr %slot, i64 %seed)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 64, i1 false)
 %wide = zext i1 %value to i64
 %r = xor i64 %wide, %seed
 ret i64 %r
}
