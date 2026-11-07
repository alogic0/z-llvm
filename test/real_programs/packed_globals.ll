target datalayout = "e-p:64:64-i64:64-i24:32-i128:128"
target triple = "x86_64-unknown-linux-gnu"

@packed_payload = private constant [8 x i8] c"payload\00"
@packed_object = internal global <{ i8, ptr, i16, ptr, [2 x <{ i8, i32 }>], { i8, i64 }, i8 }> <{ i8 165, ptr getelementptr (i8, ptr @packed_payload, i64 3), i16 4660, ptr @packed_echo, [2 x <{ i8, i32 }>] [<{ i8, i32 }> <{ i8 7, i32 287454020 }>, <{ i8, i32 }> <{ i8 8, i32 -1 }>], { i8, i64 } { i8 9, i64 72623859790382856 }, i8 90 }>, align 64
declare i64 @packed_echo(i64)

define ptr @packed_address() {
entry:
  %address = getelementptr i8, ptr @packed_object, i64 0
  ret ptr %address
}

define ptr @packed_cell(ptr %base, i64 %index) {
entry:
  %address = getelementptr <{ i8, i32 }>, ptr %base, i64 %index, i32 1
  ret ptr %address
}

define ptr @packed_nested(ptr %base) {
entry:
  %address = getelementptr <{ i8, { i8, i64 }, i16 }>, ptr %base, i64 0, i32 1, i32 1
  ret ptr %address
}

define ptr @packed_i24(ptr %base) {
entry:
  %address = getelementptr <{ i24, i8 }>, ptr %base, i64 0, i32 1
  ret ptr %address
}

define ptr @packed_fp80(ptr %base) {
entry:
  %address = getelementptr <{ x86_fp80, i8 }>, ptr %base, i64 0, i32 1
  ret ptr %address
}

define void @packed_store(ptr %base, i64 %value) {
entry:
  %address = getelementptr <{ i8, i64, i8 }>, ptr %base, i64 0, i32 1
  store i64 %value, ptr %address, align 1
  ret void
}
