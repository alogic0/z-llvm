define i32 @early_cse_param_gep_noalias_forward(ptr %p, i32 %a) {
entry:
  store i32 %a, ptr %p, align 4
  %field = getelementptr i8, ptr %p, i64 4
  store i32 7, ptr %field, align 4
  ret i32 %a
}
