target triple = "x86_64-unknown-linux-gnu"
declare i64 @llvm.vector.reduce.add.v4i64(<4 x i64>)
declare i64 @llvm.vector.reduce.add.v6i64(<6 x i64>)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>)
declare <4 x i32> @llvm.fshl.v4i32(<4 x i32>, <4 x i32>, <4 x i32>)
declare <4 x i32> @llvm.bswap.v4i32(<4 x i32>)
declare <4 x i32> @llvm.ctpop.v4i32(<4 x i32>)
declare <6 x i64> @llvm.ctpop.v6i64(<6 x i64>)
declare <4 x i32> @llvm.usub.sat.v4i32(<4 x i32>, <4 x i32>)
; The scalar declarations also type-check the private per-lane graph.
declare i32 @llvm.fshl.i32(i32, i32, i32)
declare i32 @llvm.bswap.i32(i32)
declare i32 @llvm.ctpop.i32(i32)
declare i64 @llvm.ctpop.i64(i64)
declare i32 @llvm.usub.sat.i32(i32, i32)

define i64 @vector_graph_phi8(ptr %src, ptr %out, i32 %count, i64 %live) {
entry:
 %initial = load <8 x i8>, ptr %src, align 1
 br label %loop
loop:
 %i = phi i32 [ 0, %entry ], [ %next, %loop ]
 %value = phi <8 x i8> [ %initial, %entry ], [ %changed, %loop ]
 %rotated = shufflevector <8 x i8> %value, <8 x i8> poison, <8 x i32> <i32 7, i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6>
 %changed = xor <8 x i8> %rotated, splat (i8 -91)
 %next = add i32 %i, 1
 %more = icmp ult i32 %next, %count
 br i1 %more, label %loop, label %exit
exit:
 store <8 x i8> %changed, ptr %out, align 1
 %bits = bitcast <8 x i8> %changed to i64
 %result = xor i64 %bits, %live
 ret i64 %result
}

define i64 @vector_graph_parallel(ptr %src, ptr %out, i32 %count) {
entry:
 %second_ptr = getelementptr i8, ptr %src, i64 16
 %first = load <2 x i64>, ptr %src, align 1
 %second = load <2 x i64>, ptr %second_ptr, align 1
 br label %loop
loop:
 %i = phi i32 [ 0, %entry ], [ %next, %loop ]
 %a = phi <2 x i64> [ %first, %entry ], [ %b, %loop ]
 %b = phi <2 x i64> [ %second, %entry ], [ %a, %loop ]
 %next = add i32 %i, 1
 %more = icmp ult i32 %next, %count
 br i1 %more, label %loop, label %exit
exit:
 %upper = getelementptr i8, ptr %out, i64 16
 store <2 x i64> %a, ptr %out, align 1
 store <2 x i64> %b, ptr %upper, align 1
 %lo = extractelement <2 x i64> %a, i32 0
 %hi = extractelement <2 x i64> %b, i32 1
 %result = xor i64 %lo, %hi
 ret i64 %result
}

define i64 @vector_graph_wide(ptr %left, ptr %right, ptr %out) {
entry:
 %a = load <4 x i64>, ptr %left, align 1
 %b = load <4 x i64>, ptr %right, align 1
 %wide_a = zext <4 x i64> %a to <4 x i128>
 %wide_b = zext <4 x i64> %b to <4 x i128>
 %sum = add <4 x i128> %wide_a, %wide_b
 %upper = lshr <4 x i128> %sum, splat (i128 64)
 %carry = trunc <4 x i128> %upper to <4 x i64>
 store <4 x i64> %carry, ptr %out, align 1
 %low = trunc <4 x i128> %sum to <4 x i64>
 %result = call i64 @llvm.vector.reduce.add.v4i64(<4 x i64> %low)
 ret i64 %result
}

define i64 @vector_graph_repack(ptr %src, ptr %out) {
entry:
 %words = load <4 x i64>, ptr %src, align 1
 %halves = bitcast <4 x i64> %words to <8 x i32>
 %mixed = shufflevector <8 x i32> %halves, <8 x i32> poison, <8 x i32> <i32 7, i32 0, i32 6, i32 1, i32 5, i32 2, i32 4, i32 3>
 %pairs = bitcast <8 x i32> %mixed to <2 x i128>
 %shifted = lshr <2 x i128> %pairs, <i128 13, i128 7>
 store <2 x i128> %shifted, ptr %out, align 1
 %a = extractelement <2 x i128> %shifted, i32 0
 %b = extractelement <2 x i128> %shifted, i32 1
 %lo = trunc i128 %a to i64
 %hi = trunc i128 %b to i64
 %result = xor i64 %lo, %hi
 ret i64 %result
}

define ptr @vector_graph_pointers(ptr %src, ptr %out, i32 %index, ptr %fallback) {
entry:
 %initial = load <2 x ptr>, ptr %src, align 1
 %seed = insertelement <1 x ptr> poison, ptr %fallback, i32 0
 %defaults = shufflevector <1 x ptr> %seed, <1 x ptr> poison, <2 x i32> zeroinitializer
 %empty = icmp eq <2 x ptr> %initial, zeroinitializer
 %filled = select <2 x i1> %empty, <2 x ptr> %defaults, <2 x ptr> %initial
 %changed = insertelement <2 x ptr> %filled, ptr %fallback, i32 %index
 %reverse = shufflevector <2 x ptr> %changed, <2 x ptr> poison, <2 x i32> <i32 1, i32 0>
 store <2 x ptr> %reverse, ptr %out, align 1
 %addresses = ptrtoint <2 x ptr> %reverse to <2 x i64>
 %restored = inttoptr <2 x i64> %addresses to <2 x ptr>
 %result = extractelement <2 x ptr> %restored, i32 %index
 ret ptr %result
}

define i64 @vector_graph_freeze(i64 %raw, ptr %out) {
entry:
 %lo = trunc i64 %raw to i16
 %shifted = lshr i64 %raw, 16
 %hi = trunc i64 %shifted to i16
 %a = insertelement <4 x i16> poison, i16 %lo, i32 0
 %b = insertelement <4 x i16> %a, i16 %hi, i32 2
 %frozen = freeze <4 x i16> %b
 %choice = extractelement <4 x i16> %frozen, i32 1
 %same = xor i16 %choice, %choice
 %c = insertelement <4 x i16> %frozen, i16 9, i32 1
 %d = insertelement <4 x i16> %c, i16 11, i32 3
 store <4 x i16> %d, ptr %out, align 1
 %bits = bitcast <4 x i16> %d to i64
 %zero = zext i16 %same to i64
 %result = xor i64 %bits, %zero
 ret i64 %result
}

define i32 @vector_graph_intrinsics(ptr %src, ptr %out) {
entry:
 %v = load <4 x i32>, ptr %src, align 1
 %rotate = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %v, <4 x i32> %v, <4 x i32> <i32 0, i32 1, i32 17, i32 31>)
 %reverse = call <4 x i32> @llvm.bswap.v4i32(<4 x i32> %rotate)
 store <4 x i32> %reverse, ptr %out, align 1
 %counts = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %reverse)
 %sat = call <4 x i32> @llvm.usub.sat.v4i32(<4 x i32> %counts, <4 x i32> <i32 3, i32 7, i32 31, i32 32>)
 %upper = getelementptr i8, ptr %out, i64 16
 store <4 x i32> %sat, ptr %upper, align 1
 %result = call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %sat)
 ret i32 %result
}

define i64 @vector_graph_ctpop6(ptr %src, ptr %out) {
entry:
 %words = load <6 x i64>, ptr %src, align 1
 %counts = call <6 x i64> @llvm.ctpop.v6i64(<6 x i64> %words)
 store <6 x i64> %counts, ptr %out, align 1
 %result = call i64 @llvm.vector.reduce.add.v6i64(<6 x i64> %counts)
 ret i64 %result
}
