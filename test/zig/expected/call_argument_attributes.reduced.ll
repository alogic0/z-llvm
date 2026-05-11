target triple = "x86_64-unknown-linux-gnu"

@__anon_3154 = private unnamed_addr constant [13 x i8] c"hello world!\00", align 1

declare i32 @puts(ptr)

define void @start._start() {
entry:
  ret void
}

define void @start.posixCallMainAndExit() {
entry:
  ret void
}

define void @inline_asm_caller() {
entry:
  tail call void asm sideeffect " xorl %ebp, %ebp\0A movq %rsp, %rdi\0A andq $$-16, %rsp\0A callq ${1:P}", "X,X,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @start._start, ptr nonnull @start.posixCallMainAndExit) #11
  ret void
}

define i32 @puts_caller() {
entry:
  %1 = tail call i32 @puts(ptr nonnull readonly align 1 dereferenceable(1) @__anon_3154)
  ret i32 %1
}

attributes #11 = { nounwind }
