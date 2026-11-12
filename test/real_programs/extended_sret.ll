%P = type { x86_fp80, x86_fp80 }
%Q = type { fp128, i64 }
declare void @external_pair80(ptr sret(%P) align 16, ptr byval(x86_fp80) align 16)
declare void @external_pair128(ptr sret(%Q) align 16, fp128)
declare x86_fp80 @llvm.fabs.f80(x86_fp80)
declare x86_fp80 @llvm.copysign.f80(x86_fp80, x86_fp80)
declare fp128 @llvm.fabs.f128(fp128)
declare fp128 @llvm.copysign.f128(fp128, fp128)

define void @sret_pair80(ptr sret(%P) align 16 %out, ptr byval(x86_fp80) align 16 %input) {
entry:
 %x = load x86_fp80, ptr %input, align 16
 %negative = fneg x86_fp80 %x
 store x86_fp80 %x, ptr %out, align 16
 %second = getelementptr %P, ptr %out, i64 0, i32 1
 store x86_fp80 %negative, ptr %second, align 16
 ret void
}
define void @sret_pair128(ptr sret(%Q) align 16 %out, fp128 %x) {
entry:
 store fp128 %x, ptr %out, align 16
 %second = getelementptr %Q, ptr %out, i64 0, i32 1
 store i64 1311768467463790320, ptr %second, align 8
 ret void
}
define void @sret_call80(ptr sret(%P) align 16 %out, ptr byval(x86_fp80) align 16 %input) {
entry:
 call void @external_pair80(ptr sret(%P) align 16 %out, ptr byval(x86_fp80) align 16 %input)
 ret void
}
define void @sret_call128(ptr sret(%Q) align 16 %out, fp128 %x) {
entry:
 call void @external_pair128(ptr sret(%Q) align 16 %out, fp128 %x)
 ret void
}
define x86_fp80 @sret_sign80(x86_fp80 %x, x86_fp80 %sign) {
entry:
 %magnitude = call x86_fp80 @llvm.fabs.f80(x86_fp80 %x)
 %result = call x86_fp80 @llvm.copysign.f80(x86_fp80 %magnitude, x86_fp80 %sign)
 ret x86_fp80 %result
}
define fp128 @sret_sign128(fp128 %x, fp128 %sign) {
entry:
 %magnitude = call fp128 @llvm.fabs.f128(fp128 %x)
 %result = call fp128 @llvm.copysign.f128(fp128 %magnitude, fp128 %sign)
 ret fp128 %result
}
