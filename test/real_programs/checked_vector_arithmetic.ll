target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i1 @llvm.vector.reduce.or.v2i1(<2 x i1>)
declare {<2 x i32>,<2 x i1>} @llvm.uadd.with.overflow.v2i32(<2 x i32>,<2 x i32>)
define i64 @checked_vector_body_0(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.uadd.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_0(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_0(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_1(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.uadd.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_1(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_1(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_2(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.uadd.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_2(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_2(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_3(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.uadd.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_3(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_3(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i32>,<2 x i1>} @llvm.usub.with.overflow.v2i32(<2 x i32>,<2 x i32>)
define i64 @checked_vector_body_4(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.usub.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_4(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_4(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_5(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.usub.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_5(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_5(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_6(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.usub.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_6(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_6(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_7(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.usub.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_7(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_7(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i32>,<2 x i1>} @llvm.umul.with.overflow.v2i32(<2 x i32>,<2 x i32>)
define i64 @checked_vector_body_8(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.umul.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_8(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_8(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_9(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.umul.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_9(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_9(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_10(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.umul.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_10(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_10(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_11(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.umul.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_11(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_11(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i32>,<2 x i1>} @llvm.sadd.with.overflow.v2i32(<2 x i32>,<2 x i32>)
define i64 @checked_vector_body_12(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.sadd.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_12(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_12(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_13(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.sadd.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_13(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_13(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_14(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.sadd.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_14(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_14(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_15(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.sadd.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_15(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_15(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i32>,<2 x i1>} @llvm.ssub.with.overflow.v2i32(<2 x i32>,<2 x i32>)
define i64 @checked_vector_body_16(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.ssub.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_16(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_16(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_17(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.ssub.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_17(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_17(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_18(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.ssub.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_18(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_18(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_19(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.ssub.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_19(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_19(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i32>,<2 x i1>} @llvm.smul.with.overflow.v2i32(<2 x i32>,<2 x i32>)
define i64 @checked_vector_body_20(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.smul.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_20(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_20(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_21(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.smul.with.overflow.v2i32(<2 x i32> %x,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_21(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_21(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_22(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.smul.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_22(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_22(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_23(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i32>,ptr %a,align 1
 %y = load <2 x i32>,ptr %b,align 1
 %pair = call {<2 x i32>,<2 x i1>} @llvm.smul.with.overflow.v2i32(<2 x i32> zeroinitializer,<2 x i32> %y)
 %v = extractvalue {<2 x i32>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i32>,<2 x i1>} %pair,1
 store <2 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_23(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_23(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v3i1(<3 x i1>)
declare {<3 x i32>,<3 x i1>} @llvm.uadd.with.overflow.v3i32(<3 x i32>,<3 x i32>)
define i64 @checked_vector_body_24(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.uadd.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_24(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_24(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_25(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.uadd.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_25(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_25(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i32>,<3 x i1>} @llvm.usub.with.overflow.v3i32(<3 x i32>,<3 x i32>)
define i64 @checked_vector_body_26(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.usub.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_26(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_26(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_27(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.usub.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_27(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_27(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i32>,<3 x i1>} @llvm.umul.with.overflow.v3i32(<3 x i32>,<3 x i32>)
define i64 @checked_vector_body_28(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.umul.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_28(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_28(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_29(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.umul.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_29(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_29(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i32>,<3 x i1>} @llvm.sadd.with.overflow.v3i32(<3 x i32>,<3 x i32>)
define i64 @checked_vector_body_30(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.sadd.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_30(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_30(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_31(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.sadd.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_31(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_31(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i32>,<3 x i1>} @llvm.ssub.with.overflow.v3i32(<3 x i32>,<3 x i32>)
define i64 @checked_vector_body_32(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.ssub.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_32(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_32(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_33(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.ssub.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_33(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_33(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i32>,<3 x i1>} @llvm.smul.with.overflow.v3i32(<3 x i32>,<3 x i32>)
define i64 @checked_vector_body_34(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.smul.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_34(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_34(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_35(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <3 x i32>,ptr %a,align 1
 %y = load <3 x i32>,ptr %b,align 1
 %pair = call {<3 x i32>,<3 x i1>} @llvm.smul.with.overflow.v3i32(<3 x i32> %x,<3 x i32> %y)
 %v = extractvalue {<3 x i32>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i32>,<3 x i1>} %pair,1
 store <3 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 12
 store <3 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_35(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_35(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v4i1(<4 x i1>)
declare {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8>,<4 x i8>)
define i64 @checked_vector_body_36(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_36(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_36(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_37(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_37(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_37(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_38(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_38(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_38(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_39(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.uadd.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_39(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_39(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i8>,<4 x i1>} @llvm.usub.with.overflow.v4i8(<4 x i8>,<4 x i8>)
define i64 @checked_vector_body_40(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.usub.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_40(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_40(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_41(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.usub.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_41(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_41(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_42(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.usub.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_42(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_42(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_43(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.usub.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_43(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_43(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i8>,<4 x i1>} @llvm.umul.with.overflow.v4i8(<4 x i8>,<4 x i8>)
define i64 @checked_vector_body_44(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.umul.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_44(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_44(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_45(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.umul.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_45(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_45(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_46(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.umul.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_46(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_46(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_47(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.umul.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_47(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_47(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i8>,<4 x i1>} @llvm.sadd.with.overflow.v4i8(<4 x i8>,<4 x i8>)
define i64 @checked_vector_body_48(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.sadd.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_48(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_48(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_49(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.sadd.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_49(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_49(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_50(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.sadd.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_50(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_50(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_51(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.sadd.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_51(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_51(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i8>,<4 x i1>} @llvm.ssub.with.overflow.v4i8(<4 x i8>,<4 x i8>)
define i64 @checked_vector_body_52(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.ssub.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_52(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_52(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_53(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.ssub.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_53(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_53(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_54(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.ssub.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_54(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_54(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_55(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.ssub.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_55(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_55(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i8>,<4 x i1>} @llvm.smul.with.overflow.v4i8(<4 x i8>,<4 x i8>)
define i64 @checked_vector_body_56(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.smul.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_56(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_56(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_57(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.smul.with.overflow.v4i8(<4 x i8> %x,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_57(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_57(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define i64 @checked_vector_body_58(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.smul.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_58(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_58(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_59(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i8>,ptr %a,align 1
 %y = load <4 x i8>,ptr %b,align 1
 %pair = call {<4 x i8>,<4 x i1>} @llvm.smul.with.overflow.v4i8(<4 x i8> zeroinitializer,<4 x i8> %y)
 %v = extractvalue {<4 x i8>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i8>,<4 x i1>} %pair,1
 store <4 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_59(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_59(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i8>,<2 x i1>} @llvm.uadd.with.overflow.v2i8(<2 x i8>,<2 x i8>)
define i64 @checked_vector_body_60(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.uadd.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_60(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_60(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_61(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.uadd.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_61(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_61(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i8>,<2 x i1>} @llvm.usub.with.overflow.v2i8(<2 x i8>,<2 x i8>)
define i64 @checked_vector_body_62(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.usub.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_62(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_62(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_63(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.usub.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_63(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_63(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i8>,<2 x i1>} @llvm.umul.with.overflow.v2i8(<2 x i8>,<2 x i8>)
define i64 @checked_vector_body_64(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.umul.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_64(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_64(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_65(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.umul.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_65(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_65(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i8>,<2 x i1>} @llvm.sadd.with.overflow.v2i8(<2 x i8>,<2 x i8>)
define i64 @checked_vector_body_66(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.sadd.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_66(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_66(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_67(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.sadd.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_67(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_67(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i8>,<2 x i1>} @llvm.ssub.with.overflow.v2i8(<2 x i8>,<2 x i8>)
define i64 @checked_vector_body_68(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.ssub.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_68(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_68(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_69(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.ssub.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_69(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_69(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i8>,<2 x i1>} @llvm.smul.with.overflow.v2i8(<2 x i8>,<2 x i8>)
define i64 @checked_vector_body_70(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.smul.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_70(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_70(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_71(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <2 x i8>,ptr %a,align 1
 %y = load <2 x i8>,ptr %b,align 1
 %pair = call {<2 x i8>,<2 x i1>} @llvm.smul.with.overflow.v2i8(<2 x i8> %x,<2 x i8> %y)
 %v = extractvalue {<2 x i8>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i8>,<2 x i1>} %pair,1
 store <2 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_71(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_71(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i16>,<4 x i1>} @llvm.uadd.with.overflow.v4i16(<4 x i16>,<4 x i16>)
define i64 @checked_vector_body_72(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.uadd.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_72(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_72(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_73(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.uadd.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_73(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_73(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i16>,<4 x i1>} @llvm.usub.with.overflow.v4i16(<4 x i16>,<4 x i16>)
define i64 @checked_vector_body_74(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.usub.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_74(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_74(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_75(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.usub.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_75(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_75(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i16>,<4 x i1>} @llvm.umul.with.overflow.v4i16(<4 x i16>,<4 x i16>)
define i64 @checked_vector_body_76(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.umul.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_76(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_76(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_77(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.umul.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_77(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_77(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i16>,<4 x i1>} @llvm.sadd.with.overflow.v4i16(<4 x i16>,<4 x i16>)
define i64 @checked_vector_body_78(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.sadd.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_78(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_78(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_79(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.sadd.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_79(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_79(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i16>,<4 x i1>} @llvm.ssub.with.overflow.v4i16(<4 x i16>,<4 x i16>)
define i64 @checked_vector_body_80(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.ssub.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_80(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_80(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_81(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.ssub.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_81(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_81(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i16>,<4 x i1>} @llvm.smul.with.overflow.v4i16(<4 x i16>,<4 x i16>)
define i64 @checked_vector_body_82(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.smul.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_82(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_82(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_83(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i16>,ptr %a,align 1
 %y = load <4 x i16>,ptr %b,align 1
 %pair = call {<4 x i16>,<4 x i1>} @llvm.smul.with.overflow.v4i16(<4 x i16> %x,<4 x i16> %y)
 %v = extractvalue {<4 x i16>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i16>,<4 x i1>} %pair,1
 store <4 x i16> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_83(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_83(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v8i1(<8 x i1>)
declare {<8 x i8>,<8 x i1>} @llvm.uadd.with.overflow.v8i8(<8 x i8>,<8 x i8>)
define i64 @checked_vector_body_84(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.uadd.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_84(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_84(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_85(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.uadd.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_85(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_85(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i8>,<8 x i1>} @llvm.usub.with.overflow.v8i8(<8 x i8>,<8 x i8>)
define i64 @checked_vector_body_86(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.usub.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_86(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_86(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_87(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.usub.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_87(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_87(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i8>,<8 x i1>} @llvm.umul.with.overflow.v8i8(<8 x i8>,<8 x i8>)
define i64 @checked_vector_body_88(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.umul.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_88(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_88(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_89(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.umul.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_89(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_89(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i8>,<8 x i1>} @llvm.sadd.with.overflow.v8i8(<8 x i8>,<8 x i8>)
define i64 @checked_vector_body_90(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.sadd.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_90(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_90(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_91(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.sadd.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_91(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_91(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i8>,<8 x i1>} @llvm.ssub.with.overflow.v8i8(<8 x i8>,<8 x i8>)
define i64 @checked_vector_body_92(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.ssub.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_92(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_92(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_93(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.ssub.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_93(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_93(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i8>,<8 x i1>} @llvm.smul.with.overflow.v8i8(<8 x i8>,<8 x i8>)
define i64 @checked_vector_body_94(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.smul.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_94(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_94(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_95(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i8>,ptr %a,align 1
 %y = load <8 x i8>,ptr %b,align 1
 %pair = call {<8 x i8>,<8 x i1>} @llvm.smul.with.overflow.v8i8(<8 x i8> %x,<8 x i8> %y)
 %v = extractvalue {<8 x i8>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i8>,<8 x i1>} %pair,1
 store <8 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_95(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_95(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i32>,<4 x i1>} @llvm.uadd.with.overflow.v4i32(<4 x i32>,<4 x i32>)
define i64 @checked_vector_body_96(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.uadd.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_96(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_96(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_97(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.uadd.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_97(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_97(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i32>,<4 x i1>} @llvm.usub.with.overflow.v4i32(<4 x i32>,<4 x i32>)
define i64 @checked_vector_body_98(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.usub.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_98(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_98(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_99(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.usub.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_99(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_99(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i32>,<4 x i1>} @llvm.umul.with.overflow.v4i32(<4 x i32>,<4 x i32>)
define i64 @checked_vector_body_100(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.umul.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_100(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_100(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_101(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.umul.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_101(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_101(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i32>,<4 x i1>} @llvm.sadd.with.overflow.v4i32(<4 x i32>,<4 x i32>)
define i64 @checked_vector_body_102(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.sadd.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_102(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_102(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_103(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.sadd.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_103(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_103(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i32>,<4 x i1>} @llvm.ssub.with.overflow.v4i32(<4 x i32>,<4 x i32>)
define i64 @checked_vector_body_104(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.ssub.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_104(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_104(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_105(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.ssub.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_105(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_105(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i32>,<4 x i1>} @llvm.smul.with.overflow.v4i32(<4 x i32>,<4 x i32>)
define i64 @checked_vector_body_106(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.smul.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_106(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_106(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_107(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <4 x i32>,ptr %a,align 1
 %y = load <4 x i32>,ptr %b,align 1
 %pair = call {<4 x i32>,<4 x i1>} @llvm.smul.with.overflow.v4i32(<4 x i32> %x,<4 x i32> %y)
 %v = extractvalue {<4 x i32>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i32>,<4 x i1>} %pair,1
 store <4 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_107(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_107(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i32>,<8 x i1>} @llvm.uadd.with.overflow.v8i32(<8 x i32>,<8 x i32>)
define i64 @checked_vector_body_108(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.uadd.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_108(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_108(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_109(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.uadd.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_109(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_109(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i32>,<8 x i1>} @llvm.usub.with.overflow.v8i32(<8 x i32>,<8 x i32>)
define i64 @checked_vector_body_110(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.usub.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_110(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_110(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_111(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.usub.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_111(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_111(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i32>,<8 x i1>} @llvm.umul.with.overflow.v8i32(<8 x i32>,<8 x i32>)
define i64 @checked_vector_body_112(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.umul.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_112(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_112(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_113(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.umul.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_113(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_113(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i32>,<8 x i1>} @llvm.sadd.with.overflow.v8i32(<8 x i32>,<8 x i32>)
define i64 @checked_vector_body_114(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.sadd.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_114(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_114(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_115(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.sadd.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_115(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_115(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i32>,<8 x i1>} @llvm.ssub.with.overflow.v8i32(<8 x i32>,<8 x i32>)
define i64 @checked_vector_body_116(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.ssub.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_116(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_116(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_117(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.ssub.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_117(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_117(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i32>,<8 x i1>} @llvm.smul.with.overflow.v8i32(<8 x i32>,<8 x i32>)
define i64 @checked_vector_body_118(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.smul.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_118(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_118(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_119(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <8 x i32>,ptr %a,align 1
 %y = load <8 x i32>,ptr %b,align 1
 %pair = call {<8 x i32>,<8 x i1>} @llvm.smul.with.overflow.v8i32(<8 x i32> %x,<8 x i32> %y)
 %v = extractvalue {<8 x i32>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i32>,<8 x i1>} %pair,1
 store <8 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 32
 store <8 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_119(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_119(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v1i1(<1 x i1>)
declare {<1 x i8>,<1 x i1>} @llvm.uadd.with.overflow.v1i8(<1 x i8>,<1 x i8>)
define i64 @checked_vector_body_120(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.uadd.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_120(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_120(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_121(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.uadd.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_121(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_121(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i8>,<1 x i1>} @llvm.usub.with.overflow.v1i8(<1 x i8>,<1 x i8>)
define i64 @checked_vector_body_122(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.usub.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_122(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_122(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_123(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.usub.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_123(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_123(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i8>,<1 x i1>} @llvm.umul.with.overflow.v1i8(<1 x i8>,<1 x i8>)
define i64 @checked_vector_body_124(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.umul.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_124(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_124(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_125(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.umul.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_125(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_125(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i8>,<1 x i1>} @llvm.sadd.with.overflow.v1i8(<1 x i8>,<1 x i8>)
define i64 @checked_vector_body_126(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.sadd.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_126(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_126(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_127(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.sadd.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_127(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_127(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i8>,<1 x i1>} @llvm.ssub.with.overflow.v1i8(<1 x i8>,<1 x i8>)
define i64 @checked_vector_body_128(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.ssub.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_128(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_128(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_129(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.ssub.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_129(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_129(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i8>,<1 x i1>} @llvm.smul.with.overflow.v1i8(<1 x i8>,<1 x i8>)
define i64 @checked_vector_body_130(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.smul.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_130(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_130(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_131(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <1 x i8>,ptr %a,align 1
 %y = load <1 x i8>,ptr %b,align 1
 %pair = call {<1 x i8>,<1 x i1>} @llvm.smul.with.overflow.v1i8(<1 x i8> %x,<1 x i8> %y)
 %v = extractvalue {<1 x i8>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i8>,<1 x i1>} %pair,1
 store <1 x i8> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_131(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_131(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v64i1(<64 x i1>)
declare {<64 x i32>,<64 x i1>} @llvm.uadd.with.overflow.v64i32(<64 x i32>,<64 x i32>)
define i64 @checked_vector_body_132(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.uadd.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_132(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_132(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_133(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.uadd.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_133(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_133(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i32>,<64 x i1>} @llvm.usub.with.overflow.v64i32(<64 x i32>,<64 x i32>)
define i64 @checked_vector_body_134(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.usub.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_134(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_134(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_135(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.usub.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_135(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_135(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i32>,<64 x i1>} @llvm.umul.with.overflow.v64i32(<64 x i32>,<64 x i32>)
define i64 @checked_vector_body_136(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.umul.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_136(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_136(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_137(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.umul.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_137(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_137(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i32>,<64 x i1>} @llvm.sadd.with.overflow.v64i32(<64 x i32>,<64 x i32>)
define i64 @checked_vector_body_138(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.sadd.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_138(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_138(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_139(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.sadd.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_139(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_139(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i32>,<64 x i1>} @llvm.ssub.with.overflow.v64i32(<64 x i32>,<64 x i32>)
define i64 @checked_vector_body_140(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.ssub.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_140(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_140(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_141(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.ssub.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_141(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_141(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i32>,<64 x i1>} @llvm.smul.with.overflow.v64i32(<64 x i32>,<64 x i32>)
define i64 @checked_vector_body_142(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.smul.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_142(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @checked_vector_body_142(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @checked_vector_body_143(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %x = load <64 x i32>,ptr %a,align 1
 %y = load <64 x i32>,ptr %b,align 1
 %pair = call {<64 x i32>,<64 x i1>} @llvm.smul.with.overflow.v64i32(<64 x i32> %x,<64 x i32> %y)
 %v = extractvalue {<64 x i32>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i32>,<64 x i1>} %pair,1
 store <64 x i32> %v,ptr %out,align 1
 %fptr = getelementptr i8,ptr %out,i64 256
 store <64 x i1> %flags,ptr %fptr,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @checked_vector_probe_143(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @checked_vector_body_143(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
