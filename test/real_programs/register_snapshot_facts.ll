target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare i64 @snapshot_check(ptr,ptr)
attributes #7 = { nounwind }
define i64 @register_snapshot_fact_probe_0(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_0)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_1(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_1)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_2(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_2)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_3(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_3)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_4(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_4)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_5(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_5)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_6(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_6)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_7(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_7)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_8(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_8)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_9(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_9)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_10(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_10)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_11(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_11)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_12(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_12)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_13(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_13)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_14(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_14)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_15(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_15)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_16(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_16)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_17(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_17)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_18(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(136) %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_18)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_19(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(136) %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_19)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_20(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(136) %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_20)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_21(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 tail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(136) %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_21)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_22(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = getelementptr i8,ptr %out,i64 0
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(136) %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_22)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
define i64 @register_snapshot_fact_probe_23(ptr %out,ptr %input,ptr %unused,i64 %salt) {
entry:
 %buffer = alloca [136 x i8],align 16
 notail call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)","{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(136) %buffer) #7
 %checked = call i64 @snapshot_check(ptr %buffer,ptr @register_snapshot_fact_probe_23)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %checked,ptr %out,align 1
 %zero1 = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %zero1,align 1
 %zero2 = getelementptr i8,ptr %out,i64 16
 store i64 0,ptr %zero2,align 1
 %zero3 = getelementptr i8,ptr %out,i64 24
 store i64 0,ptr %zero3,align 1
 %zero4 = getelementptr i8,ptr %out,i64 32
 store i64 0,ptr %zero4,align 1
 %zero5 = getelementptr i8,ptr %out,i64 40
 store i64 0,ptr %zero5,align 1
 %zero6 = getelementptr i8,ptr %out,i64 48
 store i64 0,ptr %zero6,align 1
 %zero7 = getelementptr i8,ptr %out,i64 56
 store i64 0,ptr %zero7,align 1
 %zero8 = getelementptr i8,ptr %out,i64 64
 store i64 0,ptr %zero8,align 1
 %zero9 = getelementptr i8,ptr %out,i64 72
 store i64 0,ptr %zero9,align 1
 %zero10 = getelementptr i8,ptr %out,i64 80
 store i64 0,ptr %zero10,align 1
 %zero11 = getelementptr i8,ptr %out,i64 88
 store i64 0,ptr %zero11,align 1
 %zero12 = getelementptr i8,ptr %out,i64 96
 store i64 0,ptr %zero12,align 1
 %zero13 = getelementptr i8,ptr %out,i64 104
 store i64 0,ptr %zero13,align 1
 %zero14 = getelementptr i8,ptr %out,i64 112
 store i64 0,ptr %zero14,align 1
 %zero15 = getelementptr i8,ptr %out,i64 120
 store i64 0,ptr %zero15,align 1
 %zero16 = getelementptr i8,ptr %out,i64 128
 store i64 0,ptr %zero16,align 1
 %op = getelementptr i8,ptr %out,i64 136
 store i64 %token,ptr %op,align 1
 %answer = xor i64 %checked,%token
 ret i64 %answer
}
