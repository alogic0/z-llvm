target datalayout = "e-m:e-p:64:64-i24:32-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define ptr @layout_i24_field(ptr %base) {
entry:
  %field = getelementptr { i24, i8 }, ptr %base, i64 0, i32 1
  ret ptr %field
}

define ptr @layout_fp80_field(ptr %base) {
entry:
  %field = getelementptr { x86_fp80, i8 }, ptr %base, i64 0, i32 1
  ret ptr %field
}

define ptr @layout_nested_field(ptr %base) {
entry:
  %field = getelementptr { { i24, i8 }, i16 }, ptr %base, i64 0, i32 1
  ret ptr %field
}

define ptr @layout_array_field(ptr %base) {
entry:
  %field = getelementptr { [2 x { i24, i8 }], i8 }, ptr %base, i64 0, i32 1
  ret ptr %field
}
