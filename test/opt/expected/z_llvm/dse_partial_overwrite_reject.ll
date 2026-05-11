define i32 @dse_partial_overwrite_reject(i32 %a, i8 %b) {
entry:
  %slot = alloca i32
  %byte = getelementptr i8, ptr %slot, i32 0
  store i32 %a, ptr %slot
  store i8 %b, ptr %byte
  %v = load i32, ptr %slot
  ret i32 %v
}
