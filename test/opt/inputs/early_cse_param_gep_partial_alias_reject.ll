define i32 @early_cse_param_gep_partial_alias_reject(ptr %p, i32 %a) {
entry:
  %overlap = getelementptr i8, ptr %p, i64 2
  store i32 %a, ptr %overlap, align 1
  %loaded = load i32, ptr %p, align 4
  ret i32 %loaded
}
