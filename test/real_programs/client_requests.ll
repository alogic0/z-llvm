declare void @client_fill(ptr, i64)
define i64 @client_default_i64(i64 %request, i64 %default) {
entry:
 %r = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request, i64 %default)
 ret i64 %r
}
define i64 @client_pointer(ptr %request, i64 %default) {
entry:
 %r = call i64 asm sideeffect " rolq  $$3,    %rdi ; rolq $$13, %rdi\0A rolq  $$61,   %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{memory},~{dirflag},~{fpsr},~{flags}"(ptr %request, i64 %default)
 ret i64 %r
}
define i64 @client_live(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h, ptr %out) {
entry:
 %r = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %a, i64 %h)
 %v0 = add i64 %r, %a
 %v1 = add i64 %v0, %b
 %v2 = add i64 %v1, %c
 %v3 = add i64 %v2, %d
 %v4 = add i64 %v3, %e
 %v5 = add i64 %v4, %f
 %v6 = add i64 %v5, %g
 %v7 = add i64 %v6, %h
 store i64 %v7, ptr %out
 ret i64 %v7
}
define i64 @client_literal(i64 %request, i64 %live) {
entry:
 %r = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %request, i64 18369614221190020847)
 %v = xor i64 %r, %live
 ret i64 %v
}
define i64 @client_stack(i64 %seed, i64 %default) {
entry:
 %request = alloca [6 x i64], align 16
 call void @client_fill(ptr %request, i64 %seed)
 %r = call i64 asm sideeffect " rolq  $$3,    %rdi ; rolq $$13, %rdi\0A rolq  $$61,   %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{memory},~{dirflag},~{fpsr},~{flags}"(ptr %request, i64 %default)
 %first = load i64, ptr %request, align 8
 %v = xor i64 %r, %first
 ret i64 %v
}
define i64 @client_flags(i64 %a, i64 %b, i64 %default) {
entry:
 %less = icmp slt i64 %a, %b
 %r = call i64 asm sideeffect " rolq  $$3,  %rdi ; rolq $$13, %rdi\0A rolq  $$61, %rdi ; rolq $$51, %rdi\0A xchgq %rbx, %rbx", "={rdx},{rax},{rdx},~{cc},~{memory},~{dirflag},~{fpsr},~{flags}"(i64 %a, i64 %default)
 br i1 %less, label %yes, label %no
yes:
 %v = add i64 %r, 7
 ret i64 %v
no:
 %w = xor i64 %r, 13
 ret i64 %w
}
