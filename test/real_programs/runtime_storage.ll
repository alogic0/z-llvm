target triple = "x86_64-unknown-linux-gnu"
%StorageRecord = type { i8, i64, [9 x i8] }
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare i64 @runtime_storage_observe(ptr, i64)

define i64 @runtime_storage_33(ptr %input, ptr %output, i64 %length, i64 %live) {
entry:
 %slot = alloca [33 x i8], align 8
 call void @llvm.memset.p0.i64(ptr %slot, i8 -91, i64 33, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 %length, i1 false)
 %hash = call i64 @runtime_storage_observe(ptr %slot, i64 33)
 call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %slot, i64 33, i1 false)
 %result = xor i64 %hash, %live
 ret i64 %result
}

define i64 @runtime_storage_4096(ptr %input, ptr %output, i64 %length, i64 %live) {
entry:
 %slot = alloca [4096 x i8], align 16
 call void @llvm.memset.p0.i64(ptr %slot, i8 -91, i64 4096, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 %length, i1 false)
 %hash = call i64 @runtime_storage_observe(ptr %slot, i64 4096)
 call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %slot, i64 4096, i1 false)
 %result = xor i64 %hash, %live
 ret i64 %result
}

define i64 @runtime_storage_nested(ptr %input, ptr %output, i64 %length, i64 %live) {
entry:
 %slot = alloca %StorageRecord, align 8
 call void @llvm.memset.p0.i64(ptr %slot, i8 -91, i64 32, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 %length, i1 false)
 %hash = call i64 @runtime_storage_observe(ptr %slot, i64 32)
 call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %slot, i64 32, i1 false)
 %result = xor i64 %hash, %live
 ret i64 %result
}

define i64 @runtime_storage_pair_array(ptr %input, ptr %output, i64 %length, i64 %live) {
entry:
 %slot = alloca [1 x { ptr, i64 }], align 8
 call void @llvm.memset.p0.i64(ptr %slot, i8 -91, i64 16, i1 false)
 call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 %length, i1 false)
 %hash = call i64 @runtime_storage_observe(ptr %slot, i64 16)
 call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %slot, i64 16, i1 false)
 %result = xor i64 %hash, %live
 ret i64 %result
}
