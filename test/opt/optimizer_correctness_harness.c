#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

extern int32_t cse_sibling(int32_t *, bool);
extern int32_t cse_join(int32_t *, bool);
extern int32_t cse_loop(int32_t *, int32_t);
extern int8_t signed_div(void);
extern int8_t signed_rem(void);
extern unsigned __int128 wide_mul(void);
extern unsigned __int128 wide_add(void);
extern unsigned __int128 wide_sub(void);
extern uint64_t unsigned_spelling_mul(void);
extern int32_t licm_counter(int32_t);
extern int32_t licm_load(int32_t *, int32_t);

int main(void) {
    for (int condition = 0; condition <= 1; ++condition) {
        int32_t p = -1;
        assert(cse_sibling(&p, condition) == (condition ? 2 : 1));
        assert(p == (condition ? 2 : 1));
        p = -1;
        assert(cse_join(&p, condition) == (condition ? 2 : 1));
        assert(p == (condition ? 2 : 1));
    }
    assert(signed_div() == -1);
    assert(signed_rem() == -1);
    assert(wide_mul() == 0);
    assert(wide_add() == ((unsigned __int128)1 << 127));
    assert(wide_sub() == (((unsigned __int128)1 << 127) - 1));
    assert(unsigned_spelling_mul() == 1);
    for (int32_t n = 1; n <= 4; ++n) {
        int32_t p = -1;
        int32_t values[] = {7, -8, 123, -456};
        assert(cse_loop(&p, n) == (n == 1 ? 1 : 2));
        assert(p == 2);
        assert(licm_counter(n) == n);
        assert(licm_load(values, n) == (n == 1 ? 7 : values[n - 1]));
        assert(values[0] == 99);
    }
    puts("ok optimizer correctness: 11 functions");
    return 0;
}
