target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
@function_alignment_alias_0 = alias i64 (i64),ptr @function_alignment_target_0
@function_alignment_dispatch_0 = internal global ptr @function_alignment_target_0,align 8
define internal i64 @function_alignment_target_0(i64 %value) noinline align 1 {
entry:
 %r = xor i64 %value,1311768467463790320
 ret i64 %r
}
define ptr @function_alignment_get_0() {
entry:
 ret ptr @function_alignment_target_0
}
define i64 @function_alignment_probe_0(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_0 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_0,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,0
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_0(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_1 = alias i64 (i64),ptr @function_alignment_target_1
@function_alignment_dispatch_1 = internal global ptr @function_alignment_target_1,align 8
define internal fastcc i64 @function_alignment_target_1(i64 %value) noinline align 1 {
entry:
 %r = xor i64 %value,1311768467463790305
 ret i64 %r
}
define ptr @function_alignment_get_1() {
entry:
 ret ptr @function_alignment_target_1
}
define i64 @function_alignment_probe_1(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_1 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_1,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,0
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_1(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_2 = alias i64 (i64),ptr @function_alignment_target_2
@function_alignment_dispatch_2 = internal global ptr @function_alignment_target_2,align 8
define internal i64 @function_alignment_target_2(i64 %value) noinline align 2 {
entry:
 %r = xor i64 %value,1311768467463790290
 ret i64 %r
}
define ptr @function_alignment_get_2() {
entry:
 ret ptr @function_alignment_target_2
}
define i64 @function_alignment_probe_2(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_2 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_2,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,1
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_2(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_3 = alias i64 (i64),ptr @function_alignment_target_3
@function_alignment_dispatch_3 = internal global ptr @function_alignment_target_3,align 8
define internal fastcc i64 @function_alignment_target_3(i64 %value) noinline align 2 {
entry:
 %r = xor i64 %value,1311768467463790275
 ret i64 %r
}
define ptr @function_alignment_get_3() {
entry:
 ret ptr @function_alignment_target_3
}
define i64 @function_alignment_probe_3(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_3 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_3,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,1
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_3(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_4 = alias i64 (i64),ptr @function_alignment_target_4
@function_alignment_dispatch_4 = internal global ptr @function_alignment_target_4,align 8
define internal i64 @function_alignment_target_4(i64 %value) noinline align 4 {
entry:
 %r = xor i64 %value,1311768467463790260
 ret i64 %r
}
define ptr @function_alignment_get_4() {
entry:
 ret ptr @function_alignment_target_4
}
define i64 @function_alignment_probe_4(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_4 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_4,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,3
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_4(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_5 = alias i64 (i64),ptr @function_alignment_target_5
@function_alignment_dispatch_5 = internal global ptr @function_alignment_target_5,align 8
define internal fastcc i64 @function_alignment_target_5(i64 %value) noinline align 4 {
entry:
 %r = xor i64 %value,1311768467463790245
 ret i64 %r
}
define ptr @function_alignment_get_5() {
entry:
 ret ptr @function_alignment_target_5
}
define i64 @function_alignment_probe_5(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_5 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_5,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,3
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_5(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_6 = alias i64 (i64),ptr @function_alignment_target_6
@function_alignment_dispatch_6 = internal global ptr @function_alignment_target_6,align 8
define internal i64 @function_alignment_target_6(i64 %value) noinline align 8 {
entry:
 %r = xor i64 %value,1311768467463790230
 ret i64 %r
}
define ptr @function_alignment_get_6() {
entry:
 ret ptr @function_alignment_target_6
}
define i64 @function_alignment_probe_6(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_6 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_6,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,7
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_6(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_7 = alias i64 (i64),ptr @function_alignment_target_7
@function_alignment_dispatch_7 = internal global ptr @function_alignment_target_7,align 8
define internal fastcc i64 @function_alignment_target_7(i64 %value) noinline align 8 {
entry:
 %r = xor i64 %value,1311768467463790215
 ret i64 %r
}
define ptr @function_alignment_get_7() {
entry:
 ret ptr @function_alignment_target_7
}
define i64 @function_alignment_probe_7(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_7 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_7,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,7
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_7(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_8 = alias i64 (i64),ptr @function_alignment_target_8
@function_alignment_dispatch_8 = internal global ptr @function_alignment_target_8,align 8
define internal i64 @function_alignment_target_8(i64 %value) noinline align 16 {
entry:
 %r = xor i64 %value,1311768467463790200
 ret i64 %r
}
define ptr @function_alignment_get_8() {
entry:
 ret ptr @function_alignment_target_8
}
define i64 @function_alignment_probe_8(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_8 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_8,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,15
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_8(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_9 = alias i64 (i64),ptr @function_alignment_target_9
@function_alignment_dispatch_9 = internal global ptr @function_alignment_target_9,align 8
define internal fastcc i64 @function_alignment_target_9(i64 %value) noinline align 16 {
entry:
 %r = xor i64 %value,1311768467463790185
 ret i64 %r
}
define ptr @function_alignment_get_9() {
entry:
 ret ptr @function_alignment_target_9
}
define i64 @function_alignment_probe_9(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_9 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_9,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,15
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_9(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_10 = alias i64 (i64),ptr @function_alignment_target_10
@function_alignment_dispatch_10 = internal global ptr @function_alignment_target_10,align 8
define internal i64 @function_alignment_target_10(i64 %value) noinline align 32 {
entry:
 %r = xor i64 %value,1311768467463790170
 ret i64 %r
}
define ptr @function_alignment_get_10() {
entry:
 ret ptr @function_alignment_target_10
}
define i64 @function_alignment_probe_10(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_10 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_10,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,31
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_10(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_11 = alias i64 (i64),ptr @function_alignment_target_11
@function_alignment_dispatch_11 = internal global ptr @function_alignment_target_11,align 8
define internal fastcc i64 @function_alignment_target_11(i64 %value) noinline align 32 {
entry:
 %r = xor i64 %value,1311768467463790155
 ret i64 %r
}
define ptr @function_alignment_get_11() {
entry:
 ret ptr @function_alignment_target_11
}
define i64 @function_alignment_probe_11(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_11 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_11,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,31
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_11(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_12 = alias i64 (i64),ptr @function_alignment_target_12
@function_alignment_dispatch_12 = internal global ptr @function_alignment_target_12,align 8
define internal i64 @function_alignment_target_12(i64 %value) noinline align 64 {
entry:
 %r = xor i64 %value,1311768467463790140
 ret i64 %r
}
define ptr @function_alignment_get_12() {
entry:
 ret ptr @function_alignment_target_12
}
define i64 @function_alignment_probe_12(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_12 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_12,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,63
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_12(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_13 = alias i64 (i64),ptr @function_alignment_target_13
@function_alignment_dispatch_13 = internal global ptr @function_alignment_target_13,align 8
define internal fastcc i64 @function_alignment_target_13(i64 %value) noinline align 64 {
entry:
 %r = xor i64 %value,1311768467463790125
 ret i64 %r
}
define ptr @function_alignment_get_13() {
entry:
 ret ptr @function_alignment_target_13
}
define i64 @function_alignment_probe_13(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_13 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_13,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,63
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_13(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_14 = alias i64 (i64),ptr @function_alignment_target_14
@function_alignment_dispatch_14 = internal global ptr @function_alignment_target_14,align 8
define internal i64 @function_alignment_target_14(i64 %value) noinline align 128 {
entry:
 %r = xor i64 %value,1311768467463790110
 ret i64 %r
}
define ptr @function_alignment_get_14() {
entry:
 ret ptr @function_alignment_target_14
}
define i64 @function_alignment_probe_14(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_14 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_14,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,127
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_14(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_15 = alias i64 (i64),ptr @function_alignment_target_15
@function_alignment_dispatch_15 = internal global ptr @function_alignment_target_15,align 8
define internal fastcc i64 @function_alignment_target_15(i64 %value) noinline align 128 {
entry:
 %r = xor i64 %value,1311768467463790095
 ret i64 %r
}
define ptr @function_alignment_get_15() {
entry:
 ret ptr @function_alignment_target_15
}
define i64 @function_alignment_probe_15(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_15 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_15,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,127
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_15(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_16 = alias i64 (i64),ptr @function_alignment_target_16
@function_alignment_dispatch_16 = internal global ptr @function_alignment_target_16,align 8
define internal i64 @function_alignment_target_16(i64 %value) noinline align 256 {
entry:
 %r = xor i64 %value,1311768467463790560
 ret i64 %r
}
define ptr @function_alignment_get_16() {
entry:
 ret ptr @function_alignment_target_16
}
define i64 @function_alignment_probe_16(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_16 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_16,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,255
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_16(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_17 = alias i64 (i64),ptr @function_alignment_target_17
@function_alignment_dispatch_17 = internal global ptr @function_alignment_target_17,align 8
define internal fastcc i64 @function_alignment_target_17(i64 %value) noinline align 256 {
entry:
 %r = xor i64 %value,1311768467463790545
 ret i64 %r
}
define ptr @function_alignment_get_17() {
entry:
 ret ptr @function_alignment_target_17
}
define i64 @function_alignment_probe_17(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_17 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_17,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,255
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_17(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_18 = alias i64 (i64),ptr @function_alignment_target_18
@function_alignment_dispatch_18 = internal global ptr @function_alignment_target_18,align 8
define internal i64 @function_alignment_target_18(i64 %value) noinline align 512 {
entry:
 %r = xor i64 %value,1311768467463790530
 ret i64 %r
}
define ptr @function_alignment_get_18() {
entry:
 ret ptr @function_alignment_target_18
}
define i64 @function_alignment_probe_18(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_18 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_18,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,511
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_18(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_19 = alias i64 (i64),ptr @function_alignment_target_19
@function_alignment_dispatch_19 = internal global ptr @function_alignment_target_19,align 8
define internal fastcc i64 @function_alignment_target_19(i64 %value) noinline align 512 {
entry:
 %r = xor i64 %value,1311768467463790515
 ret i64 %r
}
define ptr @function_alignment_get_19() {
entry:
 ret ptr @function_alignment_target_19
}
define i64 @function_alignment_probe_19(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_19 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_19,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,511
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_19(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_20 = alias i64 (i64),ptr @function_alignment_target_20
@function_alignment_dispatch_20 = internal global ptr @function_alignment_target_20,align 8
define internal i64 @function_alignment_target_20(i64 %value) noinline align 1024 {
entry:
 %r = xor i64 %value,1311768467463790500
 ret i64 %r
}
define ptr @function_alignment_get_20() {
entry:
 ret ptr @function_alignment_target_20
}
define i64 @function_alignment_probe_20(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_20 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_20,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,1023
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_20(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_21 = alias i64 (i64),ptr @function_alignment_target_21
@function_alignment_dispatch_21 = internal global ptr @function_alignment_target_21,align 8
define internal fastcc i64 @function_alignment_target_21(i64 %value) noinline align 1024 {
entry:
 %r = xor i64 %value,1311768467463790485
 ret i64 %r
}
define ptr @function_alignment_get_21() {
entry:
 ret ptr @function_alignment_target_21
}
define i64 @function_alignment_probe_21(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_21 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_21,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,1023
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_21(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_22 = alias i64 (i64),ptr @function_alignment_target_22
@function_alignment_dispatch_22 = internal global ptr @function_alignment_target_22,align 8
define internal i64 @function_alignment_target_22(i64 %value) noinline align 2048 {
entry:
 %r = xor i64 %value,1311768467463790470
 ret i64 %r
}
define ptr @function_alignment_get_22() {
entry:
 ret ptr @function_alignment_target_22
}
define i64 @function_alignment_probe_22(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_22 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_22,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,2047
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_22(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_23 = alias i64 (i64),ptr @function_alignment_target_23
@function_alignment_dispatch_23 = internal global ptr @function_alignment_target_23,align 8
define internal fastcc i64 @function_alignment_target_23(i64 %value) noinline align 2048 {
entry:
 %r = xor i64 %value,1311768467463790455
 ret i64 %r
}
define ptr @function_alignment_get_23() {
entry:
 ret ptr @function_alignment_target_23
}
define i64 @function_alignment_probe_23(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_23 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_23,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,2047
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_23(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_24 = alias i64 (i64),ptr @function_alignment_target_24
@function_alignment_dispatch_24 = internal global ptr @function_alignment_target_24,align 8
define internal i64 @function_alignment_target_24(i64 %value) noinline align 4096 {
entry:
 %r = xor i64 %value,1311768467463790440
 ret i64 %r
}
define ptr @function_alignment_get_24() {
entry:
 ret ptr @function_alignment_target_24
}
define i64 @function_alignment_probe_24(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_24 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_24,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,4095
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call i64 @function_alignment_target_24(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
@function_alignment_alias_25 = alias i64 (i64),ptr @function_alignment_target_25
@function_alignment_dispatch_25 = internal global ptr @function_alignment_target_25,align 8
define internal fastcc i64 @function_alignment_target_25(i64 %value) noinline align 4096 {
entry:
 %r = xor i64 %value,1311768467463790425
 ret i64 %r
}
define ptr @function_alignment_get_25() {
entry:
 ret ptr @function_alignment_target_25
}
define i64 @function_alignment_probe_25(ptr %out,ptr %unused,ptr %other,i64 %salt) {
entry:
 %target = ptrtoint ptr @function_alignment_target_25 to i64
 %dispatch = load ptr,ptr @function_alignment_dispatch_25,align 8
 %loaded = ptrtoint ptr %dispatch to i64
 %low = and i64 %target,4095
 %same_dispatch = xor i64 %loaded,%target
 store i64 %low,ptr %out,align 1
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %same_dispatch,ptr %p1,align 1
 %direct = call fastcc i64 @function_alignment_target_25(i64 %salt)
 %second = xor i64 %salt,40926266145
 %indirect = call fastcc i64 %dispatch(i64 %second)
 %triple = mul i64 %indirect,3
 %r = add i64 %direct,%triple
 ret i64 %r
}
