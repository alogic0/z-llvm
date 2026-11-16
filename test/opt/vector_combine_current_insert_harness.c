#include <stdint.h>
#include <limits.h>

extern int32_t vector_combine_current_insert(int32_t);

int main(void) {
    const int32_t edges[] = {0, 1, -1, INT32_MIN, INT32_MAX, 0x55555555, (int32_t)0xaaaaaaaa};
    for (unsigned i = 0; i < sizeof(edges) / sizeof(edges[0]); ++i)
        if (vector_combine_current_insert(edges[i]) != edges[i]) return 1;
    uint32_t bits = 0x12345678;
    for (unsigned i = 0; i < 65536; ++i) {
        bits = bits * 1664525u + 1013904223u;
        if (vector_combine_current_insert((int32_t)bits) != (int32_t)bits) return 2;
    }
    return 0;
}
