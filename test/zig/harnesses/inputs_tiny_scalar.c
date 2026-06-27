extern int z_add(int, int) __asm__("tiny_scalar.add");
extern void z_sideEffectFree(void) __asm__("tiny_scalar.sideEffectFree");
int main(void) {
    z_sideEffectFree();
    if (z_add(40, 2) != 42) return 1;
    if (z_add(-7, 9) != 2) return 2;
    return 0;
}

