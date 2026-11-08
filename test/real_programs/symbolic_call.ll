target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@sc_data = global [128 x i8] zeroinitializer, align 16
@sc_alias = internal alias [128 x i8], ptr @sc_data

declare i64 @sc_mix(i64, i64, i64)
declare i64 @sc_negative(i64, i64)
declare i64 @sc_many(i64, i64, i64, i64, i64, i64, i64, i64, i64)

define i64 @symbolic_direct(i64 %seed) {
entry:
  %r = tail call i64 @sc_mix(i64 noundef ptrtoint (ptr getelementptr inbounds nuw (i8, ptr @sc_data, i64 17) to i64), i64 %seed, i64 ptrtoint (ptr getelementptr (i8, ptr @sc_alias, i64 31) to i64))
  ret i64 %r
}

define i64 @symbolic_indirect(ptr %function, i64 %seed) {
entry:
  %r = call i64 %function(i64 ptrtoint (ptr getelementptr (i8, ptr @sc_alias, i64 17) to i64), i64 %seed, i64 ptrtoint (ptr getelementptr (i8, ptr @sc_data, i64 31) to i64))
  ret i64 %r
}

define i64 @symbolic_negative(i64 %seed) {
entry:
  %r = call i64 @sc_negative(i64 ptrtoint (ptr getelementptr (i8, ptr @sc_data, i64 -8) to i64), i64 %seed)
  ret i64 %r
}

define i64 @symbolic_stack(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %r = call i64 @sc_many(i64 %f, i64 %e, i64 %d, i64 %c, i64 %b, i64 %a, i64 ptrtoint (ptr @sc_data to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @sc_alias, i64 17) to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @sc_data, i64 31) to i64))
  ret i64 %r
}

define i64 @symbolic_live(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %output, double %x) {
entry:
  %f = xor i64 %a, 98765
  %before = icmp ult i64 %a, %b
  %fp = fadd double %x, 1.250000e+00
  %a1 = add i64 %a, 11
  %b1 = xor i64 %b, 23
  %c1 = add i64 %c, 37
  %d1 = xor i64 %d, 51
  %e1 = add i64 %e, 67
  %f1 = xor i64 %f, 83
  br i1 %before, label %left, label %right
left:
  %l = add i64 %a, 17
  br label %join
right:
  %r = xor i64 %b, 305419896
  br label %join
join:
  %word = phi i64 [ %l, %left ], [ %r, %right ]
  %called = call i64 @sc_many(i64 %f, i64 %e, i64 %d, i64 %c, i64 %b, i64 %a, i64 ptrtoint (ptr @sc_alias to i64), i64 ptrtoint (ptr getelementptr inbounds nuw (i8, ptr @sc_data, i64 17) to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @sc_data, i64 31) to i64))
  store double %fp, ptr %output, align 8
  %ab = xor i64 %a1, %b1
  %cd = xor i64 %c1, %d1
  %ef = xor i64 %e1, %f1
  %abcd = add i64 %ab, %cd
  %all = xor i64 %abcd, %ef
  %live = add i64 %all, %word
  %total = xor i64 %live, %called
  %extra = add i64 %total, %a
  %answer = select i1 %before, i64 %extra, i64 %total
  ret i64 %answer
}

define i64 @symbolic_write(i64 %fd, i64 %length) {
entry:
  %r = tail call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 1, i64 %fd, i64 noundef ptrtoint (ptr getelementptr inbounds nuw (i8, ptr @sc_alias, i64 17) to i64), i64 range(i64 0, 33) %length) #0
  ret i64 %r
}

define i64 @symbolic_read(i64 %fd, i64 %offset, i64 %length) {
entry:
  %r = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},{rsi},{rdx},{r10},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 17, i64 %fd, i64 ptrtoint (ptr getelementptr (i8, ptr @sc_data, i64 80) to i64), i64 range(i64 0, 33) %length, i64 %offset) #0
  ret i64 %r
}

attributes #0 = { nounwind }
