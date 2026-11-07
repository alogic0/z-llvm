@whole_compiler_missing_reference = global ptr @missing_definition
define i64 @whole_compiler_valid_body(i64 %x) {
entry:
  ret i64 %x
}
