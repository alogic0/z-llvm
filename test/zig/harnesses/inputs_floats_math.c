#include <stdbool.h>
extern float z_float_add(float, float) __asm__("floats_math.float_add");
extern float z_float_select(float, float, bool) __asm__("floats_math.float_select");
int main(void) {
    if (z_float_add(1.5f, 2.25f) != 3.75f) return 1;
    if (z_float_select(8.0f, 4.0f, true) != 8.0f) return 2;
    if (z_float_select(8.0f, 4.0f, false) != 4.0f) return 3;
    return 0;
}

