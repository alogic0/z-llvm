target triple = "x86_64-unknown-linux-gnu"
declare i64 @vector_mask_clobber()
declare i64 @vector_mask_return(i64)

define i32 @vector_mask_compare16(ptr %src, i8 %needle, ptr %out) {
entry:
 %seed = insertelement <1 x i8> poison, i8 %needle, i32 0
 %broadcast = shufflevector <1 x i8> %seed, <1 x i8> poison, <16 x i32> zeroinitializer
 %bytes = load <16 x i8>, ptr %src, align 1
 %same = icmp eq <16 x i8> %bytes, %broadcast
 %mask = bitcast <16 x i1> %same to i16
 store i16 %mask, ptr %out, align 1
 %result = zext i16 %mask to i32
 ret i32 %result
}

define i32 @vector_mask_compare8(ptr %src, i8 %needle, ptr %out) {
entry:
 %seed = insertelement <1 x i8> poison, i8 %needle, i32 0
 %broadcast = shufflevector <1 x i8> %seed, <1 x i8> poison, <8 x i32> zeroinitializer
 %bytes = load <8 x i8>, ptr %src, align 1
 %same = icmp eq <8 x i8> %bytes, %broadcast
 %mask = bitcast <8 x i1> %same to i8
 store i8 %mask, ptr %out, align 1
 %result = zext i8 %mask to i32
 ret i32 %result
}

define i32 @vector_mask_unpack16(i32 %raw, ptr %out) {
entry:
 %mask = trunc i32 %raw to i16
 %bits = bitcast i16 %mask to <16 x i1>
 %bytes = zext <16 x i1> %bits to <16 x i8>
 store <16 x i8> %bytes, ptr %out, align 1
 %back = bitcast <16 x i1> %bits to i16
 %result = zext i16 %back to i32
 ret i32 %result
}

define i64 @vector_mask_nibbles(i64 %raw, ptr %out) {
entry:
 %digits = bitcast i64 %raw to <16 x i4>
 %bytes = zext <16 x i4> %digits to <16 x i8>
 store <16 x i8> %bytes, ptr %out, align 1
 %back = bitcast <16 x i4> %digits to i64
 ret i64 %back
}

define i128 @vector_mask_reverse128(i64 %lo, i64 %hi, ptr %out) {
entry:
 %a = zext i64 %lo to i128
 %b = zext i64 %hi to i128
 %upper = shl i128 %b, 64
 %raw = or i128 %a, %upper
 %words = bitcast i128 %raw to <4 x i32>
 store <4 x i32> %words, ptr %out, align 1
 %reverse = shufflevector <4 x i32> %words, <4 x i32> poison, <4 x i32> <i32 3, i32 2, i32 1, i32 0>
 %back = bitcast <4 x i32> %reverse to i128
 ret i128 %back
}

define i32 @vector_mask_three(i32 %raw, ptr %out) {
entry:
 %mask = trunc i32 %raw to i3
 %bits = bitcast i3 %mask to <3 x i1>
 %bytes = zext <3 x i1> %bits to <3 x i8>
 store <3 x i8> %bytes, ptr %out, align 1
 %back = bitcast <3 x i1> %bits to i3
 %result = zext i3 %back to i32
 ret i32 %result
}

define i64 @vector_mask_live(ptr %left, ptr %right, ptr %out, i64 %live) {
entry:
 %a = load <16 x i8>, ptr %left, align 1
 %b = load <16 x i8>, ptr %right, align 1
 %less = icmp ult <16 x i8> %a, %b
 %noise = call i64 @vector_mask_clobber()
 %mask = bitcast <16 x i1> %less to i16
 store i16 %mask, ptr %out, align 1
 %wide = zext i16 %mask to i64
 %sum = add i64 %wide, %live
 %result = xor i64 %sum, %noise
 ret i64 %result
}

define i64 @vector_mask_reverse8(i64 %raw) {
entry:
 %bytes = bitcast i64 %raw to <8 x i8>
 %reverse = shufflevector <8 x i8> %bytes, <8 x i8> poison, <8 x i32> <i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1, i32 0>
 %back = bitcast <8 x i8> %reverse to i64
 ret i64 %back
}

define i64 @vector_mask_returned8(i64 %raw) {
entry:
 %value = call i64 @vector_mask_return(i64 %raw)
 %bytes = bitcast i64 %value to <8 x i8>
 %reverse = shufflevector <8 x i8> %bytes, <8 x i8> poison, <8 x i32> <i32 7, i32 6, i32 5, i32 4, i32 3, i32 2, i32 1, i32 0>
 %back = bitcast <8 x i8> %reverse to i64
 %result = xor i64 %back, %value
 ret i64 %result
}
