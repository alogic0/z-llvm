target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i1 @llvm.vector.reduce.or.v1i1(<1 x i1>)
declare {<1 x i1>,<1 x i1>} @llvm.uadd.with.overflow.v1i1(<1 x i1>,<1 x i1>)
define i64 @boolean_checked_body_0(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.uadd.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_0(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_0(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_1(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.uadd.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_1(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_1(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i1>,<1 x i1>} @llvm.usub.with.overflow.v1i1(<1 x i1>,<1 x i1>)
define i64 @boolean_checked_body_2(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.usub.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_2(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_2(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_3(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.usub.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_3(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_3(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i1>,<1 x i1>} @llvm.umul.with.overflow.v1i1(<1 x i1>,<1 x i1>)
define i64 @boolean_checked_body_4(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.umul.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_4(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_4(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_5(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.umul.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_5(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_5(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i1>,<1 x i1>} @llvm.sadd.with.overflow.v1i1(<1 x i1>,<1 x i1>)
define i64 @boolean_checked_body_6(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.sadd.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_6(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_6(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_7(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.sadd.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_7(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_7(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i1>,<1 x i1>} @llvm.ssub.with.overflow.v1i1(<1 x i1>,<1 x i1>)
define i64 @boolean_checked_body_8(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.ssub.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_8(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_8(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_9(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.ssub.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_9(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_9(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<1 x i1>,<1 x i1>} @llvm.smul.with.overflow.v1i1(<1 x i1>,<1 x i1>)
define i64 @boolean_checked_body_10(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.smul.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_10(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_10(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_11(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <1 x i8>,ptr %a,align 1
 %yb = load <1 x i8>,ptr %b,align 1
 %x = trunc <1 x i8> %xb to <1 x i1>
 %y = trunc <1 x i8> %yb to <1 x i1>
 %pair = call {<1 x i1>,<1 x i1>} @llvm.smul.with.overflow.v1i1(<1 x i1> %x,<1 x i1> %y)
 %v = extractvalue {<1 x i1>,<1 x i1>} %pair,0
 %flags = extractvalue {<1 x i1>,<1 x i1>} %pair,1
 %bytes = zext <1 x i1> %v to <1 x i8>
 store <1 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 1
 store <1 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 2
 store <1 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v1i1(<1 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_11(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_11(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v2i1(<2 x i1>)
declare {<2 x i1>,<2 x i1>} @llvm.uadd.with.overflow.v2i1(<2 x i1>,<2 x i1>)
define i64 @boolean_checked_body_12(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.uadd.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_12(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_12(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_13(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.uadd.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_13(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_13(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i1>,<2 x i1>} @llvm.usub.with.overflow.v2i1(<2 x i1>,<2 x i1>)
define i64 @boolean_checked_body_14(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.usub.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_14(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_14(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_15(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.usub.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_15(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_15(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i1>,<2 x i1>} @llvm.umul.with.overflow.v2i1(<2 x i1>,<2 x i1>)
define i64 @boolean_checked_body_16(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.umul.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_16(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_16(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_17(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.umul.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_17(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_17(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i1>,<2 x i1>} @llvm.sadd.with.overflow.v2i1(<2 x i1>,<2 x i1>)
define i64 @boolean_checked_body_18(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.sadd.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_18(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_18(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_19(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.sadd.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_19(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_19(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i1>,<2 x i1>} @llvm.ssub.with.overflow.v2i1(<2 x i1>,<2 x i1>)
define i64 @boolean_checked_body_20(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.ssub.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_20(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_20(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_21(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.ssub.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_21(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_21(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<2 x i1>,<2 x i1>} @llvm.smul.with.overflow.v2i1(<2 x i1>,<2 x i1>)
define i64 @boolean_checked_body_22(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.smul.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_22(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_22(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_23(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <2 x i8>,ptr %a,align 1
 %yb = load <2 x i8>,ptr %b,align 1
 %x = trunc <2 x i8> %xb to <2 x i1>
 %y = trunc <2 x i8> %yb to <2 x i1>
 %pair = call {<2 x i1>,<2 x i1>} @llvm.smul.with.overflow.v2i1(<2 x i1> %x,<2 x i1> %y)
 %v = extractvalue {<2 x i1>,<2 x i1>} %pair,0
 %flags = extractvalue {<2 x i1>,<2 x i1>} %pair,1
 %bytes = zext <2 x i1> %v to <2 x i8>
 store <2 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 2
 store <2 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 3
 store <2 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_23(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_23(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v3i1(<3 x i1>)
declare {<3 x i1>,<3 x i1>} @llvm.uadd.with.overflow.v3i1(<3 x i1>,<3 x i1>)
define i64 @boolean_checked_body_24(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.uadd.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_24(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_24(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_25(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.uadd.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_25(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_25(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i1>,<3 x i1>} @llvm.usub.with.overflow.v3i1(<3 x i1>,<3 x i1>)
define i64 @boolean_checked_body_26(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.usub.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_26(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_26(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_27(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.usub.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_27(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_27(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i1>,<3 x i1>} @llvm.umul.with.overflow.v3i1(<3 x i1>,<3 x i1>)
define i64 @boolean_checked_body_28(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.umul.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_28(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_28(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_29(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.umul.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_29(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_29(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i1>,<3 x i1>} @llvm.sadd.with.overflow.v3i1(<3 x i1>,<3 x i1>)
define i64 @boolean_checked_body_30(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.sadd.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_30(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_30(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_31(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.sadd.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_31(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_31(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i1>,<3 x i1>} @llvm.ssub.with.overflow.v3i1(<3 x i1>,<3 x i1>)
define i64 @boolean_checked_body_32(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.ssub.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_32(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_32(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_33(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.ssub.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_33(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_33(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<3 x i1>,<3 x i1>} @llvm.smul.with.overflow.v3i1(<3 x i1>,<3 x i1>)
define i64 @boolean_checked_body_34(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.smul.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_34(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_34(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_35(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <3 x i8>,ptr %a,align 1
 %yb = load <3 x i8>,ptr %b,align 1
 %x = trunc <3 x i8> %xb to <3 x i1>
 %y = trunc <3 x i8> %yb to <3 x i1>
 %pair = call {<3 x i1>,<3 x i1>} @llvm.smul.with.overflow.v3i1(<3 x i1> %x,<3 x i1> %y)
 %v = extractvalue {<3 x i1>,<3 x i1>} %pair,0
 %flags = extractvalue {<3 x i1>,<3 x i1>} %pair,1
 %bytes = zext <3 x i1> %v to <3 x i8>
 store <3 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 3
 store <3 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 4
 store <3 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_35(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_35(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v4i1(<4 x i1>)
declare {<4 x i1>,<4 x i1>} @llvm.uadd.with.overflow.v4i1(<4 x i1>,<4 x i1>)
define i64 @boolean_checked_body_36(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.uadd.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_36(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_36(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_37(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.uadd.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_37(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_37(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i1>,<4 x i1>} @llvm.usub.with.overflow.v4i1(<4 x i1>,<4 x i1>)
define i64 @boolean_checked_body_38(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.usub.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_38(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_38(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_39(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.usub.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_39(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_39(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i1>,<4 x i1>} @llvm.umul.with.overflow.v4i1(<4 x i1>,<4 x i1>)
define i64 @boolean_checked_body_40(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.umul.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_40(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_40(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_41(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.umul.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_41(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_41(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i1>,<4 x i1>} @llvm.sadd.with.overflow.v4i1(<4 x i1>,<4 x i1>)
define i64 @boolean_checked_body_42(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.sadd.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_42(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_42(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_43(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.sadd.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_43(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_43(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i1>,<4 x i1>} @llvm.ssub.with.overflow.v4i1(<4 x i1>,<4 x i1>)
define i64 @boolean_checked_body_44(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.ssub.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_44(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_44(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_45(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.ssub.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_45(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_45(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<4 x i1>,<4 x i1>} @llvm.smul.with.overflow.v4i1(<4 x i1>,<4 x i1>)
define i64 @boolean_checked_body_46(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.smul.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_46(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_46(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_47(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <4 x i8>,ptr %a,align 1
 %yb = load <4 x i8>,ptr %b,align 1
 %x = trunc <4 x i8> %xb to <4 x i1>
 %y = trunc <4 x i8> %yb to <4 x i1>
 %pair = call {<4 x i1>,<4 x i1>} @llvm.smul.with.overflow.v4i1(<4 x i1> %x,<4 x i1> %y)
 %v = extractvalue {<4 x i1>,<4 x i1>} %pair,0
 %flags = extractvalue {<4 x i1>,<4 x i1>} %pair,1
 %bytes = zext <4 x i1> %v to <4 x i8>
 store <4 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 4
 store <4 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 5
 store <4 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_47(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_47(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v8i1(<8 x i1>)
declare {<8 x i1>,<8 x i1>} @llvm.uadd.with.overflow.v8i1(<8 x i1>,<8 x i1>)
define i64 @boolean_checked_body_48(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.uadd.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_48(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_48(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_49(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.uadd.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_49(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_49(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i1>,<8 x i1>} @llvm.usub.with.overflow.v8i1(<8 x i1>,<8 x i1>)
define i64 @boolean_checked_body_50(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.usub.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_50(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_50(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_51(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.usub.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_51(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_51(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i1>,<8 x i1>} @llvm.umul.with.overflow.v8i1(<8 x i1>,<8 x i1>)
define i64 @boolean_checked_body_52(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.umul.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_52(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_52(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_53(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.umul.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_53(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_53(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i1>,<8 x i1>} @llvm.sadd.with.overflow.v8i1(<8 x i1>,<8 x i1>)
define i64 @boolean_checked_body_54(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.sadd.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_54(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_54(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_55(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.sadd.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_55(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_55(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i1>,<8 x i1>} @llvm.ssub.with.overflow.v8i1(<8 x i1>,<8 x i1>)
define i64 @boolean_checked_body_56(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.ssub.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_56(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_56(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_57(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.ssub.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_57(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_57(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<8 x i1>,<8 x i1>} @llvm.smul.with.overflow.v8i1(<8 x i1>,<8 x i1>)
define i64 @boolean_checked_body_58(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.smul.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_58(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_58(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_59(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <8 x i8>,ptr %a,align 1
 %yb = load <8 x i8>,ptr %b,align 1
 %x = trunc <8 x i8> %xb to <8 x i1>
 %y = trunc <8 x i8> %yb to <8 x i1>
 %pair = call {<8 x i1>,<8 x i1>} @llvm.smul.with.overflow.v8i1(<8 x i1> %x,<8 x i1> %y)
 %v = extractvalue {<8 x i1>,<8 x i1>} %pair,0
 %flags = extractvalue {<8 x i1>,<8 x i1>} %pair,1
 %bytes = zext <8 x i1> %v to <8 x i8>
 store <8 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 8
 store <8 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 9
 store <8 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_59(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_59(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v16i1(<16 x i1>)
declare {<16 x i1>,<16 x i1>} @llvm.uadd.with.overflow.v16i1(<16 x i1>,<16 x i1>)
define i64 @boolean_checked_body_60(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.uadd.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_60(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_60(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_61(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.uadd.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_61(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_61(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<16 x i1>,<16 x i1>} @llvm.usub.with.overflow.v16i1(<16 x i1>,<16 x i1>)
define i64 @boolean_checked_body_62(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.usub.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_62(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_62(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_63(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.usub.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_63(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_63(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<16 x i1>,<16 x i1>} @llvm.umul.with.overflow.v16i1(<16 x i1>,<16 x i1>)
define i64 @boolean_checked_body_64(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.umul.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_64(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_64(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_65(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.umul.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_65(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_65(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<16 x i1>,<16 x i1>} @llvm.sadd.with.overflow.v16i1(<16 x i1>,<16 x i1>)
define i64 @boolean_checked_body_66(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.sadd.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_66(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_66(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_67(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.sadd.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_67(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_67(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<16 x i1>,<16 x i1>} @llvm.ssub.with.overflow.v16i1(<16 x i1>,<16 x i1>)
define i64 @boolean_checked_body_68(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.ssub.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_68(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_68(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_69(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.ssub.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_69(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_69(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<16 x i1>,<16 x i1>} @llvm.smul.with.overflow.v16i1(<16 x i1>,<16 x i1>)
define i64 @boolean_checked_body_70(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.smul.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_70(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_70(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_71(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <16 x i8>,ptr %a,align 1
 %yb = load <16 x i8>,ptr %b,align 1
 %x = trunc <16 x i8> %xb to <16 x i1>
 %y = trunc <16 x i8> %yb to <16 x i1>
 %pair = call {<16 x i1>,<16 x i1>} @llvm.smul.with.overflow.v16i1(<16 x i1> %x,<16 x i1> %y)
 %v = extractvalue {<16 x i1>,<16 x i1>} %pair,0
 %flags = extractvalue {<16 x i1>,<16 x i1>} %pair,1
 %bytes = zext <16 x i1> %v to <16 x i8>
 store <16 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 18
 store <16 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_71(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_71(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v32i1(<32 x i1>)
declare {<32 x i1>,<32 x i1>} @llvm.uadd.with.overflow.v32i1(<32 x i1>,<32 x i1>)
define i64 @boolean_checked_body_72(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.uadd.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_72(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_72(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_73(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.uadd.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_73(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_73(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<32 x i1>,<32 x i1>} @llvm.usub.with.overflow.v32i1(<32 x i1>,<32 x i1>)
define i64 @boolean_checked_body_74(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.usub.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_74(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_74(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_75(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.usub.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_75(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_75(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<32 x i1>,<32 x i1>} @llvm.umul.with.overflow.v32i1(<32 x i1>,<32 x i1>)
define i64 @boolean_checked_body_76(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.umul.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_76(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_76(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_77(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.umul.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_77(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_77(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<32 x i1>,<32 x i1>} @llvm.sadd.with.overflow.v32i1(<32 x i1>,<32 x i1>)
define i64 @boolean_checked_body_78(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.sadd.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_78(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_78(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_79(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.sadd.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_79(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_79(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<32 x i1>,<32 x i1>} @llvm.ssub.with.overflow.v32i1(<32 x i1>,<32 x i1>)
define i64 @boolean_checked_body_80(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.ssub.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_80(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_80(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_81(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.ssub.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_81(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_81(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<32 x i1>,<32 x i1>} @llvm.smul.with.overflow.v32i1(<32 x i1>,<32 x i1>)
define i64 @boolean_checked_body_82(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.smul.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_82(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_82(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_83(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <32 x i8>,ptr %a,align 1
 %yb = load <32 x i8>,ptr %b,align 1
 %x = trunc <32 x i8> %xb to <32 x i1>
 %y = trunc <32 x i8> %yb to <32 x i1>
 %pair = call {<32 x i1>,<32 x i1>} @llvm.smul.with.overflow.v32i1(<32 x i1> %x,<32 x i1> %y)
 %v = extractvalue {<32 x i1>,<32 x i1>} %pair,0
 %flags = extractvalue {<32 x i1>,<32 x i1>} %pair,1
 %bytes = zext <32 x i1> %v to <32 x i8>
 store <32 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 32
 store <32 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 36
 store <32 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_83(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_83(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v64i1(<64 x i1>)
declare {<64 x i1>,<64 x i1>} @llvm.uadd.with.overflow.v64i1(<64 x i1>,<64 x i1>)
define i64 @boolean_checked_body_84(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.uadd.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_84(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_84(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_85(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.uadd.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_85(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_85(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i1>,<64 x i1>} @llvm.usub.with.overflow.v64i1(<64 x i1>,<64 x i1>)
define i64 @boolean_checked_body_86(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.usub.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_86(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_86(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_87(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.usub.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_87(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_87(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i1>,<64 x i1>} @llvm.umul.with.overflow.v64i1(<64 x i1>,<64 x i1>)
define i64 @boolean_checked_body_88(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.umul.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_88(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_88(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_89(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.umul.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_89(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_89(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i1>,<64 x i1>} @llvm.sadd.with.overflow.v64i1(<64 x i1>,<64 x i1>)
define i64 @boolean_checked_body_90(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.sadd.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_90(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_90(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_91(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.sadd.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_91(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_91(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i1>,<64 x i1>} @llvm.ssub.with.overflow.v64i1(<64 x i1>,<64 x i1>)
define i64 @boolean_checked_body_92(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.ssub.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_92(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_92(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_93(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.ssub.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_93(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_93(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
declare {<64 x i1>,<64 x i1>} @llvm.smul.with.overflow.v64i1(<64 x i1>,<64 x i1>)
define i64 @boolean_checked_body_94(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.smul.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_94(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call i64 @boolean_checked_body_94(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
define fastcc i64 @boolean_checked_body_95(ptr %out,ptr %a,ptr %b,i64 %live) noinline {
entry:
 %xb = load <64 x i8>,ptr %a,align 1
 %yb = load <64 x i8>,ptr %b,align 1
 %x = trunc <64 x i8> %xb to <64 x i1>
 %y = trunc <64 x i8> %yb to <64 x i1>
 %pair = call {<64 x i1>,<64 x i1>} @llvm.smul.with.overflow.v64i1(<64 x i1> %x,<64 x i1> %y)
 %v = extractvalue {<64 x i1>,<64 x i1>} %pair,0
 %flags = extractvalue {<64 x i1>,<64 x i1>} %pair,1
 %bytes = zext <64 x i1> %v to <64 x i8>
 store <64 x i8> %bytes,ptr %out,align 1
 %fp = getelementptr i8,ptr %out,i64 64
 store <64 x i1> %flags,ptr %fp,align 1
 %wp = getelementptr i8,ptr %out,i64 72
 store <64 x i1> %v,ptr %wp,align 1
 %any = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %flags)
 %wide = zext i1 %any to i64
 %r = xor i64 %wide,%live
 ret i64 %r
}
define i64 @boolean_checked_probe_95(ptr %out,ptr %a,ptr %b,i64 %live) {
entry:
 %r = call fastcc i64 @boolean_checked_body_95(ptr %out,ptr %a,ptr %b,i64 %live)
 ret i64 %r
}
