define ptr @mem2reg_escape() {
entry:
  %slot = alloca i32
  ret ptr %slot
}
