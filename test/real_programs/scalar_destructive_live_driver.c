#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef uint64_t (*function_t)(const void *, uint64_t, uint64_t, uint64_t *);
#define DECLARE(bits) \
    extern uint64_t destructive_shift##bits(const void *, uint64_t, uint64_t, uint64_t *); \
    extern uint64_t destructive_loop##bits(const void *, uint64_t, uint64_t, uint64_t *)
DECLARE(16); DECLARE(32); DECLARE(64);
extern uint64_t destructive_bool_and(const void *, uint64_t, uint64_t, uint64_t *);
extern uint64_t destructive_bool_or(const void *, uint64_t, uint64_t, uint64_t *);
static size_t observations;
static const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
static uint64_t mask(unsigned bits) { return bits == 64 ? UINT64_MAX : (UINT64_C(1) << bits) - 1; }
static int one(function_t function, unsigned bits, unsigned kind, unsigned seed, unsigned amount, unsigned count, unsigned fault) {
    uint64_t words[9], expected[8];
    unsigned char input[88], saved[88];
    struct { uint64_t before, values[8], after; } output;
    memset(input, 0x5a, sizeof input);
    memset(&output, 0xa5, sizeof output);
    for (unsigned i = 0; i < 8; i++) expected[i] = guard;
    for (unsigned i = 0; i < 9; i++) {
        words[i] = (seed == 0 ? 0 : seed == 1 ? UINT64_MAX : seed == 2 ? UINT64_C(1) << (bits - 1) :
                    seed == 3 ? 1 : (UINT64_C(0xf06dea67e461de5b) * (seed + 1)) ^ (UINT64_C(0x9e3779b97f4a7c15) * i)) & mask(bits);
        for (unsigned byte = 0; byte < (bits + 7) / 8; byte++) input[1 + i * ((bits + 7) / 8) + byte] = (unsigned char)(words[i] >> (byte * 8));
    }
    memcpy(saved, input, sizeof input);
    uint64_t returned = words[0];
    if (kind == 0) {
        expected[0] = (words[0] << amount) & mask(bits);
        expected[1] = words[0] >> amount;
        expected[2] = expected[1];
        if (amount && (words[0] & (UINT64_C(1) << (bits - 1)))) expected[2] |= mask(bits) ^ (mask(bits) >> amount);
    } else if (kind == 1) {
        for (unsigned i = 0; i < count; i++) expected[i] = ((words[i] >> amount) | (words[i + 1] << ((0u - amount) & (bits - 1)))) & mask(bits);
        returned = words[count];
    } else expected[0] = kind == 2 ? words[0] & amount : words[0] | amount;
    uint64_t got = function(input + 1, amount, count, output.values);
    if (fault == 1) got ^= 1;
    if (fault == 2) output.values[0] ^= 1;
    if (fault == 3) output.after ^= 1;
    unsigned checks[12] = {got == returned, output.before == guard, output.after == guard, memcmp(input, saved, sizeof input) == 0};
    for (unsigned i = 0; i < 8; i++) checks[4 + i] = output.values[i] == expected[i];
    for (unsigned i = 0; i < 12; i++) {
        observations++;
        if (!checks[i]) {
            fprintf(stderr, "scalar-destructive-live bits=%u kind=%u seed=%u amount=%u count=%u check=%u fault=%u observations=%zu\n", bits, kind, seed, amount, count, i, fault, observations);
            return 1;
        }
    }
    return 0;
}
int main(int argc, char **argv) {
    const unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    const function_t shifts[] = {destructive_shift16, destructive_shift32, destructive_shift64};
    const function_t loops[] = {destructive_loop16, destructive_loop32, destructive_loop64};
    for (unsigned width = 0; width < 3; width++) {
        const unsigned bits = 16u << width, amounts[] = {0, 1, bits / 2, bits - 1}, counts[] = {1, 2, 3, 7};
        for (unsigned seed = 0; seed < 8; seed++) for (unsigned amount = 0; amount < 4; amount++) {
            if (one(shifts[width], bits, 0, seed, amounts[amount], 1, fault)) return 1;
            for (unsigned count = 0; count < 4; count++) if (one(loops[width], bits, 1, seed, amounts[amount], counts[count], fault)) return 1;
        }
    }
    for (unsigned seed = 0; seed < 2; seed++) for (unsigned amount = 0; amount < 2; amount++) {
        if (one(destructive_bool_and, 1, 2, seed, amount, 1, fault) || one(destructive_bool_or, 1, 3, seed, amount, 1, fault)) return 1;
    }
    printf("scalar-destructive-live observations=%zu shifts=booleans=loop-phis=guards=preserved\n", observations);
    return 0;
}
