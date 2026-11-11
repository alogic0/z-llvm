target triple = "x86_64-unknown-linux-gnu"
declare i64 @integer_boundaries_clobber(i64)
declare fastcc i16 @zig.target.intByteSize(ptr,i16)
declare void @llvm.memset.p0.i64(ptr,i8,i64,i1)
declare { i128, i1 } @llvm.umul.with.overflow.i128(i128,i128)
define i128 @integer_boundaries_umul(i128 %a,i128 %b,ptr %out,i64 %live) {
entry:
 %pair = call { i128, i1 } @llvm.umul.with.overflow.i128(i128 %a,i128 %b)
 %value = extractvalue { i128, i1 } %pair,0
 %overflow = extractvalue { i128, i1 } %pair,1
 %byte = zext i1 %overflow to i8
 %flag = getelementptr i8,ptr %out,i64 16
 %probe = call i64 @integer_boundaries_clobber(i64 %live)
 store i128 %value,ptr %out,align 1
 store i8 %byte,ptr %flag,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %value,%wide
 ret i128 %answer
}
declare { i128, i1 } @llvm.smul.with.overflow.i128(i128,i128)
define i128 @integer_boundaries_smul(i128 %a,i128 %b,ptr %out,i64 %live) {
entry:
 %pair = call { i128, i1 } @llvm.smul.with.overflow.i128(i128 %a,i128 %b)
 %value = extractvalue { i128, i1 } %pair,0
 %overflow = extractvalue { i128, i1 } %pair,1
 %byte = zext i1 %overflow to i8
 %flag = getelementptr i8,ptr %out,i64 16
 %probe = call i64 @integer_boundaries_clobber(i64 %live)
 store i128 %value,ptr %out,align 1
 store i8 %byte,ptr %flag,align 1
 %wide = zext i64 %probe to i128
 %answer = xor i128 %value,%wide
 ret i128 %answer
}
define i64 @integer_boundaries_target(ptr %context,i64 %raw,ptr %out,i64 %live) {
entry:
 %bits = trunc i64 %raw to i16
 %small = tail call fastcc i16 @zig.target.intByteSize(ptr nonnull readonly align 1 %context,i16 %bits)
 %value = zext i16 %small to i64
 %probe = call i64 @integer_boundaries_clobber(i64 %live)
 store i16 %small,ptr %out,align 1
 %answer = xor i64 %value,%probe
 ret i64 %answer
}
define i64 @integer_boundaries_memset(ptr %out,i64 %rawfill,i64 %rawlen,i64 %live) {
entry:
 %fill = trunc i64 %rawfill to i8
 %len = and i64 %rawlen,31
 call void @llvm.memset.p0.i64(ptr align 1 %out,i8 noundef %fill,i64 range(i64 0, 33) %len,i1 false)
 %probe = call i64 @integer_boundaries_clobber(i64 %live)
 ret i64 %probe
}
define i64 @integer_boundaries_memset_constant(ptr %out,i64 %rawfill,i64 %rawlen,i64 %live) {
entry:
 %fill = trunc i64 %rawfill to i8
 %len = and i64 %rawlen,31
 call void @llvm.memset.p0.i64(ptr align 1 %out,i8 noundef %fill,i64 range(i64 0, 33) 32,i1 false)
 %probe = call i64 @integer_boundaries_clobber(i64 %live)
 ret i64 %probe
}
