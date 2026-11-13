target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
@pointer_order_global = global [128 x i8] zeroinitializer,align 16
@"pointer order quoted" = global [128 x i8] zeroinitializer,align 16
define i64 @pointer_order_probe_0(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ult ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_1(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp ult ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_2(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp ult ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_3(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp ult ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_4(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ult ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_5(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ult ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_6(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ult ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_7(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp ult ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_8(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp ult ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_9(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp ult ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_10(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ule ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_11(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp ule ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_12(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp ule ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_13(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp ule ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_14(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ule ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_15(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ule ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_16(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ule ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_17(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp ule ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_18(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp ule ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_19(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp ule ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_20(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ugt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_21(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp ugt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_22(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp ugt ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_23(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp ugt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_24(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ugt ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_25(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ugt ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_26(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp ugt ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_27(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp ugt ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_28(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp ugt ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_29(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp ugt ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_30(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp uge ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_31(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp uge ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_32(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp uge ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_33(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp uge ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_34(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp uge ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_35(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp uge ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_36(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp uge ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_37(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp uge ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_38(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp uge ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_39(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp uge ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_40(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp slt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_41(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp slt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_42(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp slt ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_43(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp slt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_44(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp slt ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_45(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp slt ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_46(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp slt ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_47(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp slt ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_48(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp slt ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_49(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp slt ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_50(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sle ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_51(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp sle ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_52(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp sle ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_53(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp sle ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_54(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sle ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_55(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sle ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_56(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sle ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_57(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp sle ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_58(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp sle ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_59(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp sle ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_60(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sgt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_61(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp sgt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_62(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp sgt ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_63(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp sgt ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_64(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sgt ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_65(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sgt ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_66(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sgt ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_67(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp sgt ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_68(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp sgt ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_69(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp sgt ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_70(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sge ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_71(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = getelementptr i8,ptr %input,i64 %left_bits
 %right = getelementptr i8,ptr %input,i64 %right_bits
 %c = icmp sge ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_72(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @pointer_order_global,i64 %right_bits
 %c = icmp sge ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_73(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %owned = alloca [128 x i8],align 16
 %left = getelementptr i8,ptr %owned,i64 %left_bits
 %right = getelementptr i8,ptr %owned,i64 %right_bits
 %c = icmp sge ptr %left,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_74(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sge ptr null,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr null to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_75(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sge ptr inttoptr (i64 9223372036854775808 to ptr),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr inttoptr (i64 9223372036854775808 to ptr) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_76(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = inttoptr i64 %right_bits to ptr
 %c = icmp sge ptr @pointer_order_global,%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr @pointer_order_global to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_77(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %right = getelementptr i8,ptr @"pointer order quoted",i64 %right_bits
 %c = icmp sge ptr getelementptr (i8,ptr @"pointer order quoted",i64 31),%right
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr getelementptr (i8,ptr @"pointer order quoted",i64 31) to i64
 %ri = ptrtoint ptr %right to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_78(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp sge ptr %left,null
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr null to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
define i64 @pointer_order_probe_79(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %left_bits = load i64,ptr %input,align 1
 %rp = getelementptr i8,ptr %input,i64 8
 %right_bits = load i64,ptr %rp,align 1
 %left = inttoptr i64 %left_bits to ptr
 %c = icmp sge ptr %left,inttoptr (i64 -1 to ptr)
 %comparison = zext i1 %c to i64
 %li = ptrtoint ptr %left to i64
 %ri = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
 %delta = sub i64 %ri,%li
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %comparison,ptr %out,align 1
 %dp = getelementptr i8,ptr %out,i64 8
 store i64 %delta,ptr %dp,align 1
 %op = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %comparison,%token
 ret i64 %answer
}
