target triple = "x86_64-unknown-linux-gnu"
declare <4 x i32> @vector_abi_host(<4 x i32>, <4 x i32>, i64)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define <4 x i32> @vector_abi_rotate(<4 x i32> %input) {
entry:
 %left = shl <4 x i32> %input, <i32 7, i32 7, i32 7, i32 7>
 %right = lshr <4 x i32> %input, <i32 25, i32 25, i32 25, i32 25>
 %rotated = or <4 x i32> %left, %right
 ret <4 x i32> %rotated
}
define <4 x i32> @vector_abi_mix(<4 x i32> %a, <4 x i32> %b, i64 %tag) {
entry:
 %x = call <4 x i32> @vector_abi_rotate(<4 x i32> %a)
 %y = xor <4 x i32> %x, %b
 %z = call <4 x i32> @vector_abi_host(<4 x i32> %b, <4 x i32> %y, i64 %tag)
 %result = add <4 x i32> %z, %x
 ret <4 x i32> %result
}
define <4 x i32> @vector_abi_pressure(<4 x i32> %a, <4 x i32> %b, <4 x i32> %c, <4 x i32> %d, <4 x i32> %e, <4 x i32> %f, <4 x i32> %g, <4 x i32> %h) {
entry:
 %first = call <4 x i32> @vector_abi_host(<4 x i32> %b, <4 x i32> %a, i64 123)
 %ab = add <4 x i32> %first, %a
 %abc = xor <4 x i32> %ab, %c
 %abcd = add <4 x i32> %abc, %d
 %abcde = xor <4 x i32> %abcd, %e
 %abcdef = add <4 x i32> %abcde, %f
 %abcdefg = xor <4 x i32> %abcdef, %g
 %result = add <4 x i32> %abcdefg, %h
 ret <4 x i32> %result
}
define void @vector_abi_sret(ptr sret([4 x <4 x i32>]) align 16 %out, <4 x i32> %a) {
entry:
 %b = add <4 x i32> %a, <i32 1, i32 2, i32 3, i32 4>
 %c = xor <4 x i32> %a, <i32 -1, i32 -2, i32 -3, i32 -4>
 %d = sub <4 x i32> %a, %b
 %p1 = getelementptr i8, ptr %out, i64 16
 %p2 = getelementptr i8, ptr %out, i64 32
 %p3 = getelementptr i8, ptr %out, i64 48
 store <4 x i32> %a, ptr %out, align 16
 store <4 x i32> %b, ptr %p1, align 16
 store <4 x i32> %c, ptr %p2, align 16
 store <4 x i32> %d, ptr %p3, align 16
 ret void
}
define void @vector_abi_nested(ptr %out, <4 x i32> %a) {
entry:
 %slot = alloca [4 x <4 x i32>], align 16
 call void @vector_abi_sret(ptr sret([4 x <4 x i32>]) align 16 %slot, <4 x i32> %a)
 call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 64, i1 false)
 ret void
}
