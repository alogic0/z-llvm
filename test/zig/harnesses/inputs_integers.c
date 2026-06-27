extern int z_add_wrap(int, int) __asm__("integers.add_wrap");
extern unsigned z_shift_mix(unsigned, unsigned) __asm__("integers.shift_mix");
extern int z_cmp_select(int, int) __asm__("integers.cmp_select");
int main(void) {
    if (z_add_wrap(2147483647, 1) != (-2147483647 - 1)) return 1;
    if (z_shift_mix(8u, 1u) != 20u) return 2;
    if (z_cmp_select(7, 3) != 3) return 3;
    if (z_cmp_select(-4, 9) != -4) return 4;
    return 0;
}

