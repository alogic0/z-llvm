target triple = "x86_64-unknown-linux-gnu"
define i64 @whole_compiler_add(i64 %x, i64 %y) {
entry:
  %sum = add i64 %x, %y
  ret i64 %sum
}
