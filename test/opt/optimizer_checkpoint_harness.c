#include <assert.h>
#include <stdint.h>
#include <stdio.h>

extern int32_t checkpoint_global(void);
extern int32_t checkpoint_loop(int32_t);
extern int32_t checkpoint_forward(int32_t);
extern int32_t checkpoint_lane(int32_t);
extern int32_t checkpoint_signed_lane(int32_t);
extern int32_t checkpoint_bypass(int32_t);
extern int32_t checkpoint_distinct(int32_t);
extern int32_t checkpoint_shuffle(int32_t);
extern uint8_t checkpoint_shl(void);
extern uint8_t checkpoint_lshr(void);
extern int8_t checkpoint_ashr(void);

int main(void) {
    assert(checkpoint_global() == 7);
    assert(checkpoint_shl() == 1);
    assert(checkpoint_lshr() == 64);
    assert(checkpoint_ashr() == -2);
    for (int32_t n = 1; n <= 64; ++n)
        assert(checkpoint_loop(n) == n * (n - 1) / 2);
    const int32_t boundary[] = {INT32_MIN, INT32_MAX, -1, 0, 1, 42};
    uint32_t seed = 0x5eed1234;
    for (unsigned i = 0; i < 262; ++i) {
        seed = seed * 1664525u + 1013904223u;
        int32_t x = i < 6 ? boundary[i] : (int32_t)seed;
        assert(checkpoint_forward(x) == x);
        assert(checkpoint_lane(x) == x);
        assert(checkpoint_signed_lane(x) == x);
        assert(checkpoint_bypass(x) == x);
        assert(checkpoint_distinct(x) == 0);
        assert(checkpoint_shuffle(x) == x);
    }
    puts("ok correctness checkpoint: 11 functions, 1640 observations, seed=5eed1234");
    return 0;
}
