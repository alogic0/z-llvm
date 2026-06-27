extern float z_float_literal(void) __asm__("fp_constants.float_literal");
extern double z_double_literal(void) __asm__("fp_constants.double_literal");
int main(void) {
    if (z_float_literal() != 1.5f) return 1;
    if (z_double_literal() != 2.25) return 2;
    return 0;
}

