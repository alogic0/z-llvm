define i32 @inline_asm_sideeffect_preserve(i32 %x) {
entry:
  call void asm sideeffect "", "~{dirflag},~{fpsr},~{flags}"()
  ret i32 %x
}

