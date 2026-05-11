target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

define ptr @sroa_struct_ptr_field(ptr %p) {
entry:
  %agg = alloca { ptr, i32 }
  %p0 = getelementptr { ptr, i32 }, ptr %agg, i32 0, i32 0
  store ptr %p, ptr %p0
  %x = load ptr, ptr %p0
  ret ptr %x
}
