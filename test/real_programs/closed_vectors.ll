target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)
declare void @llvm.memset.p0.i64(ptr,i8,i64,i1)
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare i1 @llvm.vector.reduce.or.v64i1(<64 x i1>)
define internal fastcc i64 @closed.vector.compare.8(ptr %out,<64 x i4> %counts,<64 x i32> %expected) noinline {
entry:
 %wide = zext <64 x i4> %counts to <64 x i32>
 store <64 x i32> %wide,ptr %out,align 1
 %different = icmp ne <64 x i32> %wide,%expected
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %different)
 %r = zext i1 %any to i64
 ret i64 %r
}
declare <64 x i8> @llvm.cttz.v64i8(<64 x i8>,i1)
define internal fastcc i64 @closed.vector.body.0(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i8>,align 64
 store <64 x i8> %input,ptr %local,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i8>,ptr %local,align 64
 %counts = call <64 x i8> @llvm.cttz.v64i8(<64 x i8> %round,i1 0)
 %small = trunc <64 x i8> %counts to <64 x i4>
 %check = call fastcc i64 @closed.vector.compare.8(ptr %out,<64 x i4> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i8> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,63
 %ap = getelementptr i8,ptr %out,i64 320
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_0(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.0(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.body.1(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i8>,align 64
 store <64 x i8> %input,ptr %local,align 64
 store <64 x i8> zeroinitializer,ptr %source,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i8>,ptr %local,align 64
 %counts = call <64 x i8> @llvm.cttz.v64i8(<64 x i8> %round,i1 0)
 %small = trunc <64 x i8> %counts to <64 x i4>
 %check = call fastcc i64 @closed.vector.compare.8(ptr %out,<64 x i4> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i8> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,63
 %ap = getelementptr i8,ptr %out,i64 320
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_1(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.1(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
declare <64 x i8> @llvm.ctlz.v64i8(<64 x i8>,i1)
define internal fastcc i64 @closed.vector.body.2(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i8>,align 64
 store <64 x i8> %input,ptr %local,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i8>,ptr %local,align 64
 %counts = call <64 x i8> @llvm.ctlz.v64i8(<64 x i8> %round,i1 0)
 %small = trunc <64 x i8> %counts to <64 x i4>
 %check = call fastcc i64 @closed.vector.compare.8(ptr %out,<64 x i4> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i8> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,63
 %ap = getelementptr i8,ptr %out,i64 320
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_2(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.2(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.body.3(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i8>,align 64
 store <64 x i8> %input,ptr %local,align 64
 store <64 x i8> zeroinitializer,ptr %source,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i8>,ptr %local,align 64
 %counts = call <64 x i8> @llvm.ctlz.v64i8(<64 x i8> %round,i1 0)
 %small = trunc <64 x i8> %counts to <64 x i4>
 %check = call fastcc i64 @closed.vector.compare.8(ptr %out,<64 x i4> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i8> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,63
 %ap = getelementptr i8,ptr %out,i64 320
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_3(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i8>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.3(ptr %out,<64 x i8> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.compare.16(ptr %out,<64 x i5> %counts,<64 x i32> %expected) noinline {
entry:
 %wide = zext <64 x i5> %counts to <64 x i32>
 store <64 x i32> %wide,ptr %out,align 1
 %different = icmp ne <64 x i32> %wide,%expected
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %different)
 %r = zext i1 %any to i64
 ret i64 %r
}
declare <64 x i16> @llvm.cttz.v64i16(<64 x i16>,i1)
define internal fastcc i64 @closed.vector.body.4(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i16>,align 128
 store <64 x i16> %input,ptr %local,align 128
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i16>,ptr %local,align 128
 %counts = call <64 x i16> @llvm.cttz.v64i16(<64 x i16> %round,i1 0)
 %small = trunc <64 x i16> %counts to <64 x i5>
 %check = call fastcc i64 @closed.vector.compare.16(ptr %out,<64 x i5> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i16> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,127
 %ap = getelementptr i8,ptr %out,i64 384
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_4(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i16>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.4(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.body.5(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i16>,align 128
 store <64 x i16> %input,ptr %local,align 128
 store <64 x i16> zeroinitializer,ptr %source,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i16>,ptr %local,align 128
 %counts = call <64 x i16> @llvm.cttz.v64i16(<64 x i16> %round,i1 0)
 %small = trunc <64 x i16> %counts to <64 x i5>
 %check = call fastcc i64 @closed.vector.compare.16(ptr %out,<64 x i5> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i16> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,127
 %ap = getelementptr i8,ptr %out,i64 384
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_5(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i16>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.5(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
declare <64 x i16> @llvm.ctlz.v64i16(<64 x i16>,i1)
define internal fastcc i64 @closed.vector.body.6(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i16>,align 128
 store <64 x i16> %input,ptr %local,align 128
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i16>,ptr %local,align 128
 %counts = call <64 x i16> @llvm.ctlz.v64i16(<64 x i16> %round,i1 0)
 %small = trunc <64 x i16> %counts to <64 x i5>
 %check = call fastcc i64 @closed.vector.compare.16(ptr %out,<64 x i5> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i16> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,127
 %ap = getelementptr i8,ptr %out,i64 384
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_6(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i16>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.6(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.body.7(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i16>,align 128
 store <64 x i16> %input,ptr %local,align 128
 store <64 x i16> zeroinitializer,ptr %source,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i16>,ptr %local,align 128
 %counts = call <64 x i16> @llvm.ctlz.v64i16(<64 x i16> %round,i1 0)
 %small = trunc <64 x i16> %counts to <64 x i5>
 %check = call fastcc i64 @closed.vector.compare.16(ptr %out,<64 x i5> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i16> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,127
 %ap = getelementptr i8,ptr %out,i64 384
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_7(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i16>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.7(ptr %out,<64 x i16> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.compare.128(ptr %out,<64 x i8> %counts,<64 x i32> %expected) noinline {
entry:
 %wide = zext <64 x i8> %counts to <64 x i32>
 store <64 x i32> %wide,ptr %out,align 1
 %different = icmp ne <64 x i32> %wide,%expected
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %different)
 %r = zext i1 %any to i64
 ret i64 %r
}
declare <64 x i128> @llvm.cttz.v64i128(<64 x i128>,i1)
define internal fastcc i64 @closed.vector.body.8(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i128>,align 1024
 store <64 x i128> %input,ptr %local,align 1024
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i128>,ptr %local,align 1024
 %counts = call <64 x i128> @llvm.cttz.v64i128(<64 x i128> %round,i1 0)
 %small = trunc <64 x i128> %counts to <64 x i8>
 %check = call fastcc i64 @closed.vector.compare.128(ptr %out,<64 x i8> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i128> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,1023
 %ap = getelementptr i8,ptr %out,i64 1280
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_8(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i128>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.8(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.body.9(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i128>,align 1024
 store <64 x i128> %input,ptr %local,align 1024
 store <64 x i128> zeroinitializer,ptr %source,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i128>,ptr %local,align 1024
 %counts = call <64 x i128> @llvm.cttz.v64i128(<64 x i128> %round,i1 0)
 %small = trunc <64 x i128> %counts to <64 x i8>
 %check = call fastcc i64 @closed.vector.compare.128(ptr %out,<64 x i8> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i128> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,1023
 %ap = getelementptr i8,ptr %out,i64 1280
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_9(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i128>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.9(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
declare <64 x i128> @llvm.ctlz.v64i128(<64 x i128>,i1)
define internal fastcc i64 @closed.vector.body.10(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i128>,align 1024
 store <64 x i128> %input,ptr %local,align 1024
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i128>,ptr %local,align 1024
 %counts = call <64 x i128> @llvm.ctlz.v64i128(<64 x i128> %round,i1 0)
 %small = trunc <64 x i128> %counts to <64 x i8>
 %check = call fastcc i64 @closed.vector.compare.128(ptr %out,<64 x i8> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i128> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,1023
 %ap = getelementptr i8,ptr %out,i64 1280
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_10(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i128>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.10(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
define internal fastcc i64 @closed.vector.body.11(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt) noinline {
entry:
 %local = alloca <64 x i128>,align 1024
 store <64 x i128> %input,ptr %local,align 1024
 store <64 x i128> zeroinitializer,ptr %source,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %round = load <64 x i128>,ptr %local,align 1024
 %counts = call <64 x i128> @llvm.ctlz.v64i128(<64 x i128> %round,i1 0)
 %small = trunc <64 x i128> %counts to <64 x i8>
 %check = call fastcc i64 @closed.vector.compare.128(ptr %out,<64 x i8> %small,<64 x i32> %expected)
 %payload = getelementptr i8,ptr %out,i64 256
 store <64 x i128> %round,ptr %payload,align 1
 %bits = ptrtoint ptr %local to i64
 %low = and i64 %bits,1023
 %ap = getelementptr i8,ptr %out,i64 1280
 store i64 %low,ptr %ap,align 1
 %r = xor i64 %token,%check
 ret i64 %r
}
define i64 @closed_vectors_probe_11(ptr %out,ptr %source,ptr %expected_ptr,i64 %salt) {
entry:
 %input = load <64 x i128>,ptr %source,align 1
 %expected = load <64 x i32>,ptr %expected_ptr,align 1
 %r = call fastcc i64 @closed.vector.body.11(ptr %out,<64 x i128> %input,<64 x i32> %expected,ptr %source,i64 %salt)
 ret i64 %r
}
