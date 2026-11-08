target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare void @intrinsic_facts_clobber()
declare i64 @llvm.uadd.sat.i64(i64, i64)
declare i64 @llvm.usub.sat.i64(i64, i64)
declare i23 @llvm.uadd.sat.i23(i23, i23)
declare i6 @llvm.umin.i6(i6, i6)
declare i23 @llvm.bitreverse.i23(i23)

define i64 @intrinsic_facts_add(i64 %a, i64 %b, ptr %output, i64 %salt) {
entry:
  call void @intrinsic_facts_clobber()
  %result = call noundef i64 @llvm.uadd.sat.i64(i64 noundef %a, i64 noundef %b)
  store i64 %result, ptr %output, align 8
  %both = xor i64 %a, %b
  %witness = xor i64 %both, %salt
  ret i64 %witness
}

define i64 @intrinsic_facts_wrapped(i64 %a, i64 %b, ptr %output, i64 %salt) {
entry:
  %lhs = or i64 %a, 32
  %rhs = or i64 %b, 1
  %result = call noundef range(i64 33, 0) i64 @llvm.uadd.sat.i64(i64 range(i64 32, 0) %lhs, i64 noundef range(i64 1, 0) %rhs)
  store i64 %result, ptr %output, align 8
  %both = xor i64 %a, %b
  %witness = xor i64 %both, %salt
  ret i64 %witness
}

define i64 @intrinsic_facts_sub(i64 %a, i64 %b, ptr %output, i64 %salt) {
entry:
  %rhs = or i64 %b, 1
  %result = call range(i64 0, -1) i64 @llvm.usub.sat.i64(i64 noundef %a, i64 range(i64 1, 0) %rhs)
  store i64 %result, ptr %output, align 8
  %both = xor i64 %a, %b
  %witness = xor i64 %both, %salt
  ret i64 %witness
}

define i64 @intrinsic_facts_add23(i64 %a, i64 %b, ptr %output, i64 %salt) {
entry:
  %x = trunc i64 %a to i23
  %y = trunc i64 %b to i23
  %lhs = or i23 %x, 1
  %small = call noundef range(i23 1, 0) i23 @llvm.uadd.sat.i23(i23 range(i23 1, 0) %lhs, i23 noundef %y)
  %result = zext i23 %small to i64
  store i64 %result, ptr %output, align 8
  %both = xor i64 %a, %b
  %witness = xor i64 %both, %salt
  ret i64 %witness
}

define i64 @intrinsic_facts_min6(i64 %a, i64 %b, ptr %output, i64 %salt) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %lhs = and i6 %x, 15
  %rhs = and i6 %y, 15
  %small = call noundef range(i6 -16, 16) i6 @llvm.umin.i6(i6 range(i6 -16, 16) %lhs, i6 noundef range(i6 0, 16) %rhs)
  %result = zext i6 %small to i64
  store i64 %result, ptr %output, align 8
  %both = xor i64 %a, %b
  %witness = xor i64 %both, %salt
  ret i64 %witness
}

define i64 @intrinsic_facts_reverse23(i64 %a, i64 %b, ptr %output, i64 %salt) {
entry:
  %x = trunc i64 %a to i23
  %lhs = and i23 %x, 4194303
  %small = call noundef range(i23 0, 8388607) i23 @llvm.bitreverse.i23(i23 range(i23 0, 4194304) %lhs)
  %result = zext i23 %small to i64
  store i64 %result, ptr %output, align 8
  %both = xor i64 %a, %b
  %witness = xor i64 %both, %salt
  ret i64 %witness
}

