source_filename = "discover2_gap_closure"
target triple = "x86_64-unknown-linux-gnu"

%"atomic.Value(usize)" = type { i64 }
%Packed.Container = type { <{ %"atomic.Value(usize)", [24 x i8] }>, i3, [7 x i8] }

@external_variable = external global i32, align 4
@ptr_to_external = private unnamed_addr constant ptr @external_variable, align 8
@anon_pair = private unnamed_addr constant { ptr, i64 } { ptr @external_variable, i64 0 }, align 8
@packed_global = private unnamed_addr constant %Packed.Container { <{ %"atomic.Value(usize)", [24 x i8] }> undef, i3 0, [7 x i8] undef }, align 8

@bar = weak_odr alias void (), ptr @"quoted target.fn"

declare void @llvm.experimental.noalias.scope.decl(metadata)

declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg)

declare i32 @printf(ptr noundef nonnull readonly align 1 captures(none), ...)

define void @"quoted target.fn"() {
entry:
  ret void
}

define i8 @cast_flags(i32 %x) {
entry:
  %t = trunc nuw i32 %x to i8
  ret i8 %t
}

define i32 @call_attrs(ptr %p, i8 %code) {
entry:
  call void @llvm.experimental.noalias.scope.decl(metadata !0)
  %wide = zext i8 %code to i64
  %printed = call i32 (ptr, ...) @printf(ptr noundef nonnull readonly align 1 dereferenceable(8) getelementptr inbounds nuw (i8, ptr @anon_pair, i64 0), double 2.000000e+00)
  call void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none) %p, ptr noalias readonly captures(none) @ptr_to_external, i64 8, i1 immarg 0)
  %exit = call i64 asm sideeffect "syscall", "={rax},{rax},{rdi},~{memory},~{rcx},~{r11},~{dirflag},~{fpsr},~{flags}"(i64 231, i64 range(i64 0, 256) %wide)
  ret i32 %printed
}

define void @addrspace_store() {
entry:
  store i64 98765, ptr addrspace(257) null, align 4294967296
  ret void
}

define i32 @multi_edge_phi(i32 %x) {
entry:
  switch i32 %x, label %join [
    i32 0, label %join
    i32 1, label %join
  ]
join:
  %v = phi i32 [ 0, %entry ], [ 0, %entry ], [ 0, %entry ]
  ret i32 %v
}

!llvm.module.flags = !{}
!0 = !{!1}
!1 = distinct !{!1, !"scope"}
