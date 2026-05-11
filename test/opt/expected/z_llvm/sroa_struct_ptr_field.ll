target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

define ptr @sroa_struct_ptr_field(ptr %p) {
entry:
  ret ptr %p
}
