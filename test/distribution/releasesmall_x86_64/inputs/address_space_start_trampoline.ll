source_filename = "address_space_pointer_access_chaining_pointer_to_optional_array"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@_start = alias void (), ptr @start._start

declare void @start.posixCallMainAndExit(ptr)

define private void @start._start() unnamed_addr align 1 {
0:
  tail call void asm sideeffect ".cfi_undefined %rip", "~{dirflag},~{fpsr},~{flags}"()
  tail call void asm sideeffect " xorl %ebp, %ebp\0A movq %rsp, %rdi\0A andq $$-16, %rsp\0A callq ${1:P}", "X,X,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @start._start, ptr nonnull @start.posixCallMainAndExit)
  unreachable
}
