#include <assert.h>
#include <stdint.h>
#include <stdio.h>

extern int32_t adce_vector_result(int32_t x, int32_t index);

int main(void) {
    for (int32_t x = -19; x <= 19; ++x) {
        for (int32_t index = 0; index < 4; ++index) {
            assert(adce_vector_result(x, index) == ((index & 1) ? 0 : x + 3));
        }
    }
    puts("ok ADCE vector operands: 156 observations");
    return 0;
}
