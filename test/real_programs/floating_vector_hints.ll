target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
define internal fastcc i64 @floating_hint_body_0(ptr %out,<4 x double> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %r = call fastcc i64 @floating_hint_body_0(ptr %out,<4 x double> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_1(ptr %out,<4 x double> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %r = tail call fastcc i64 @floating_hint_body_1(ptr %out,<4 x double> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_2(ptr %out,<4 x double> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %r = notail call fastcc i64 @floating_hint_body_2(ptr %out,<4 x double> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_3(ptr %out,<4 x double> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %r = call fastcc i64 @floating_hint_body_3(ptr %out,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_4(ptr %out,<4 x double> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %r = tail call fastcc i64 @floating_hint_body_4(ptr %out,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_5(ptr %out,<4 x double> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %r = notail call fastcc i64 @floating_hint_body_5(ptr %out,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_6(ptr %out,<4 x double> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = call fastcc i64 @floating_hint_body_6(ptr %out,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_7(ptr %out,<4 x double> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call fastcc i64 @floating_hint_body_7(ptr %out,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_8(ptr %out,<4 x double> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call fastcc i64 @floating_hint_body_8(ptr %out,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_9(ptr %out,<4 x double> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x double> poison,double 1.000000e+00,i64 0
 %literal_1 = insertelement <4 x double> %literal_0,double -0.000000e+00,i64 1
 %literal_2 = insertelement <4 x double> %literal_1,double 0x7FF8000000000001,i64 2
 %a = insertelement <4 x double> %literal_2,double -2.000000e+00,i64 3
 %r = call fastcc i64 @floating_hint_body_9(ptr %out,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_10(ptr %out,<4 x double> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x double> poison,double 1.000000e+00,i64 0
 %literal_1 = insertelement <4 x double> %literal_0,double -0.000000e+00,i64 1
 %literal_2 = insertelement <4 x double> %literal_1,double 0x7FF8000000000001,i64 2
 %a = insertelement <4 x double> %literal_2,double -2.000000e+00,i64 3
 %r = tail call fastcc i64 @floating_hint_body_10(ptr %out,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_11(ptr %out,<4 x double> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x double> poison,double 1.000000e+00,i64 0
 %literal_1 = insertelement <4 x double> %literal_0,double -0.000000e+00,i64 1
 %literal_2 = insertelement <4 x double> %literal_1,double 0x7FF8000000000001,i64 2
 %a = insertelement <4 x double> %literal_2,double -2.000000e+00,i64 3
 %r = notail call fastcc i64 @floating_hint_body_11(ptr %out,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 40
 store <4 x double> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 72
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_12(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 32
 %b = load <4 x double>,ptr %next,align 1
 %r = call fastcc i64 @floating_hint_body_12(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_13(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 32
 %b = load <4 x double>,ptr %next,align 1
 %r = tail call fastcc i64 @floating_hint_body_13(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_14(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 32
 %b = load <4 x double>,ptr %next,align 1
 %r = notail call fastcc i64 @floating_hint_body_14(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_15(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 32
 %b = load <4 x double>,ptr %next,align 1
 %r = call fastcc i64 @floating_hint_body_15(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_16(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 32
 %b = load <4 x double>,ptr %next,align 1
 %r = tail call fastcc i64 @floating_hint_body_16(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_17(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 32
 %b = load <4 x double>,ptr %next,align 1
 %r = notail call fastcc i64 @floating_hint_body_17(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_18(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = call fastcc i64 @floating_hint_body_18(ptr %out,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_19(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call fastcc i64 @floating_hint_body_19(ptr %out,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_20(ptr %out,<4 x double> %a,<4 x double> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call fastcc i64 @floating_hint_body_20(ptr %out,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,<4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> <double 1.000000e+00,double -0.000000e+00,double 0x7FF8000000000001,double -2.000000e+00>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_21(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x double> poison,double 1.000000e+00,i64 0
 %literal_1 = insertelement <4 x double> %literal_0,double -0.000000e+00,i64 1
 %literal_2 = insertelement <4 x double> %literal_1,double 0x7FF8000000000001,i64 2
 %a = insertelement <4 x double> %literal_2,double -2.000000e+00,i64 3
 %r = call fastcc i64 @floating_hint_body_21(ptr %out,<4 x double> noundef %a,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_22(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x double> poison,double 1.000000e+00,i64 0
 %literal_1 = insertelement <4 x double> %literal_0,double -0.000000e+00,i64 1
 %literal_2 = insertelement <4 x double> %literal_1,double 0x7FF8000000000001,i64 2
 %a = insertelement <4 x double> %literal_2,double -2.000000e+00,i64 3
 %r = tail call fastcc i64 @floating_hint_body_22(ptr %out,<4 x double> noundef %a,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_23(ptr %out,<4 x double> noundef %a,<4 x double> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x double> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 32
 store <4 x double> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x double> poison,double 1.000000e+00,i64 0
 %literal_1 = insertelement <4 x double> %literal_0,double -0.000000e+00,i64 1
 %literal_2 = insertelement <4 x double> %literal_1,double 0x7FF8000000000001,i64 2
 %a = insertelement <4 x double> %literal_2,double -2.000000e+00,i64 3
 %r = notail call fastcc i64 @floating_hint_body_23(ptr %out,<4 x double> noundef %a,<4 x double> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x double> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 32
 store <4 x double> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_24(ptr %out,<4 x x86_fp80> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %r = call fastcc i64 @floating_hint_body_24(ptr %out,<4 x x86_fp80> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_25(ptr %out,<4 x x86_fp80> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %r = tail call fastcc i64 @floating_hint_body_25(ptr %out,<4 x x86_fp80> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_26(ptr %out,<4 x x86_fp80> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %r = notail call fastcc i64 @floating_hint_body_26(ptr %out,<4 x x86_fp80> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_27(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %r = call fastcc i64 @floating_hint_body_27(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_28(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %r = tail call fastcc i64 @floating_hint_body_28(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_29(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %r = notail call fastcc i64 @floating_hint_body_29(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_30(ptr %out,<4 x x86_fp80> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = call fastcc i64 @floating_hint_body_30(ptr %out,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_31(ptr %out,<4 x x86_fp80> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call fastcc i64 @floating_hint_body_31(ptr %out,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_32(ptr %out,<4 x x86_fp80> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call fastcc i64 @floating_hint_body_32(ptr %out,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_33(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x x86_fp80> poison,x86_fp80 0xK3FFF8000000000000000,i64 0
 %literal_1 = insertelement <4 x x86_fp80> %literal_0,x86_fp80 0xK80000000000000000000,i64 1
 %literal_2 = insertelement <4 x x86_fp80> %literal_1,x86_fp80 0xK4000C000000000000000,i64 2
 %a = insertelement <4 x x86_fp80> %literal_2,x86_fp80 0xKBFFF8000000000000000,i64 3
 %r = call fastcc i64 @floating_hint_body_33(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_34(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x x86_fp80> poison,x86_fp80 0xK3FFF8000000000000000,i64 0
 %literal_1 = insertelement <4 x x86_fp80> %literal_0,x86_fp80 0xK80000000000000000000,i64 1
 %literal_2 = insertelement <4 x x86_fp80> %literal_1,x86_fp80 0xK4000C000000000000000,i64 2
 %a = insertelement <4 x x86_fp80> %literal_2,x86_fp80 0xKBFFF8000000000000000,i64 3
 %r = tail call fastcc i64 @floating_hint_body_34(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_35(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 40
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x x86_fp80> poison,x86_fp80 0xK3FFF8000000000000000,i64 0
 %literal_1 = insertelement <4 x x86_fp80> %literal_0,x86_fp80 0xK80000000000000000000,i64 1
 %literal_2 = insertelement <4 x x86_fp80> %literal_1,x86_fp80 0xK4000C000000000000000,i64 2
 %a = insertelement <4 x x86_fp80> %literal_2,x86_fp80 0xKBFFF8000000000000000,i64 3
 %r = notail call fastcc i64 @floating_hint_body_35(ptr %out,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 48
 store <4 x x86_fp80> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 88
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_36(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 40
 %b = load <4 x x86_fp80>,ptr %next,align 1
 %r = call fastcc i64 @floating_hint_body_36(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_37(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 40
 %b = load <4 x x86_fp80>,ptr %next,align 1
 %r = tail call fastcc i64 @floating_hint_body_37(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_38(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 40
 %b = load <4 x x86_fp80>,ptr %next,align 1
 %r = notail call fastcc i64 @floating_hint_body_38(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_39(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 40
 %b = load <4 x x86_fp80>,ptr %next,align 1
 %r = call fastcc i64 @floating_hint_body_39(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_40(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 40
 %b = load <4 x x86_fp80>,ptr %next,align 1
 %r = tail call fastcc i64 @floating_hint_body_40(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_41(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 40
 %b = load <4 x x86_fp80>,ptr %next,align 1
 %r = notail call fastcc i64 @floating_hint_body_41(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_42(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = call fastcc i64 @floating_hint_body_42(ptr %out,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_43(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call fastcc i64 @floating_hint_body_43(ptr %out,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_44(ptr %out,<4 x x86_fp80> %a,<4 x x86_fp80> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call fastcc i64 @floating_hint_body_44(ptr %out,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,<4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> <x86_fp80 0xK3FFF8000000000000000,x86_fp80 0xK80000000000000000000,x86_fp80 0xK4000C000000000000000,x86_fp80 0xKBFFF8000000000000000>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_45(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x x86_fp80> poison,x86_fp80 0xK3FFF8000000000000000,i64 0
 %literal_1 = insertelement <4 x x86_fp80> %literal_0,x86_fp80 0xK80000000000000000000,i64 1
 %literal_2 = insertelement <4 x x86_fp80> %literal_1,x86_fp80 0xK4000C000000000000000,i64 2
 %a = insertelement <4 x x86_fp80> %literal_2,x86_fp80 0xKBFFF8000000000000000,i64 3
 %r = call fastcc i64 @floating_hint_body_45(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_46(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x x86_fp80> poison,x86_fp80 0xK3FFF8000000000000000,i64 0
 %literal_1 = insertelement <4 x x86_fp80> %literal_0,x86_fp80 0xK80000000000000000000,i64 1
 %literal_2 = insertelement <4 x x86_fp80> %literal_1,x86_fp80 0xK4000C000000000000000,i64 2
 %a = insertelement <4 x x86_fp80> %literal_2,x86_fp80 0xKBFFF8000000000000000,i64 3
 %r = tail call fastcc i64 @floating_hint_body_46(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_47(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x x86_fp80> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 40
 store <4 x x86_fp80> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 80
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x x86_fp80> poison,x86_fp80 0xK3FFF8000000000000000,i64 0
 %literal_1 = insertelement <4 x x86_fp80> %literal_0,x86_fp80 0xK80000000000000000000,i64 1
 %literal_2 = insertelement <4 x x86_fp80> %literal_1,x86_fp80 0xK4000C000000000000000,i64 2
 %a = insertelement <4 x x86_fp80> %literal_2,x86_fp80 0xKBFFF8000000000000000,i64 3
 %r = notail call fastcc i64 @floating_hint_body_47(ptr %out,<4 x x86_fp80> noundef %a,<4 x x86_fp80> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 88
 store <4 x x86_fp80> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 40
 store <4 x x86_fp80> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 168
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_48(ptr %out,<4 x fp128> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %r = call fastcc i64 @floating_hint_body_48(ptr %out,<4 x fp128> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_49(ptr %out,<4 x fp128> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %r = tail call fastcc i64 @floating_hint_body_49(ptr %out,<4 x fp128> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_50(ptr %out,<4 x fp128> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %r = notail call fastcc i64 @floating_hint_body_50(ptr %out,<4 x fp128> %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_51(ptr %out,<4 x fp128> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %r = call fastcc i64 @floating_hint_body_51(ptr %out,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_52(ptr %out,<4 x fp128> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %r = tail call fastcc i64 @floating_hint_body_52(ptr %out,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_53(ptr %out,<4 x fp128> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %r = notail call fastcc i64 @floating_hint_body_53(ptr %out,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_54(ptr %out,<4 x fp128> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = call fastcc i64 @floating_hint_body_54(ptr %out,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_55(ptr %out,<4 x fp128> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call fastcc i64 @floating_hint_body_55(ptr %out,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_56(ptr %out,<4 x fp128> %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call fastcc i64 @floating_hint_body_56(ptr %out,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_57(ptr %out,<4 x fp128> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x fp128> poison,fp128 0xL00000000000000003FFF000000000000,i64 0
 %literal_1 = insertelement <4 x fp128> %literal_0,fp128 0xL00000000000000008000000000000000,i64 1
 %literal_2 = insertelement <4 x fp128> %literal_1,fp128 0xL000000000000000140007FFF00000000,i64 2
 %a = insertelement <4 x fp128> %literal_2,fp128 0xL0000000000000000C000000000000000,i64 3
 %r = call fastcc i64 @floating_hint_body_57(ptr %out,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_58(ptr %out,<4 x fp128> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x fp128> poison,fp128 0xL00000000000000003FFF000000000000,i64 0
 %literal_1 = insertelement <4 x fp128> %literal_0,fp128 0xL00000000000000008000000000000000,i64 1
 %literal_2 = insertelement <4 x fp128> %literal_1,fp128 0xL000000000000000140007FFF00000000,i64 2
 %a = insertelement <4 x fp128> %literal_2,fp128 0xL0000000000000000C000000000000000,i64 3
 %r = tail call fastcc i64 @floating_hint_body_58(ptr %out,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_59(ptr %out,<4 x fp128> noundef %a,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x fp128> poison,fp128 0xL00000000000000003FFF000000000000,i64 0
 %literal_1 = insertelement <4 x fp128> %literal_0,fp128 0xL00000000000000008000000000000000,i64 1
 %literal_2 = insertelement <4 x fp128> %literal_1,fp128 0xL000000000000000140007FFF00000000,i64 2
 %a = insertelement <4 x fp128> %literal_2,fp128 0xL0000000000000000C000000000000000,i64 3
 %r = notail call fastcc i64 @floating_hint_body_59(ptr %out,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 72
 store <4 x fp128> %a,ptr %after,align 1
 %last = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_60(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_60(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 64
 %b = load <4 x fp128>,ptr %next,align 1
 %r = call fastcc i64 @floating_hint_body_60(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_61(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_61(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 64
 %b = load <4 x fp128>,ptr %next,align 1
 %r = tail call fastcc i64 @floating_hint_body_61(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_62(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_62(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 64
 %b = load <4 x fp128>,ptr %next,align 1
 %r = notail call fastcc i64 @floating_hint_body_62(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_63(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_63(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 64
 %b = load <4 x fp128>,ptr %next,align 1
 %r = call fastcc i64 @floating_hint_body_63(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_64(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_64(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 64
 %b = load <4 x fp128>,ptr %next,align 1
 %r = tail call fastcc i64 @floating_hint_body_64(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_65(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_65(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 64
 %b = load <4 x fp128>,ptr %next,align 1
 %r = notail call fastcc i64 @floating_hint_body_65(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %b,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_66(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_66(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = call fastcc i64 @floating_hint_body_66(ptr %out,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_67(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_67(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call fastcc i64 @floating_hint_body_67(ptr %out,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_68(ptr %out,<4 x fp128> %a,<4 x fp128> %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_68(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call fastcc i64 @floating_hint_body_68(ptr %out,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,<4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> <fp128 0xL00000000000000003FFF000000000000,fp128 0xL00000000000000008000000000000000,fp128 0xL000000000000000140007FFF00000000,fp128 0xL0000000000000000C000000000000000>,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_69(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_69(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x fp128> poison,fp128 0xL00000000000000003FFF000000000000,i64 0
 %literal_1 = insertelement <4 x fp128> %literal_0,fp128 0xL00000000000000008000000000000000,i64 1
 %literal_2 = insertelement <4 x fp128> %literal_1,fp128 0xL000000000000000140007FFF00000000,i64 2
 %a = insertelement <4 x fp128> %literal_2,fp128 0xL0000000000000000C000000000000000,i64 3
 %r = call fastcc i64 @floating_hint_body_69(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_70(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_70(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x fp128> poison,fp128 0xL00000000000000003FFF000000000000,i64 0
 %literal_1 = insertelement <4 x fp128> %literal_0,fp128 0xL00000000000000008000000000000000,i64 1
 %literal_2 = insertelement <4 x fp128> %literal_1,fp128 0xL000000000000000140007FFF00000000,i64 2
 %a = insertelement <4 x fp128> %literal_2,fp128 0xL0000000000000000C000000000000000,i64 3
 %r = tail call fastcc i64 @floating_hint_body_70(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @floating_hint_body_71(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %b,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <4 x fp128> %a,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 64
 store <4 x fp128> %b,ptr %next,align 1
 %token_out = getelementptr i8,ptr %out,i64 128
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @floating_hint_probe_71(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %literal_0 = insertelement <4 x fp128> poison,fp128 0xL00000000000000003FFF000000000000,i64 0
 %literal_1 = insertelement <4 x fp128> %literal_0,fp128 0xL00000000000000008000000000000000,i64 1
 %literal_2 = insertelement <4 x fp128> %literal_1,fp128 0xL000000000000000140007FFF00000000,i64 2
 %a = insertelement <4 x fp128> %literal_2,fp128 0xL0000000000000000C000000000000000,i64 3
 %r = notail call fastcc i64 @floating_hint_body_71(ptr %out,<4 x fp128> noundef %a,<4 x fp128> noundef %a,i64 %salt)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %after = getelementptr i8,ptr %out,i64 136
 store <4 x fp128> %a,ptr %after,align 1
 %after2 = getelementptr i8,ptr %after,i64 64
 store <4 x fp128> %a,ptr %after2,align 1
 %last = getelementptr i8,ptr %out,i64 264
 store i64 %token,ptr %last,align 1
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
