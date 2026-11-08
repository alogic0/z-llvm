target datalayout = "e-p:64:64-i64:64"
target triple = "x86_64-unknown-linux-gnu"

declare noundef range(i8 -16, 16) i8 @facts_dirty_byte(i8, i16)
declare range(i16 0, 32768) i16 @facts_dirty_stack(i8, i16, i8, i16, i32, i64, i8, i16)
declare range(i16 0, 32768) i16 @facts_dirty_word(i16)
declare noundef i1 @facts_dirty_boolean(i64)

define range(i16 0, 32768) i16 @facts_call(i8 range(i8 -16, 16) %a, i16 noundef %b, i64 %live, ptr %output) {
entry:
  %called = call noundef range(i8 -16, 16) i8 @facts_dirty_byte(i8 range(i8 -16, 16) %a, i16 noundef %b)
  %wide = zext i8 %called to i64
  %aw = zext i8 %a to i64
  %bw = zext i16 %b to i64
  %with_a = add i64 %wide, %aw
  %with_b = xor i64 %with_a, %bw
  %combined = xor i64 %with_b, %live
  store i64 %combined, ptr %output, align 8
  %bounded = and i64 %combined, 32767
  %result = trunc i64 %bounded to i16
  ret i16 %result
}

define noundef range(i16 0, 32768) i16 @facts_stack(i8 range(i8 -16, 16) %a, i16 noundef %b, i8 %c, i16 range(i16 0, -1) %d, i32 %e, i64 %live, i8 range(i8 0, 16) %g, i16 %h, ptr %output) {
entry:
  %called = call range(i16 0, 32768) i16 @facts_dirty_stack(i8 range(i8 -16, 16) %a, i16 noundef %b, i8 %c, i16 range(i16 0, -1) %d, i32 %e, i64 %live, i8 range(i8 0, 16) %g, i16 %h)
  %wide = zext i16 %called to i64
  %combined = xor i64 %wide, %live
  store i64 %combined, ptr %output, align 8
  ret i16 %called
}

define i32 @facts_phi(i64 %input, i64 %choose, i64 %live, ptr %output) {
entry:
  %low = trunc i64 %input to i8
  %nibble = and i8 %low, 15
  %condition = icmp eq i64 %choose, 0
  br i1 %condition, label %lo, label %hi
lo:
  br label %join
hi:
  %high = or i8 %nibble, -16
  br label %join
join:
  %arg = phi i8 [ %nibble, %lo ], [ %high, %hi ]
  %called = call noundef range(i8 -16, 16) i8 @facts_dirty_byte(i8 noundef range(i8 -16, 16) %arg, i16 noundef 1)
  %wide = zext i8 %called to i64
  %combined = xor i64 %wide, %live
  store i64 %combined, ptr %output, align 8
  %result = trunc i64 %combined to i32
  ret i32 %result
}

define i64 @facts_boolean(i64 %input, i64 %live) {
entry:
  %called = call noundef i1 @facts_dirty_boolean(i64 %input)
  br i1 %called, label %yes, label %no
yes:
  %changed = xor i64 %live, 90
  ret i64 %changed
no:
  ret i64 %live
}

define i64 @facts_ignored(i64 %input) {
entry:
  %small = trunc i64 %input to i16
  %ignored = call range(i16 0, 32768) i16 @facts_dirty_word(i16 noundef %small)
  ret i64 %input
}
