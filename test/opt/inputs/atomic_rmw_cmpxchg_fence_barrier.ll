define void @atomic_rmw_cmpxchg_fence_barrier(ptr %p, i32 %old, i32 %new) {
entry:
  %dead = add i32 %old, 0
  %rmw = atomicrmw add ptr %p, i32 %new monotonic, align 4
  %pair = cmpxchg ptr %p, i32 %old, i32 %new monotonic monotonic, align 4
  fence seq_cst
  ret void
}
