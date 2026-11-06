target triple = "x86_64-unknown-linux-gnu"

define void @system_snapshot(ptr %p) {
entry:
  call void asm sideeffect " movq %rax, 0x00(%rdi)\0A movq %rdx, 0x08(%rdi)\0A movq %rcx, 0x10(%rdi)\0A movq %rbx, 0x18(%rdi)\0A movq %rsi, 0x20(%rdi)\0A movq %rdi, 0x28(%rdi)\0A movq %rbp, 0x30(%rdi)\0A movq %rsp, 0x38(%rdi)\0A movq %r8,  0x40(%rdi)\0A movq %r9,  0x48(%rdi)\0A movq %r10, 0x50(%rdi)\0A movq %r11, 0x58(%rdi)\0A movq %r12, 0x60(%rdi)\0A movq %r13, 0x68(%rdi)\0A movq %r14, 0x70(%rdi)\0A movq %r15, 0x78(%rdi)\0A leaq (%rip), %rax\0A movq %rax, 0x80(%rdi)", "{rdi},~{memory},~{rax},~{dirflag},~{fpsr},~{flags}"(ptr %p)
  ret void
}

define i64 @system_call0(i64 %v0) {
entry:
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 %v0)
  ret i64 %result
}

define i64 @system_call1(i64 %v0, i64 %v1) {
entry:
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 %v0, i64 %v1)
  ret i64 %result
}

define i64 @system_call2(i64 %v0, i64 %v1, i64 %v2) {
entry:
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 %v0, i64 %v1, i64 %v2)
  ret i64 %result
}

define i64 @system_call3(i64 %v0, i64 %v1, i64 %v2, i64 %v3) {
entry:
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 %v0, i64 %v1, i64 %v2, i64 %v3)
  ret i64 %result
}

define i64 @system_call4(i64 %v0, i64 %v1, i64 %v2, i64 %v3, i64 %v4) {
entry:
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 %v0, i64 %v1, i64 %v2, i64 %v3, i64 %v4)
  ret i64 %result
}

define i64 @system_call5(i64 %v0, i64 %v1, i64 %v2, i64 %v3, i64 %v4, i64 %v5) {
entry:
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 %v0, i64 %v1, i64 %v2, i64 %v3, i64 %v4, i64 %v5)
  ret i64 %result
}

define i64 @system_call6(i64 %v0, i64 %v1, i64 %v2, i64 %v3, i64 %v4, i64 %v5, i64 %v6) {
entry:
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 %v0, i64 %v1, i64 %v2, i64 %v3, i64 %v4, i64 %v5, i64 %v6)
  ret i64 %result
}

define i64 @system_pressure(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %before = icmp ult i64 %a, %b
  %pid = call i64 asm sideeffect "syscall", "={rax},{rax},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 39)
  %ab = xor i64 %a, %b
  %cd = add i64 %c, %d
  %ef = xor i64 %e, %f
  %left = add i64 %ab, %cd
  %right = xor i64 %ef, %pid
  %sum = add i64 %left, %right
  %result = select i1 %before, i64 %sum, i64 %ab
  ret i64 %result
}
