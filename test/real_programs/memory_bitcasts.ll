target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)
declare void @llvm.memset.p0.i64(ptr,i8,i64,i1)
define internal i64 @memory.bitcast.body.0(ptr %out,<32 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <16 x i8>],align 16
 %wide = bitcast <32 x i8> %input to i256
 %q = and i64 %salt,1
 %amount = mul i64 %q,128
 %count = zext i64 %amount to i256
 %shifted = lshr i256 %wide,%count
 %half = trunc i256 %shifted to i128
 %vector = bitcast i128 %half to <16 x i8>
 %where = getelementptr [16 x i8],ptr %local,i64 %q
 store <16 x i8> %vector,ptr %where,align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 16,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,15
 %ap = getelementptr i8,ptr %out,i64 16
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = call i64 @memory.bitcast.body.0(ptr %out,<32 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
define internal i64 @memory.bitcast.body.1(ptr %out,<32 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <16 x i8>],align 16
 store <32 x i8> zeroinitializer,ptr %source,align 1
 %wide = bitcast <32 x i8> %input to i256
 %q = and i64 %salt,1
 %amount = mul i64 %q,128
 %count = zext i64 %amount to i256
 %shifted = lshr i256 %wide,%count
 %half = trunc i256 %shifted to i128
 %vector = bitcast i128 %half to <16 x i8>
 %where = getelementptr [16 x i8],ptr %local,i64 %q
 store <16 x i8> %vector,ptr %where,align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 16,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,15
 %ap = getelementptr i8,ptr %out,i64 16
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = call i64 @memory.bitcast.body.1(ptr %out,<32 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @memory.bitcast.body.2(ptr %out,<32 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <16 x i8>],align 16
 %wide = bitcast <32 x i8> %input to i256
 %q = and i64 %salt,1
 %amount = mul i64 %q,128
 %count = zext i64 %amount to i256
 %shifted = lshr i256 %wide,%count
 %half = trunc i256 %shifted to i128
 %vector = bitcast i128 %half to <16 x i8>
 %where = getelementptr [16 x i8],ptr %local,i64 %q
 store <16 x i8> %vector,ptr %where,align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 16,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,15
 %ap = getelementptr i8,ptr %out,i64 16
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = call fastcc i64 @memory.bitcast.body.2(ptr %out,<32 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @memory.bitcast.body.3(ptr %out,<32 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <16 x i8>],align 16
 store <32 x i8> zeroinitializer,ptr %source,align 1
 %wide = bitcast <32 x i8> %input to i256
 %q = and i64 %salt,1
 %amount = mul i64 %q,128
 %count = zext i64 %amount to i256
 %shifted = lshr i256 %wide,%count
 %half = trunc i256 %shifted to i128
 %vector = bitcast i128 %half to <16 x i8>
 %where = getelementptr [16 x i8],ptr %local,i64 %q
 store <16 x i8> %vector,ptr %where,align 16
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 16,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,15
 %ap = getelementptr i8,ptr %out,i64 16
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = call fastcc i64 @memory.bitcast.body.3(ptr %out,<32 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
define internal i64 @memory.bitcast.body.4(ptr %out,<64 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <32 x i8>],align 32
 %wide = bitcast <64 x i8> %input to i512
 %q = and i64 %salt,1
 %amount = mul i64 %q,256
 %count = zext i64 %amount to i512
 %shifted = lshr i512 %wide,%count
 %half = trunc i512 %shifted to i256
 %vector = bitcast i256 %half to <32 x i8>
 %where = getelementptr [32 x i8],ptr %local,i64 %q
 store <32 x i8> %vector,ptr %where,align 32
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 32,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,31
 %ap = getelementptr i8,ptr %out,i64 32
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %r = call i64 @memory.bitcast.body.4(ptr %out,<64 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
define internal i64 @memory.bitcast.body.5(ptr %out,<64 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <32 x i8>],align 32
 store <64 x i8> zeroinitializer,ptr %source,align 1
 %wide = bitcast <64 x i8> %input to i512
 %q = and i64 %salt,1
 %amount = mul i64 %q,256
 %count = zext i64 %amount to i512
 %shifted = lshr i512 %wide,%count
 %half = trunc i512 %shifted to i256
 %vector = bitcast i256 %half to <32 x i8>
 %where = getelementptr [32 x i8],ptr %local,i64 %q
 store <32 x i8> %vector,ptr %where,align 32
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 32,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,31
 %ap = getelementptr i8,ptr %out,i64 32
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %r = call i64 @memory.bitcast.body.5(ptr %out,<64 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @memory.bitcast.body.6(ptr %out,<64 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <32 x i8>],align 32
 %wide = bitcast <64 x i8> %input to i512
 %q = and i64 %salt,1
 %amount = mul i64 %q,256
 %count = zext i64 %amount to i512
 %shifted = lshr i512 %wide,%count
 %half = trunc i512 %shifted to i256
 %vector = bitcast i256 %half to <32 x i8>
 %where = getelementptr [32 x i8],ptr %local,i64 %q
 store <32 x i8> %vector,ptr %where,align 32
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 32,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,31
 %ap = getelementptr i8,ptr %out,i64 32
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %r = call fastcc i64 @memory.bitcast.body.6(ptr %out,<64 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @memory.bitcast.body.7(ptr %out,<64 x i8> %input,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca [2 x <32 x i8>],align 32
 store <64 x i8> zeroinitializer,ptr %source,align 1
 %wide = bitcast <64 x i8> %input to i512
 %q = and i64 %salt,1
 %amount = mul i64 %q,256
 %count = zext i64 %amount to i512
 %shifted = lshr i512 %wide,%count
 %half = trunc i512 %shifted to i256
 %vector = bitcast i256 %half to <32 x i8>
 %where = getelementptr [32 x i8],ptr %local,i64 %q
 store <32 x i8> %vector,ptr %where,align 32
 call void @llvm.memcpy.p0.p0.i64(ptr %out,ptr %where,i64 32,i1 0)
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,31
 %ap = getelementptr i8,ptr %out,i64 32
 store i64 %low,ptr %ap,align 1
 ret i64 %salt
}
define i64 @memory_bitcasts_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %r = call fastcc i64 @memory.bitcast.body.7(ptr %out,<64 x i8> %input,ptr %source,i64 %salt)
 ret i64 %r
}
