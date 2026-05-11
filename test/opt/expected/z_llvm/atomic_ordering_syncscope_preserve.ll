define i32 @atomic_ordering_syncscope_preserve(ptr %p, i32 %old, i32 %new) {
entry:
  %a = load atomic i32, ptr %p syncscope("singlethread") acquire, align 4
  store atomic i32 %a, ptr %p syncscope("singlethread") release, align 4
  %rmw = atomicrmw add ptr %p, i32 %new syncscope("singlethread") monotonic, align 4
  %pair = cmpxchg weak ptr %p, i32 %old, i32 %new syncscope("singlethread") acq_rel monotonic, align 4
  fence syncscope("singlethread") seq_cst
  ret i32 %a
}
