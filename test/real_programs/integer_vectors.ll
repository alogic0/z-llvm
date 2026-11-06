target triple = "x86_64-unknown-linux-gnu"
declare i1 @llvm.vector.reduce.or.v16i1(<16 x i1>)
declare i1 @llvm.vector.reduce.or.v8i1(<8 x i1>)
declare i4 @llvm.vector.reduce.umin.v16i4(<16 x i4>)
declare i5 @llvm.vector.reduce.add.v16i5(<16 x i5>)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>)
declare i64 @integer_vector_clobber(ptr)

define i32 @integer_vector_find8(ptr %src, i8 %needle, ptr %out) {
entry:
 %seed = insertelement <1 x i8> poison, i8 %needle, i32 0
 %broadcast = shufflevector <1 x i8> %seed, <1 x i8> poison, <8 x i32> zeroinitializer
 %bytes = load <8 x i8>, ptr %src, align 1
 %same = icmp eq <8 x i8> %bytes, %broadcast
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %same)
 store <8 x i1> %same, ptr %out, align 1
 %result = zext i1 %any to i32
 ret i32 %result
}

define i32 @integer_vector_find16(ptr %src, i8 %needle, ptr %out) {
entry:
 %seed = insertelement <1 x i8> poison, i8 %needle, i32 0
 %broadcast = shufflevector <1 x i8> %seed, <1 x i8> poison, <16 x i32> zeroinitializer
 %bytes = load <16 x i8>, ptr %src, align 1
 %same = icmp eq <16 x i8> %bytes, %broadcast
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %same)
 store <16 x i1> %same, ptr %out, align 1
 %result = zext i1 %any to i32
 ret i32 %result
}

define i32 @integer_vector_first16(i16 %mask) {
entry:
 %slot = alloca <16 x i1>, align 2
 store i16 %mask, ptr %slot, align 2
 %bits = load <16 x i1>, ptr %slot, align 2
 %indices = select <16 x i1> %bits, <16 x i4> <i4 0, i4 1, i4 2, i4 3, i4 4, i4 5, i4 6, i4 7, i4 8, i4 9, i4 10, i4 11, i4 12, i4 13, i4 14, i4 15>, <16 x i4> splat (i4 -1)
 %first = call i4 @llvm.vector.reduce.umin.v16i4(<16 x i4> %indices)
 %result = zext i4 %first to i32
 ret i32 %result
}
define i32 @integer_vector_count16(i16 %mask) {
entry:
 %slot = alloca <16 x i1>, align 2
 store i16 %mask, ptr %slot, align 2
 %bits = load <16 x i1>, ptr %slot, align 2
 %ones = select <16 x i1> %bits, <16 x i5> splat (i5 1), <16 x i5> zeroinitializer
 %sum = call i5 @llvm.vector.reduce.add.v16i5(<16 x i5> %ones)
 %result = zext i5 %sum to i32
 ret i32 %result
}
define i64 @integer_vector_arithmetic(ptr %a, ptr %b, ptr %out) {
entry:
 %x = load <4 x i32>, ptr %a, align 1
 %y = load <4 x i32>, ptr %b, align 1
 %sum = add <4 x i32> %x, %y
 %shifted = lshr <4 x i32> %sum, <i32 0, i32 1, i32 7, i32 31>
 %value = xor <4 x i32> %shifted, %x
 %noise = call i64 @integer_vector_clobber(ptr %a)
 store <4 x i32> %value, ptr %out, align 1
 %fold = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %value)
 %wide = zext i32 %fold to i64
 %result = xor i64 %wide, %noise
 ret i64 %result
}
define void @integer_vector_shuffle(ptr %a, ptr %b, ptr %out) {
entry:
 %x = load <16 x i8>, ptr %a, align 1
 %y = load <16 x i8>, ptr %b, align 1
 %mixed = shufflevector <16 x i8> %x, <16 x i8> %y, <16 x i32> <i32 0, i32 17, i32 2, i32 19, i32 4, i32 21, i32 6, i32 23, i32 8, i32 25, i32 10, i32 27, i32 12, i32 29, i32 14, i32 31>
 %words = bitcast <16 x i8> %mixed to <4 x i32>
 store <4 x i32> %words, ptr %out, align 1
 ret void
}

define i32 @integer_vector_update(ptr %src, ptr %out, i32 %index, i8 %byte) {
entry:
 %v = load <16 x i8>, ptr %src, align 1
 %changed = insertelement <16 x i8> %v, i8 %byte, i32 %index
 store <16 x i8> %changed, ptr %out, align 1
 %other = xor i32 %index, 15
 %picked = extractelement <16 x i8> %changed, i32 %other
 %wide = zext i8 %picked to i32
 ret i32 %wide
}
define i32 @integer_vector_build_loop(ptr %src, ptr %out) {
entry:
 %slot = alloca <16 x i8>, align 16
 store <16 x i8> zeroinitializer, ptr %slot, align 16
 br label %loop
loop:
 %i = phi i64 [ 0, %entry ], [ %next, %loop ]
 %p = getelementptr i8, ptr %src, i64 %i
 %byte = load i8, ptr %p, align 1
 %old = load <16 x i8>, ptr %slot, align 16
 %new = insertelement <16 x i8> %old, i8 %byte, i64 %i
 store <16 x i8> %new, ptr %slot, align 16
 %next = add i64 %i, 1
 %more = icmp ult i64 %next, 16
 br i1 %more, label %loop, label %exit
exit:
 %v = load <16 x i8>, ptr %slot, align 16
 store <16 x i8> %v, ptr %out, align 1
 %a = extractelement <16 x i8> %v, i32 0
 %b = extractelement <16 x i8> %v, i32 15
 %sum = add i8 %a, %b
 %wide = zext i8 %sum to i32
 ret i32 %wide
}
