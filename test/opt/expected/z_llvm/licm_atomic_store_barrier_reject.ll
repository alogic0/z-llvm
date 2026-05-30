define i32 @licm_atomic_store_barrier_reject(i32 %a, ptr %p) {
entry:
  %x = add i32 %a, 1
  %c = icmp sgt i32 %x, 0
  br label %header
header:
  store atomic i32 %a, ptr %p release, align 4
  br i1 %c, label %body, label %exit
body:
  br label %latch
latch:
  br label %header
exit:
  ret i32 %a
}
