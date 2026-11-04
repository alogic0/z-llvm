#include <assert.h>
#include <stdint.h>
#include <stdio.h>

extern int32_t spelling_store_load(int32_t);
extern int32_t spelling_reverse_store_load(int32_t);
extern int32_t spelling_escape_store_load(int32_t);
extern int32_t spelling_alias_store_load(int32_t);
extern int32_t spelling_read_constants(void);
extern int32_t spelling_alias;

int main(void) {
    static const int32_t inputs[] = {
        INT32_MIN, INT32_MIN + 1, -1000000, -1024, -31, -1, 0, 1,
        7, 17, 23, 29, 31, 1000000, INT32_MAX - 1, INT32_MAX
    };
    for (unsigned i = 0; i < sizeof(inputs) / sizeof(inputs[0]); ++i) {
        const int32_t x = inputs[i];
        const int32_t direct = spelling_store_load(x);
        const int32_t reverse = spelling_reverse_store_load(x);
        const int32_t escaped = spelling_escape_store_load(x);
        const int32_t aliased = spelling_alias_store_load(x);
        const int32_t constants = spelling_read_constants();
        assert(direct == x && reverse == x && escaped == x && aliased == x);
        assert(spelling_alias == x && constants == 1148);
        printf("%u %d %d %d %d %d\n", i, direct, reverse, escaped, aliased, constants);
    }
    return 0;
}
