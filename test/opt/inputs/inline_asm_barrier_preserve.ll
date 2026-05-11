define i32 @inline_asm_barrier_preserve(i32 %value) {
entry:
  %dead = add i32 %value, 0
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #0
  ret i32 %value
}

attributes #0 = { nounwind }
