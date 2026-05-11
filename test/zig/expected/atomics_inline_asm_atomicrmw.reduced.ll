source_filename = "atomics_inline_asm_debug"

@atomics_inline_asm_debug.atomic_counter = private unnamed_addr global i32 0, align 4

define i32 @atomics_inline_asm_debug.atomic_add(i32 %value) {
entry:
  %old = atomicrmw add ptr @atomics_inline_asm_debug.atomic_counter, i32 %value monotonic, align 4
  ret i32 %old
}
