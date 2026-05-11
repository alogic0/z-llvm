define i32 @inline_asm_barrier_preserve(i32 %value) {
entry:
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #0
  ret i32 %value
}

attributes #0 = { nounwind }
