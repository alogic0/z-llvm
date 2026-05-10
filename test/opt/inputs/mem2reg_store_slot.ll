define i32 @mem2reg_store_slot(ptr %sink) {
entry:
  %slot = alloca i32
  store ptr %slot, ptr %sink
  ret i32 0
}
