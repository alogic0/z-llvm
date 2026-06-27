extern float z_float_sub(float, float) __asm__("fp_extended_ops.float_sub");
extern double z_double_div(double, double) __asm__("fp_extended_ops.double_div");
extern float z_float_rem(float, float) __asm__("fp_extended_ops.float_rem");
int main(void) {
    if (z_float_sub(9.0f, 2.5f) != 6.5f) return 1;
    if (z_double_div(9.0, 2.0) != 4.5) return 2;
    if (z_float_rem(7.0f, 2.0f) != 1.0f) return 3;
    return 0;
}

