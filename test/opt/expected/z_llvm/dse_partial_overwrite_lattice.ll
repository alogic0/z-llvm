define i16 @dse_partial_overwrite_lattice(i16 %a, i8 %lo, i8 %hi) {
entry:
  %slot = alloca i16
  %byte0 = getelementptr i8, ptr %slot, i32 0
  %byte1 = getelementptr i8, ptr %slot, i32 1
  store i8 %lo, ptr %byte0
  store i8 %hi, ptr %byte1
  %v = load i16, ptr %slot
  ret i16 %v
}
