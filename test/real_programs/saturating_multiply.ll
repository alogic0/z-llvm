target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare i4 @llvm.umul.fix.sat.i4(i4,i4,i32 immarg)
define i64 @sat_mul_umul_4(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = trunc i64 %input to i4
 %y = trunc i64 %other to i4
 %value = call i4 @llvm.umul.fix.sat.i4(i4 %x,i4 %y,i32 0)
 %wide = zext i4 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i4 @llvm.smul.fix.sat.i4(i4,i4,i32 immarg)
define i64 @sat_mul_smul_4(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = trunc i64 %input to i4
 %y = trunc i64 %other to i4
 %value = call i4 @llvm.smul.fix.sat.i4(i4 %x,i4 %y,i32 0)
 %wide = zext i4 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i8 @llvm.umul.fix.sat.i8(i8,i8,i32 immarg)
define i64 @sat_mul_umul_8(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = trunc i64 %input to i8
 %y = trunc i64 %other to i8
 %value = call i8 @llvm.umul.fix.sat.i8(i8 %x,i8 %y,i32 0)
 %wide = zext i8 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i8 @llvm.smul.fix.sat.i8(i8,i8,i32 immarg)
define i64 @sat_mul_smul_8(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = trunc i64 %input to i8
 %y = trunc i64 %other to i8
 %value = call i8 @llvm.smul.fix.sat.i8(i8 %x,i8 %y,i32 0)
 %wide = zext i8 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i25 @llvm.umul.fix.sat.i25(i25,i25,i32 immarg)
define i64 @sat_mul_umul_25(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = trunc i64 %input to i25
 %y = trunc i64 %other to i25
 %value = call i25 @llvm.umul.fix.sat.i25(i25 %x,i25 %y,i32 0)
 %wide = zext i25 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i25 @llvm.smul.fix.sat.i25(i25,i25,i32 immarg)
define i64 @sat_mul_smul_25(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = trunc i64 %input to i25
 %y = trunc i64 %other to i25
 %value = call i25 @llvm.smul.fix.sat.i25(i25 %x,i25 %y,i32 0)
 %wide = zext i25 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i64 @llvm.umul.fix.sat.i64(i64,i64,i32 immarg)
define i64 @sat_mul_umul_64(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = add i64 %input,0
 %y = add i64 %other,0
 %value = call i64 @llvm.umul.fix.sat.i64(i64 %x,i64 %y,i32 0)
 %wide = add i64 %value,0
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i64 @llvm.smul.fix.sat.i64(i64,i64,i32 immarg)
define i64 @sat_mul_smul_64(ptr %out,i64 %input,i64 %other,i64 %live) {
entry:
 %x = add i64 %input,0
 %y = add i64 %other,0
 %value = call i64 @llvm.smul.fix.sat.i64(i64 %x,i64 %y,i32 0)
 %wide = add i64 %value,0
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%other
 %answer = xor i64 %b,%live
 ret i64 %answer
}
