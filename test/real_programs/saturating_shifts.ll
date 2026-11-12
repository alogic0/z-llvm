target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare i4 @llvm.ushl.sat.i4(i4,i4)
define i64 @sat_shift_ushl_4(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = trunc i64 %input to i4
 %n = trunc i64 %amount to i4
 %raw = call i4 @llvm.ushl.sat.i4(i4 %x,i4 %n)
 %valid = icmp ult i4 %n,4
 %value = select i1 %valid,i4 %raw,i4 0
 %wide = zext i4 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i4 @llvm.sshl.sat.i4(i4,i4)
define i64 @sat_shift_sshl_4(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = trunc i64 %input to i4
 %n = trunc i64 %amount to i4
 %raw = call i4 @llvm.sshl.sat.i4(i4 %x,i4 %n)
 %valid = icmp ult i4 %n,4
 %value = select i1 %valid,i4 %raw,i4 0
 %wide = zext i4 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i8 @llvm.ushl.sat.i8(i8,i8)
define i64 @sat_shift_ushl_8(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = trunc i64 %input to i8
 %n = trunc i64 %amount to i8
 %raw = call i8 @llvm.ushl.sat.i8(i8 %x,i8 %n)
 %valid = icmp ult i8 %n,8
 %value = select i1 %valid,i8 %raw,i8 0
 %wide = zext i8 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i8 @llvm.sshl.sat.i8(i8,i8)
define i64 @sat_shift_sshl_8(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = trunc i64 %input to i8
 %n = trunc i64 %amount to i8
 %raw = call i8 @llvm.sshl.sat.i8(i8 %x,i8 %n)
 %valid = icmp ult i8 %n,8
 %value = select i1 %valid,i8 %raw,i8 0
 %wide = zext i8 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i25 @llvm.ushl.sat.i25(i25,i25)
define i64 @sat_shift_ushl_25(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = trunc i64 %input to i25
 %n = trunc i64 %amount to i25
 %raw = call i25 @llvm.ushl.sat.i25(i25 %x,i25 %n)
 %valid = icmp ult i25 %n,25
 %value = select i1 %valid,i25 %raw,i25 0
 %wide = zext i25 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i25 @llvm.sshl.sat.i25(i25,i25)
define i64 @sat_shift_sshl_25(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = trunc i64 %input to i25
 %n = trunc i64 %amount to i25
 %raw = call i25 @llvm.sshl.sat.i25(i25 %x,i25 %n)
 %valid = icmp ult i25 %n,25
 %value = select i1 %valid,i25 %raw,i25 0
 %wide = zext i25 %value to i64
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i64 @llvm.ushl.sat.i64(i64,i64)
define i64 @sat_shift_ushl_64(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = add i64 %input,0
 %n = add i64 %amount,0
 %raw = call i64 @llvm.ushl.sat.i64(i64 %x,i64 %n)
 %valid = icmp ult i64 %n,64
 %value = select i1 %valid,i64 %raw,i64 0
 %wide = add i64 %value,0
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
declare i64 @llvm.sshl.sat.i64(i64,i64)
define i64 @sat_shift_sshl_64(ptr %out,i64 %input,i64 %amount,i64 %live) {
entry:
 %x = add i64 %input,0
 %n = add i64 %amount,0
 %raw = call i64 @llvm.sshl.sat.i64(i64 %x,i64 %n)
 %valid = icmp ult i64 %n,64
 %value = select i1 %valid,i64 %raw,i64 0
 %wide = add i64 %value,0
 store i64 %wide,ptr %out,align 1
 %a = xor i64 %wide,%input
 %b = xor i64 %a,%amount
 %answer = xor i64 %b,%live
 ret i64 %answer
}
