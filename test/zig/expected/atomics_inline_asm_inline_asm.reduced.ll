source_filename = "atomics_inline_asm_debug"

define i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 %value) {
entry:
  call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"()
  ret i32 %value
}
