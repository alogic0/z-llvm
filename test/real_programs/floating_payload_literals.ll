target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
define internal float @floating_payload_return_0() noinline {
entry:
 ret float 0x0000000000000000
}
define internal i64 @floating_payload_body_0(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x0000000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x0000000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_0()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_0(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_0(ptr %out,float 0x0000000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_1() noinline {
entry:
 ret float 0x0000000000000000
}
define internal fastcc i64 @floating_payload_body_1(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x0000000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x0000000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_1()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_1(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_1(ptr %out,float 0x0000000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_2() noinline {
entry:
 ret float 0x8000000000000000
}
define internal i64 @floating_payload_body_2(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x8000000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x8000000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_2()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_2(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_2(ptr %out,float 0x8000000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_3() noinline {
entry:
 ret float 0x8000000000000000
}
define internal fastcc i64 @floating_payload_body_3(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x8000000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x8000000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_3()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_3(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_3(ptr %out,float 0x8000000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_4() noinline {
entry:
 ret float 0x7FF0000000000000
}
define internal i64 @floating_payload_body_4(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_4()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_4(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_4(ptr %out,float 0x7FF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_5() noinline {
entry:
 ret float 0x7FF0000000000000
}
define internal fastcc i64 @floating_payload_body_5(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_5()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_5(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_5(ptr %out,float 0x7FF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_6() noinline {
entry:
 ret float 0xFFF0000000000000
}
define internal i64 @floating_payload_body_6(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_6()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_6(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_6(ptr %out,float 0xFFF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_7() noinline {
entry:
 ret float 0xFFF0000000000000
}
define internal fastcc i64 @floating_payload_body_7(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_7()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_7(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_7(ptr %out,float 0xFFF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_8() noinline {
entry:
 ret float 0x7FF0000020000000
}
define internal i64 @floating_payload_body_8(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF0000020000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF0000020000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_8()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_8(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_8(ptr %out,float 0x7FF0000020000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_9() noinline {
entry:
 ret float 0x7FF0000020000000
}
define internal fastcc i64 @floating_payload_body_9(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF0000020000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF0000020000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_9()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_9(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_9(ptr %out,float 0x7FF0000020000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_10() noinline {
entry:
 ret float 0xFFF0000020000000
}
define internal i64 @floating_payload_body_10(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF0000020000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF0000020000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_10()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_10(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_10(ptr %out,float 0xFFF0000020000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_11() noinline {
entry:
 ret float 0xFFF0000020000000
}
define internal fastcc i64 @floating_payload_body_11(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF0000020000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF0000020000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_11()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_11(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_11(ptr %out,float 0xFFF0000020000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_12() noinline {
entry:
 ret float 0x7FF4000000000000
}
define internal i64 @floating_payload_body_12(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF4000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF4000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_12()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_12(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_12(ptr %out,float 0x7FF4000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_13() noinline {
entry:
 ret float 0x7FF4000000000000
}
define internal fastcc i64 @floating_payload_body_13(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF4000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF4000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_13()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_13(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_13(ptr %out,float 0x7FF4000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_14() noinline {
entry:
 ret float 0xFFF4000000000000
}
define internal i64 @floating_payload_body_14(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF4000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF4000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_14()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_14(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_14(ptr %out,float 0xFFF4000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_15() noinline {
entry:
 ret float 0xFFF4000000000000
}
define internal fastcc i64 @floating_payload_body_15(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF4000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF4000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_15()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_15(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_15(ptr %out,float 0xFFF4000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_16() noinline {
entry:
 ret float 0x7FF7FFFFE0000000
}
define internal i64 @floating_payload_body_16(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF7FFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF7FFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_16()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_16(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_16(ptr %out,float 0x7FF7FFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_17() noinline {
entry:
 ret float 0x7FF7FFFFE0000000
}
define internal fastcc i64 @floating_payload_body_17(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF7FFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF7FFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_17()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_17(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_17(ptr %out,float 0x7FF7FFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_18() noinline {
entry:
 ret float 0xFFF7FFFFE0000000
}
define internal i64 @floating_payload_body_18(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF7FFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF7FFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_18()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_18(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_18(ptr %out,float 0xFFF7FFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_19() noinline {
entry:
 ret float 0xFFF7FFFFE0000000
}
define internal fastcc i64 @floating_payload_body_19(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF7FFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF7FFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_19()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_19(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_19(ptr %out,float 0xFFF7FFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_20() noinline {
entry:
 ret float 0x7FF8000000000000
}
define internal i64 @floating_payload_body_20(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF8000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF8000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_20()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_20(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_20(ptr %out,float 0x7FF8000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_21() noinline {
entry:
 ret float 0x7FF8000000000000
}
define internal fastcc i64 @floating_payload_body_21(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FF8000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FF8000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_21()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_21(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_21(ptr %out,float 0x7FF8000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_22() noinline {
entry:
 ret float 0xFFF8000000000000
}
define internal i64 @floating_payload_body_22(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF8000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF8000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_22()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_22(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_22(ptr %out,float 0xFFF8000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_23() noinline {
entry:
 ret float 0xFFF8000000000000
}
define internal fastcc i64 @floating_payload_body_23(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFF8000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFF8000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_23()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_23(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_23(ptr %out,float 0xFFF8000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_24() noinline {
entry:
 ret float 0x7FFFFFFFE0000000
}
define internal i64 @floating_payload_body_24(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FFFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FFFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_24()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_24(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_24(ptr %out,float 0x7FFFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_25() noinline {
entry:
 ret float 0x7FFFFFFFE0000000
}
define internal fastcc i64 @floating_payload_body_25(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x7FFFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x7FFFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_25()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_25(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_25(ptr %out,float 0x7FFFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_26() noinline {
entry:
 ret float 0xFFFFFFFFE0000000
}
define internal i64 @floating_payload_body_26(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFFFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFFFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_26()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_26(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_26(ptr %out,float 0xFFFFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_27() noinline {
entry:
 ret float 0xFFFFFFFFE0000000
}
define internal fastcc i64 @floating_payload_body_27(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xFFFFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xFFFFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_27()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_27(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_27(ptr %out,float 0xFFFFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_28() noinline {
entry:
 ret float 0x36A0000000000000
}
define internal i64 @floating_payload_body_28(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x36A0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x36A0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_28()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_28(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_28(ptr %out,float 0x36A0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_29() noinline {
entry:
 ret float 0x36A0000000000000
}
define internal fastcc i64 @floating_payload_body_29(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x36A0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x36A0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_29()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_29(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_29(ptr %out,float 0x36A0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_30() noinline {
entry:
 ret float 0xB6A0000000000000
}
define internal i64 @floating_payload_body_30(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xB6A0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xB6A0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_30()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_30(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_30(ptr %out,float 0xB6A0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_31() noinline {
entry:
 ret float 0xB6A0000000000000
}
define internal fastcc i64 @floating_payload_body_31(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xB6A0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xB6A0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_31()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_31(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_31(ptr %out,float 0xB6A0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_32() noinline {
entry:
 ret float 0x380FFFFFC0000000
}
define internal i64 @floating_payload_body_32(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x380FFFFFC0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x380FFFFFC0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_32()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_32(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_32(ptr %out,float 0x380FFFFFC0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_33() noinline {
entry:
 ret float 0x380FFFFFC0000000
}
define internal fastcc i64 @floating_payload_body_33(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x380FFFFFC0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x380FFFFFC0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_33()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_33(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_33(ptr %out,float 0x380FFFFFC0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_34() noinline {
entry:
 ret float 0xB80FFFFFC0000000
}
define internal i64 @floating_payload_body_34(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xB80FFFFFC0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xB80FFFFFC0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_34()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_34(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_34(ptr %out,float 0xB80FFFFFC0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_35() noinline {
entry:
 ret float 0xB80FFFFFC0000000
}
define internal fastcc i64 @floating_payload_body_35(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xB80FFFFFC0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xB80FFFFFC0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_35()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_35(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_35(ptr %out,float 0xB80FFFFFC0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_36() noinline {
entry:
 ret float 0x3FF0000000000000
}
define internal i64 @floating_payload_body_36(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x3FF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x3FF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_36()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_36(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_36(ptr %out,float 0x3FF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_37() noinline {
entry:
 ret float 0x3FF0000000000000
}
define internal fastcc i64 @floating_payload_body_37(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x3FF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x3FF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_37()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_37(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_37(ptr %out,float 0x3FF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_38() noinline {
entry:
 ret float 0xBFF0000000000000
}
define internal i64 @floating_payload_body_38(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xBFF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xBFF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_38()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_38(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_38(ptr %out,float 0xBFF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_39() noinline {
entry:
 ret float 0xBFF0000000000000
}
define internal fastcc i64 @floating_payload_body_39(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xBFF0000000000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xBFF0000000000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_39()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_39(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_39(ptr %out,float 0xBFF0000000000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_40() noinline {
entry:
 ret float 0x47EFFFFFE0000000
}
define internal i64 @floating_payload_body_40(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x47EFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x47EFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_40()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_40(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_40(ptr %out,float 0x47EFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_41() noinline {
entry:
 ret float 0x47EFFFFFE0000000
}
define internal fastcc i64 @floating_payload_body_41(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0x47EFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0x47EFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_41()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_41(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_41(ptr %out,float 0x47EFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal float @floating_payload_return_42() noinline {
entry:
 ret float 0xC7EFFFFFE0000000
}
define internal i64 @floating_payload_body_42(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xC7EFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xC7EFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call float @floating_payload_return_42()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_42(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call i64 @floating_payload_body_42(ptr %out,float 0xC7EFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
define internal fastcc float @floating_payload_return_43() noinline {
entry:
 ret float 0xC7EFFFFFE0000000
}
define internal fastcc i64 @floating_payload_body_43(ptr %out,float %argument,i32 %dynamic,i64 %token) noinline {
entry:
 %local = alloca float,align 4
 %argument_bits = bitcast float %argument to i32
 store i32 %argument_bits,ptr %out,align 1
 store float 0xC7EFFFFFE0000000,ptr %local,align 4
 %loaded = load float,ptr %local,align 4
 %loaded_bits = bitcast float %loaded to i32
 %p1 = getelementptr i8,ptr %out,i64 4
 store i32 %loaded_bits,ptr %p1,align 1
 %literal_bits = bitcast float 0xC7EFFFFFE0000000 to i32
 %p2 = getelementptr i8,ptr %out,i64 8
 store i32 %literal_bits,ptr %p2,align 1
 %returned = call fastcc float @floating_payload_return_43()
 %return_bits = bitcast float %returned to i32
 %p3 = getelementptr i8,ptr %out,i64 12
 store i32 %return_bits,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %out,i64 16
 store i32 %dynamic,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %out,i64 20
 store i64 %token,ptr %p5,align 1
 ret i64 %token
}
define i64 @floating_payload_probe_43(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %dynamic = load i32,ptr %input,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %r = call fastcc i64 @floating_payload_body_43(ptr %out,float 0xC7EFFFFFE0000000,i32 %dynamic,i64 %token)
 ret i64 %r
}
