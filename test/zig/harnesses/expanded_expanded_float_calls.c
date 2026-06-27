#include <stdbool.h>
extern float z_expanded_float_pipeline(float, float, bool) __asm__("expanded_float_calls.expanded_float_pipeline");
extern double z_expanded_double_pipeline(double, double) __asm__("expanded_float_calls.expanded_double_pipeline");
int main(void) {
    if (z_expanded_float_pipeline(1.25f, 2.5f, true) != 3.75f) return 1;
    if (z_expanded_double_pipeline(9.0, 2.0) != 4.5) return 2;
    return 0;
}

