#include <stdbool.h>
extern bool z_float_less(float, float) __asm__("float_compare.float_less");
extern double z_float_mul(double, double) __asm__("float_compare.float_mul");
int main(void) {
    if (!z_float_less(1.0f, 2.0f)) return 1;
    if (z_float_less(2.0f, 1.0f)) return 2;
    if (z_float_mul(3.0, 4.0) != 12.0) return 3;
    return 0;
}

