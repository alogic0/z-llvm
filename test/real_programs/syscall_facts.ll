target triple = "x86_64-unknown-linux-gnu"

define i64 @sysfact0(i64 %nr) {
entry:
  %r = tail call i64 asm sideeffect "syscall", "={rax},{rax},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 noundef range(i64 0, 1024) %nr) #0
  ret i64 %r
}

define i64 @sysfact1(i64 %a, i64 %nr) {
entry:
  %r = notail call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 range(i64 0, 1024) %nr, i64 range(i64 -4096, 4096) %a) #0
  ret i64 %r
}

define i64 @sysfact2(i64 %b, i64 %a, i64 %nr) {
entry:
  %r = tail call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 range(i64 0, 1024) %nr, i64 noundef %a, i64 range(i64 0, -9223372036854775808) %b) #0
  ret i64 %r
}

define i64 @sysfact3(i64 %c, i64 %b, i64 %a, i64 %nr) {
entry:
  %r = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 noundef %nr, i64 noundef %a, i64 noundef %b, i64 range(i64 0, 128) %c) #0
  ret i64 %r
}

define i64 @sysfact4(i64 %d, i64 %c, i64 %b, i64 %a, i64 %nr) {
entry:
  %r = tail call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 range(i64 0, 1024) %nr, i64 noundef %a, i64 noundef %b, i64 range(i64 0, 128) %c, i64 range(i64 0, 8192) %d) #0
  ret i64 %r
}

define i64 @sysfact5(i64 %e, i64 %d, i64 %c, i64 %b, i64 %a, i64 %nr) {
entry:
  %r = notail call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 noundef %nr, i64 noundef %a, i64 noundef %b, i64 range(i64 0, 4096) %c, i64 range(i64 0, 4096) %d, i64 noundef %e) #0
  ret i64 %r
}

define i64 @sysfact6(i64 %f, i64 %e, i64 %d, i64 %c, i64 %b, i64 %a, i64 %nr) {
entry:
  %r = tail call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8},{r9},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 range(i64 0, 1024) %nr, i64 noundef %a, i64 range(i64 1, 8192) %b, i64 range(i64 0, 8) %c, i64 range(i64 0, 128) %d, i64 noundef %e, i64 range(i64 0, 8192) %f) #0
  ret i64 %r
}

define i64 @sysfact_live(i64 %fd, ptr %buffer, i64 %length, i64 %a, i64 %b, ptr %output, double %x) {
entry:
  %before = icmp ult i64 %a, %b
  %fp = fadd double %x, 1.250000e+00
  %buffer_bits = ptrtoint ptr %buffer to i64
  br i1 %before, label %left, label %right
left:
  %l = add i64 %a, 17
  br label %join
right:
  %r = xor i64 %b, 305419896
  br label %join
join:
  %word = phi i64 [ %l, %left ], [ %r, %right ]
  %result = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 range(i64 0, 1024) 1, i64 noundef %fd, i64 noundef %buffer_bits, i64 range(i64 0, 128) %length) #0
  store double %fp, ptr %output, align 8
  %wa = xor i64 %word, %a
  %wb = add i64 %wa, %b
  %wr = xor i64 %wb, %result
  %total = add i64 %wr, %length
  %answer = select i1 %before, i64 %total, i64 %wr
  ret i64 %answer
}

attributes #0 = { nounwind }
