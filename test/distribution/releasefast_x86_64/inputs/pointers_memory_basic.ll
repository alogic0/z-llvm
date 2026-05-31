source_filename = "pointers_memory"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@volatile_roundtrip = alias i32 (ptr, i32), ptr @pointers_memory.volatile_roundtrip
@load_store = alias i32 (ptr, ptr), ptr @pointers_memory.load_store

define private i32 @pointers_memory.volatile_roundtrip(ptr nonnull %0, i32 %1) unnamed_addr #0 align 1 {
2:
  store volatile i32 %1, ptr %0, align 4
  %3 = load volatile i32, ptr %0, align 4
  ret i32 %3
}

define private range(i32 -2147483647, -2147483648) i32 @pointers_memory.load_store(ptr nonnull readonly captures(none) %0, ptr nonnull writeonly captures(none) initializes((0, 4)) %1) unnamed_addr #1 align 1 {
2:
  %3 = load i32, ptr %0, align 4
  %4 = add nsw i32 %3, 1
  store i32 %4, ptr %1, align 4
  ret i32 %4
}

attributes #0 = { nofree norecurse nounwind memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
