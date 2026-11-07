target triple = "x86_64-unknown-linux-gnu"

declare void @runtime_memory_clobber()
declare ptr @runtime_memory_identity(ptr)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1 immarg)
declare noalias ptr @runtime_memory_allocate(i64, i64) #0
declare ptr @runtime_memory_resize(ptr allocptr noundef align 1 captures(none), i64, i64) #1
declare void @runtime_memory_release(ptr allocptr noundef align 1 captures(none)) #2

define void @runtime_memory_f32(ptr %input, ptr %output, ptr %preserved) {
entry:
  %p1 = getelementptr i8, ptr %input, i64 4
  %a = load float, ptr %input, align 1
  %b = load float, ptr %p1, align 1
  %q1 = getelementptr i8, ptr %output, i64 4
  store float %b, ptr %output, align 1
  store float %a, ptr %q1, align 1
  %k1 = getelementptr i8, ptr %preserved, i64 4
  store float %a, ptr %preserved, align 1
  store float %b, ptr %k1, align 1
  ret void
}

define void @runtime_memory_f64(ptr %input, ptr %output, ptr %preserved) {
entry:
  %p1 = getelementptr i8, ptr %input, i64 8
  %a = load double, ptr %input, align 1
  %b = load double, ptr %p1, align 1
  call void @runtime_memory_clobber()
  %q1 = getelementptr i8, ptr %output, i64 8
  store double %b, ptr %output, align 1
  store double %a, ptr %q1, align 1
  %k1 = getelementptr i8, ptr %preserved, i64 8
  store double %a, ptr %preserved, align 1
  store double %b, ptr %k1, align 1
  ret void
}

define void @runtime_memory_returned(ptr %input, ptr %output, i64 %offset) {
entry:
  %p = getelementptr i8, ptr %input, i64 %offset
  %a = load double, ptr %p, align 1
  %q = call ptr @runtime_memory_identity(ptr %output)
  store double %a, ptr %q, align 1
  ret void
}

define void @runtime_memory_pressure(ptr %input, ptr %output, double %a, double %b, double %c, double %d, double %e, double %f, double %g, double %h) {
entry:
  %loaded = load double, ptr %input, align 1
  call void @runtime_memory_clobber()
  %p1 = getelementptr i8, ptr %output, i64 8
  %p2 = getelementptr i8, ptr %output, i64 16
  %p3 = getelementptr i8, ptr %output, i64 24
  %p4 = getelementptr i8, ptr %output, i64 32
  %p5 = getelementptr i8, ptr %output, i64 40
  %p6 = getelementptr i8, ptr %output, i64 48
  %p7 = getelementptr i8, ptr %output, i64 56
  %p8 = getelementptr i8, ptr %output, i64 64
  store double %a, ptr %output, align 1
  store double %b, ptr %p1, align 1
  store double %c, ptr %p2, align 1
  store double %d, ptr %p3, align 1
  store double %e, ptr %p4, align 1
  store double %f, ptr %p5, align 1
  store double %g, ptr %p6, align 1
  store double %h, ptr %p7, align 1
  store double %loaded, ptr %p8, align 1
  ret void
}

define i64 @runtime_memory_memset(ptr %output, i64 %length, i8 %fill) {
entry:
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull writeonly align 1 captures(none) dereferenceable(16) %output, i8 %fill, i64 %length, i1 false)
  ret i64 %length
}

define i64 @runtime_memory_allocation(i64 %length, i64 %cookie, i64 %fail_alloc, i64 %fail_resize) {
entry:
  %p = call ptr @runtime_memory_allocate(i64 %length, i64 %fail_alloc)
  %empty = icmp eq ptr %p, null
  br i1 %empty, label %allocation_failed, label %allocated
allocation_failed:
  call void @runtime_memory_release(ptr allocptr noundef align 1 captures(none) null)
  ret i64 -1
allocated:
  store i64 %cookie, ptr %p, align 1
  %size = shl i64 %length, 1
  %q = call ptr @runtime_memory_resize(ptr allocptr noundef align 1 captures(none) %p, i64 %size, i64 %fail_resize)
  %failed = icmp eq ptr %q, null
  br i1 %failed, label %resize_failed, label %resized
resize_failed:
  %old = load i64, ptr %p, align 1
  call void @runtime_memory_release(ptr allocptr noundef align 1 captures(none) %p)
  %error_result = xor i64 %old, -1
  ret i64 %error_result
resized:
  %value = load i64, ptr %q, align 1
  call void @runtime_memory_release(ptr allocptr noundef align 1 captures(none) %q)
  ret i64 %value
}

define float @runtime_memory_nneg(i8 %input) {
entry:
  %converted = uitofp nneg i8 %input to float
  ret float %converted
}

attributes #0 = { nounwind allockind("alloc,uninitialized") allocsize(0) "alloc-family"="runtime-memory" }
attributes #1 = { nounwind allockind("realloc,uninitialized") allocsize(1) "alloc-family"="runtime-memory" }
attributes #2 = { nounwind allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="runtime-memory" }
