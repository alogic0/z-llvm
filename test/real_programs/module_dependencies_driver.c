#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

typedef uint64_t (*callback)(uint64_t);
extern uint64_t module_entry(uint64_t);
extern uint32_t module_fib(uint32_t);
extern callback module_callback;
extern callback module_callback_alias;
extern const callback *module_get_slot(void);

uint64_t module_external_word(uint64_t x) { return x ^ UINT64_C(0xfedcba9876543210); }

int main(void) {
    static const uint64_t inputs[] = {0, 1, 2, 127, 0xffffffff,
        UINT64_C(0x8000000000000000), UINT64_C(0xfffffffffffffffe), UINT64_MAX};
    volatile uint64_t guards[] = {UINT64_C(0x12345678abcddcba), UINT64_C(0xfedcba9801234567)};
    unsigned observations = 0;
    const callback *slot = module_get_slot();
    if (!slot || !*slot || !module_callback || module_callback_alias != module_callback) return 1;
    for (unsigned i = 0; i < sizeof inputs / sizeof inputs[0]; ++i) {
        uint64_t x = inputs[i];
        uint64_t expected = ((module_external_word(x) + 17) + x) ^ UINT64_C(918273645);
        if (module_entry(x) != expected || module_callback(x) != (x ^ UINT64_C(123456789)) ||
            (*slot)(x) != x + UINT64_C(987654321)) {
            fprintf(stderr, "module dependency mismatch input=%" PRIu64 "\n", x);
            return 2;
        }
        observations += 3;
    }
    uint32_t current = 0, next = 1;
    for (uint32_t n = 0; n <= 30; ++n) {
        if (module_fib(n) != current) return 3;
        uint32_t sum = current + next;
        current = next;
        next = sum;
        ++observations;
    }
    if (guards[0] != UINT64_C(0x12345678abcddcba) || guards[1] != UINT64_C(0xfedcba9801234567)) return 4;
    printf("module-dependencies observations=%u aliases=helpers=recursion=callbacks=imports=guards=preserved\n", observations);
    return 0;
}
