target triple = "x86_64-unknown-linux-gnu"
@symbolic_word_data = global [64 x i8] zeroinitializer, align 16

define i64 @symbolic_word_lhs(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %difference = sub i64 ptrtoint (ptr @symbolic_word_data to i64), %a
  %result = xor i64 %difference, %f
  ret i64 %result
}

define i64 @symbolic_word_rhs(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %difference = sub i64 %a, ptrtoint (ptr @symbolic_word_data to i64)
  %result = xor i64 %difference, %f
  ret i64 %result
}

define i64 @symbolic_word_offset(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %difference = sub i64 ptrtoint (ptr getelementptr (i8, ptr @symbolic_word_data, i64 17) to i64), %a
  %result = xor i64 %difference, %f
  ret i64 %result
}

define i64 @symbolic_word_quoted(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %difference = sub i64 ptrtoint (ptr getelementptr (i8, ptr @"symbolic\5Fword_data", i64 9) to i64), %a
  %result = xor i64 %difference, %f
  ret i64 %result
}

define i64 @symbolic_word_both(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %difference = sub i64 ptrtoint (ptr getelementptr (i8, ptr @"symbolic\5Fword_data", i64 9) to i64), ptrtoint (ptr getelementptr (i8, ptr @symbolic_word_data, i64 -8) to i64)
  %with_input = xor i64 %difference, %a
  %result = xor i64 %with_input, %f
  ret i64 %result
}

define i64 @symbolic_word_pressure(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %difference = sub i64 ptrtoint (ptr @symbolic_word_data to i64), %a
  %one = xor i64 %difference, %b
  %two = add i64 %one, %c
  %three = xor i64 %two, %d
  %four = sub i64 %three, %e
  %result = xor i64 %four, %f
  ret i64 %result
}
