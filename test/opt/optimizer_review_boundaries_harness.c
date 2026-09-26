#include <assert.h>
#include <stdint.h>
#include <stdio.h>

extern int8_t boundary_min(void);
extern int8_t boundary_max(void);
extern unsigned __int128 boundary_udiv127(void);
extern unsigned __int128 boundary_urem127(void);
extern unsigned __int128 boundary_udiv128(void);
extern uint8_t boundary_alloca(uint64_t);
extern uint8_t boundary_folded_alloca(void);

static unsigned count;
void boundary_fill(uint8_t *buffer) {
    for (unsigned i = 0; i < count; ++i) buffer[i] = (uint8_t)(i * 17 + 3);
}

int main(void) {
    assert(boundary_min() == -1);
    assert(boundary_max() == 1);
    assert(boundary_udiv127() == (((unsigned __int128)1 << 126) - 1));
    assert(boundary_urem127() == 1);
    assert(boundary_udiv128() == ~(unsigned __int128)0);
    for (count = 1; count <= 128; ++count)
        assert(boundary_alloca(count - 1) == (uint8_t)((count - 1) * 17 + 3));
    count = 32;
    assert(boundary_folded_alloca() == (uint8_t)(31 * 17 + 3));
    puts("ok optimizer review boundaries: 7 functions, 134 observations");
    return 0;
}
