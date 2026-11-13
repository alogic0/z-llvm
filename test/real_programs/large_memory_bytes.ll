target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)
declare void @llvm.memset.p0.i64(ptr,i8,i64,i1)
define i64 @large_memory_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i1025>,align 8192
 %old = load i1025,ptr %source,align 1
 %vector = insertelement <1 x i1025> poison,i1025 %old,i32 0
 store <1 x i1025> %vector,ptr %local,align 1
 %loaded = load <1 x i1025>,ptr %local,align 1
 %round = extractelement <1 x i1025> %loaded,i32 0
 %extended = zext i1025 %old to i65536
 %back = trunc nuw i65536 %extended to i1025
 %same = icmp eq i1025 %round,%back
 store i1025 %round,ptr %out,align 1
 %ones = icmp eq i1025 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 129
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i1025>,align 8192
 %old = load i1025,ptr %source,align 1
 store i1025 0,ptr %source,align 1
 %vector = insertelement <1 x i1025> poison,i1025 %old,i32 0
 store <1 x i1025> %vector,ptr %local,align 1
 %loaded = load <1 x i1025>,ptr %local,align 1
 %round = extractelement <1 x i1025> %loaded,i32 0
 %extended = zext i1025 %old to i65536
 %back = trunc nuw i65536 %extended to i1025
 %same = icmp eq i1025 %round,%back
 store i1025 %round,ptr %out,align 1
 %ones = icmp eq i1025 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 129
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i2047>,align 8192
 %old = load i2047,ptr %source,align 1
 %vector = insertelement <1 x i2047> poison,i2047 %old,i32 0
 store <1 x i2047> %vector,ptr %local,align 1
 %loaded = load <1 x i2047>,ptr %local,align 1
 %round = extractelement <1 x i2047> %loaded,i32 0
 %extended = zext i2047 %old to i65536
 %back = trunc nuw i65536 %extended to i2047
 %same = icmp eq i2047 %round,%back
 store i2047 %round,ptr %out,align 1
 %ones = icmp eq i2047 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 256
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i2047>,align 8192
 %old = load i2047,ptr %source,align 1
 store i2047 0,ptr %source,align 1
 %vector = insertelement <1 x i2047> poison,i2047 %old,i32 0
 store <1 x i2047> %vector,ptr %local,align 1
 %loaded = load <1 x i2047>,ptr %local,align 1
 %round = extractelement <1 x i2047> %loaded,i32 0
 %extended = zext i2047 %old to i65536
 %back = trunc nuw i65536 %extended to i2047
 %same = icmp eq i2047 %round,%back
 store i2047 %round,ptr %out,align 1
 %ones = icmp eq i2047 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 256
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i4095>,align 8192
 %old = load i4095,ptr %source,align 1
 %vector = insertelement <1 x i4095> poison,i4095 %old,i32 0
 store <1 x i4095> %vector,ptr %local,align 1
 %loaded = load <1 x i4095>,ptr %local,align 1
 %round = extractelement <1 x i4095> %loaded,i32 0
 %extended = zext i4095 %old to i65536
 %back = trunc nuw i65536 %extended to i4095
 %same = icmp eq i4095 %round,%back
 store i4095 %round,ptr %out,align 1
 %ones = icmp eq i4095 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 512
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i4095>,align 8192
 %old = load i4095,ptr %source,align 1
 store i4095 0,ptr %source,align 1
 %vector = insertelement <1 x i4095> poison,i4095 %old,i32 0
 store <1 x i4095> %vector,ptr %local,align 1
 %loaded = load <1 x i4095>,ptr %local,align 1
 %round = extractelement <1 x i4095> %loaded,i32 0
 %extended = zext i4095 %old to i65536
 %back = trunc nuw i65536 %extended to i4095
 %same = icmp eq i4095 %round,%back
 store i4095 %round,ptr %out,align 1
 %ones = icmp eq i4095 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 512
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i65528>,align 8192
 %old = load i65528,ptr %source,align 1
 %vector = insertelement <1 x i65528> poison,i65528 %old,i32 0
 store <1 x i65528> %vector,ptr %local,align 1
 %loaded = load <1 x i65528>,ptr %local,align 1
 %round = extractelement <1 x i65528> %loaded,i32 0
 %extended = zext i65528 %old to i65536
 %back = trunc nuw i65536 %extended to i65528
 %same = icmp eq i65528 %round,%back
 store i65528 %round,ptr %out,align 1
 %ones = icmp eq i65528 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8191
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i65528>,align 8192
 %old = load i65528,ptr %source,align 1
 store i65528 0,ptr %source,align 1
 %vector = insertelement <1 x i65528> poison,i65528 %old,i32 0
 store <1 x i65528> %vector,ptr %local,align 1
 %loaded = load <1 x i65528>,ptr %local,align 1
 %round = extractelement <1 x i65528> %loaded,i32 0
 %extended = zext i65528 %old to i65536
 %back = trunc nuw i65536 %extended to i65528
 %same = icmp eq i65528 %round,%back
 store i65528 %round,ptr %out,align 1
 %ones = icmp eq i65528 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8191
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i65529>,align 8192
 %old = load i65529,ptr %source,align 1
 %vector = insertelement <1 x i65529> poison,i65529 %old,i32 0
 store <1 x i65529> %vector,ptr %local,align 1
 %loaded = load <1 x i65529>,ptr %local,align 1
 %round = extractelement <1 x i65529> %loaded,i32 0
 %extended = zext i65529 %old to i65536
 %back = trunc nuw i65536 %extended to i65529
 %same = icmp eq i65529 %round,%back
 store i65529 %round,ptr %out,align 1
 %ones = icmp eq i65529 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8192
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i65529>,align 8192
 %old = load i65529,ptr %source,align 1
 store i65529 0,ptr %source,align 1
 %vector = insertelement <1 x i65529> poison,i65529 %old,i32 0
 store <1 x i65529> %vector,ptr %local,align 1
 %loaded = load <1 x i65529>,ptr %local,align 1
 %round = extractelement <1 x i65529> %loaded,i32 0
 %extended = zext i65529 %old to i65536
 %back = trunc nuw i65536 %extended to i65529
 %same = icmp eq i65529 %round,%back
 store i65529 %round,ptr %out,align 1
 %ones = icmp eq i65529 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8192
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i65535>,align 8192
 %old = load i65535,ptr %source,align 1
 %vector = insertelement <1 x i65535> poison,i65535 %old,i32 0
 store <1 x i65535> %vector,ptr %local,align 1
 %loaded = load <1 x i65535>,ptr %local,align 1
 %round = extractelement <1 x i65535> %loaded,i32 0
 %extended = zext i65535 %old to i65536
 %back = trunc nuw i65536 %extended to i65535
 %same = icmp eq i65535 %round,%back
 store i65535 %round,ptr %out,align 1
 %ones = icmp eq i65535 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8192
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca <1 x i65535>,align 8192
 %old = load i65535,ptr %source,align 1
 store i65535 0,ptr %source,align 1
 %vector = insertelement <1 x i65535> poison,i65535 %old,i32 0
 store <1 x i65535> %vector,ptr %local,align 1
 %loaded = load <1 x i65535>,ptr %local,align 1
 %round = extractelement <1 x i65535> %loaded,i32 0
 %extended = zext i65535 %old to i65536
 %back = trunc nuw i65536 %extended to i65535
 %same = icmp eq i65535 %round,%back
 store i65535 %round,ptr %out,align 1
 %ones = icmp eq i65535 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8192
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca i65536,align 8192
 %old = load i65536,ptr %source,align 1
 store i65536 %old,ptr %local,align 1
 %round = load i65536,ptr %local,align 1
 %same = icmp eq i65536 %round,%old
 store i65536 %round,ptr %out,align 1
 %ones = icmp eq i65536 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8192
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
define i64 @large_memory_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %local = alloca i65536,align 8192
 %old = load i65536,ptr %source,align 1
 store i65536 0,ptr %source,align 1
 store i65536 %old,ptr %local,align 1
 %round = load i65536,ptr %local,align 1
 %same = icmp eq i65536 %round,%old
 store i65536 %round,ptr %out,align 1
 %ones = icmp eq i65536 %old,-1
 %mismatch = xor i1 %same,true
 %bad = zext i1 %mismatch to i64
 %bad2 = shl i64 %bad,1
 %isones = zext i1 %ones to i64
 %flags = or i64 %bad2,%isones
 %r = xor i64 %salt,%flags
 %address = ptrtoint ptr %local to i64
 %low = and i64 %address,8191
 %ap = getelementptr i8,ptr %out,i64 8192
 store i64 %low,ptr %ap,align 1
 ret i64 %r
}
