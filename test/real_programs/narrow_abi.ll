target datalayout = "e-p:64:64-i64:64"
target triple = "x86_64-unknown-linux-gnu"

declare fastcc i3 @narrow_dirty_3(i3)
declare fastcc i8 @narrow_dirty_8(i8)
declare fastcc i16 @narrow_dirty_16(i16)
declare i16 @narrow_dirty_constants(i3, i8, i16)
declare i32 @narrow_seed(i64)
declare void @narrow_record(i1)

define i64 @narrow_entry_1(i1 %input, i64 %live, ptr %output) {
entry:
  %wide = zext i1 %input to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i1 @narrow_return_1(i64 %input, i64 %live, ptr %output) {
entry:
  %combined = xor i64 %input, %live
  %small = trunc i64 %combined to i1
  %wide = zext i1 %small to i64
  store i64 %wide, ptr %output, align 8
  ret i1 %small
}

define i64 @narrow_entry_3(i3 %input, i64 %live, ptr %output) {
entry:
  %wide = zext i3 %input to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i3 @narrow_return_3(i64 %input, i64 %live, ptr %output) {
entry:
  %combined = xor i64 %input, %live
  %small = trunc i64 %combined to i3
  %wide = zext i3 %small to i64
  store i64 %wide, ptr %output, align 8
  ret i3 %small
}

define i64 @narrow_entry_8(i8 %input, i64 %live, ptr %output) {
entry:
  %wide = zext i8 %input to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i8 @narrow_return_8(i64 %input, i64 %live, ptr %output) {
entry:
  %combined = xor i64 %input, %live
  %small = trunc i64 %combined to i8
  %wide = zext i8 %small to i64
  store i64 %wide, ptr %output, align 8
  ret i8 %small
}

define i64 @narrow_entry_16(i16 %input, i64 %live, ptr %output) {
entry:
  %wide = zext i16 %input to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i16 @narrow_return_16(i64 %input, i64 %live, ptr %output) {
entry:
  %combined = xor i64 %input, %live
  %small = trunc i64 %combined to i16
  %wide = zext i16 %small to i64
  store i64 %wide, ptr %output, align 8
  ret i16 %small
}

define i64 @narrow_call_3(i64 %input, i64 %live, ptr %output) {
entry:
  %small = trunc i64 %input to i3
  %called = call fastcc i3 @narrow_dirty_3(i3 %small)
  %wide = zext i3 %called to i64
  store i64 %wide, ptr %output, align 8
  %original = xor i64 %wide, %input
  %result = xor i64 %original, %live
  ret i64 %result
}

define i64 @narrow_call_8(i64 %input, i64 %live, ptr %output) {
entry:
  %small = trunc i64 %input to i8
  %called = call fastcc i8 @narrow_dirty_8(i8 %small)
  %wide = zext i8 %called to i64
  store i64 %wide, ptr %output, align 8
  %original = xor i64 %wide, %input
  %result = xor i64 %original, %live
  ret i64 %result
}

define i64 @narrow_call_16(i64 %input, i64 %live, ptr %output) {
entry:
  %small = trunc i64 %input to i16
  %called = call fastcc i16 @narrow_dirty_16(i16 %small)
  %wide = zext i16 %called to i64
  store i64 %wide, ptr %output, align 8
  %original = xor i64 %wide, %input
  %result = xor i64 %original, %live
  ret i64 %result
}

define i64 @narrow_constants(i64 %input, i64 %live, ptr %output) {
entry:
  %small = call i16 @narrow_dirty_constants(i3 -4, i8 -1, i16 -32768)
  %wide = zext i16 %small to i64
  store i64 %wide, ptr %output, align 8
  %original = xor i64 %wide, %input
  %result = xor i64 %original, %live
  ret i64 %result
}

define void @narrow_last_use(i64 %input) {
entry:
  %seed = call i32 @narrow_seed(i64 %input)
  %condition = icmp eq i32 %seed, 1
  call void @narrow_record(i1 %condition)
  ret void
}
