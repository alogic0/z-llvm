extern unsigned z_atomic_add(unsigned) __asm__("atomics_inline_asm_debug.atomic_add");
extern int z_inline_asm_barrier(int) __asm__("atomics_inline_asm_debug.inline_asm_barrier");
extern int z_debug_location(int) __asm__("atomics_inline_asm_debug.debug_location");
int main(void) {
    if (z_atomic_add(5) != 0) return 1;
    if (z_atomic_add(7) != 5) return 2;
    if (z_inline_asm_barrier(19) != 19) return 3;
    if (z_debug_location(41) != 42) return 4;
    return 0;
}

