define i32 @licm_atomic_store_barrier_reject(i32 %a, ptr %p) {
entry:
  br label %header
header:
  %x = add i32 %a, 1
  store atomic i32 %a, ptr %p release, align 4
  %c = icmp sgt i32 %x, 0
  br i1 %c, label %body, label %exit
body:
  br label %latch
latch:
  br label %header
exit:
  ret i32 %a
}
