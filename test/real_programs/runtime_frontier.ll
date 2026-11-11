target triple = "x86_64-unknown-linux-gnu"
declare i128 @llvm.cttz.i128(i128,i1 immarg)
declare i128 @llvm.umin.i128(i128,i128)
declare i128 @llvm.umax.i128(i128,i128)
declare i128 @llvm.fshl.i128(i128,i128,i128)
declare i32 @llvm.ucmp.i32.i64(i64,i64)
declare i32 @llvm.scmp.i32.i64(i64,i64)
declare i32 @llvm.ucmp.i32.i32(i32,i32)
declare half @llvm.copysign.f16(half,half)
declare half @llvm.maxnum.f16(half,half)
declare x86_fp80 @llvm.maxnum.f80(x86_fp80,x86_fp80)
declare fp128 @llvm.maxnum.f128(fp128,fp128)
@runtime_frontier_data = private global i64 1234567
@runtime_frontier_weak_data = weak_odr alias i64,ptr @runtime_frontier_data
@runtime_frontier_weak = weak_odr alias i64(i64),ptr @runtime_frontier_body
define private i64 @runtime_frontier_body(i64 %x) {
entry:
 %r = xor i64 %x, 1234567
 ret i64 %r
}
define i128 @runtime_frontier_cttz(i128 %x) {
entry:
 %r = call i128 @llvm.cttz.i128(i128 %x,i1 false)
 ret i128 %r
}
define i128 @runtime_frontier_min(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.umin.i128(i128 %a,i128 %b)
 ret i128 %r
}
define i128 @runtime_frontier_max(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.umax.i128(i128 %a,i128 %b)
 ret i128 %r
}
define i64 @runtime_frontier_pairs(i64 %a,i64 %b,i64 %c,i64 %d,ptr %out,i64 %live) {
entry:
 %bh = zext i64 %b to i128
 %bs = shl i128 %bh,64
 %al = zext i64 %a to i128
 %left = or i128 %bs,%al
 %dh = zext i64 %d to i128
 %ds = shl i128 %dh,64
 %cl = zext i64 %c to i128
 %right = or i128 %ds,%cl
 %both = xor i128 %left,%right
 store i128 %both,ptr %out,align 1
 %low = trunc i128 %both to i64
 %answer = xor i64 %low,%live
 ret i64 %answer
}
define i64 @runtime_frontier_div(i64 %divisor,i64 %low,i64 %high,ptr %out,i64 %live) {
entry:
 %both = call {i64,i64} asm "divq ${2}","={rax},={rdx},r,{rax},{rdx},~{dirflag},~{fpsr},~{flags}"(i64 %divisor,i64 %low,i64 %high)
 %q = extractvalue {i64,i64} %both,0
 %r = extractvalue {i64,i64} %both,1
 store i64 %q,ptr %out,align 1
 %tail = getelementptr i8,ptr %out,i64 8
 store i64 %r,ptr %tail,align 1
 %answer = xor i64 %q,%live
 ret i64 %answer
}
define i32 @runtime_frontier_ucmp(i64 %a,i64 %b) {
entry:
 %r = call i32 @llvm.ucmp.i32.i64(i64 %a,i64 %b)
 ret i32 %r
}
define i32 @runtime_frontier_scmp(i64 %a,i64 %b) {
entry:
 %r = call i32 @llvm.scmp.i32.i64(i64 %a,i64 %b)
 ret i32 %r
}
define i32 @runtime_frontier_ucmp32(i32 %a,i32 %b) {
entry:
 %r = call i32 @llvm.ucmp.i32.i32(i32 %a,i32 %b)
 ret i32 %r
}
define i16 @runtime_frontier_half(float %a,float %b,float %c,float %d) {
entry:
 %p = fmul float %a,%b
 %q = fmul float %c,%d
 %h = fptrunc float %p to half
 %i = fptrunc float %q to half
 %r = fadd half %i,%h
 %bits = bitcast half %r to i16
 ret i16 %bits
}
define i16 @runtime_frontier_sign(i16 %a,i16 %b) {
entry:
 %x = bitcast i16 %a to half
 %y = bitcast i16 %b to half
 %r = call half @llvm.copysign.f16(half %x,half %y)
 %bits = bitcast half %r to i16
 ret i16 %bits
}
define i16 @runtime_frontier_halfmax(i16 %a,i16 %b) {
entry:
 %x = bitcast i16 %a to half
 %y = bitcast i16 %b to half
 %r = call half @llvm.maxnum.f16(half %x,half %y)
 %bits = bitcast half %r to i16
 ret i16 %bits
}
define double @runtime_frontier_shuffle(double %a,double %b,double %c,double %d,ptr %out,double %live) {
entry:
 %v0 = insertelement <4 x double> poison,double %a,i64 0
 %v1 = insertelement <4 x double> %v0,double %b,i64 1
 %v2 = insertelement <4 x double> %v1,double %c,i64 2
 %v3 = insertelement <4 x double> %v2,double %d,i64 3
 %v = shufflevector <4 x double> %v3,<4 x double> poison,<4 x i32> <i32 3,i32 0,i32 2,i32 1>
 store <4 x double> %v,ptr %out,align 1
 ret double %live
}
define <2 x float> @runtime_frontier_packed(float %a,float %b) {
entry:
 %v0 = insertelement <2 x float> poison,float %a,i64 0
 %v1 = insertelement <2 x float> %v0,float %b,i64 1
 ret <2 x float> %v1
}
define i64 @runtime_frontier_packed_call(float %a,float %b) {
entry:
 %v = call <2 x float> @runtime_frontier_packed(float %a,float %b)
 %r = bitcast <2 x float> %v to i64
 ret i64 %r
}
define void @runtime_frontier_quad(fp128 %a,fp128 %b,fp128 %c,fp128 %d,ptr %out) {
entry:
 %v0 = insertelement <4 x fp128> poison,fp128 %a,i64 0
 %v1 = insertelement <4 x fp128> %v0,fp128 %b,i64 1
 %v2 = insertelement <4 x fp128> %v1,fp128 %c,i64 2
 %v3 = insertelement <4 x fp128> %v2,fp128 %d,i64 3
 %v = shufflevector <4 x fp128> %v3,<4 x fp128> poison,<4 x i32> <i32 3,i32 0,i32 2,i32 1>
 store <4 x fp128> %v,ptr %out,align 1
 ret void
}
define x86_fp80 @runtime_frontier_max80(x86_fp80 %a,x86_fp80 %b) {
entry:
 %r = call x86_fp80 @llvm.maxnum.f80(x86_fp80 %a,x86_fp80 %b)
 ret x86_fp80 %r
}
define fp128 @runtime_frontier_max128(fp128 %a,fp128 %b) {
entry:
 %r = call fp128 @llvm.maxnum.f128(fp128 %a,fp128 %b)
 ret fp128 %r
}
define void @runtime_frontier_byval(ptr %out,ptr byval(x86_fp80) align 16 %a,ptr byval(x86_fp80) align 16 %b,ptr byval(x86_fp80) align 16 %c,ptr byval(x86_fp80) align 16 %d) {
entry:
 %x = load x86_fp80,ptr %a,align 1
 %y = load x86_fp80,ptr %b,align 1
 %z = load x86_fp80,ptr %c,align 1
 %w = load x86_fp80,ptr %d,align 1
 store x86_fp80 %x,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 16
 %p2 = getelementptr i8,ptr %out,i64 32
 %p3 = getelementptr i8,ptr %out,i64 48
 store x86_fp80 %y,ptr %p1,align 1
 store x86_fp80 %z,ptr %p2,align 1
 store x86_fp80 %w,ptr %p3,align 1
 ret void
}
define void @runtime_frontier_byval_call(ptr %out,ptr %a,ptr %b,ptr %c,ptr %d) {
entry:
 call void @runtime_frontier_byval(ptr %out,ptr byval(x86_fp80) align 16 %a,ptr byval(x86_fp80) align 16 %b,ptr byval(x86_fp80) align 16 %c,ptr byval(x86_fp80) align 16 %d)
 ret void
}
define i128 @runtime_frontier_funnel_0(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 0)
 ret i128 %r
}
define i128 @runtime_frontier_funnel_1(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 1)
 ret i128 %r
}
define i128 @runtime_frontier_funnel_63(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 63)
 ret i128 %r
}
define i128 @runtime_frontier_funnel_64(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 64)
 ret i128 %r
}
define i128 @runtime_frontier_funnel_65(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 65)
 ret i128 %r
}
define i128 @runtime_frontier_funnel_127(i128 %a,i128 %b) {
entry:
 %r = call i128 @llvm.fshl.i128(i128 %a,i128 %b,i128 127)
 ret i128 %r
}
