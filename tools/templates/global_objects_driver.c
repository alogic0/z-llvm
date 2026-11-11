#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern const unsigned char *global_objects_escape(void);
extern const unsigned char *global_objects_poison(void);
extern const unsigned char *global_objects_float(void);
extern const unsigned char *global_objects_half(void);
extern const unsigned char *global_objects_extended(void);
extern const unsigned char *global_objects_relative(void);
extern unsigned char *global_objects_first(void);
extern unsigned char *global_objects_second(void);
extern unsigned char *const *global_objects_many(void);

static uint16_t word16(const void *p) { uint16_t x; memcpy(&x, p, 2); return x; }
static uint32_t word32(const void *p) { uint32_t x; memcpy(&x, p, 4); return x; }
static uint64_t word64(const void *p) { uint64_t x; memcpy(&x, p, 8); return x; }
static uintptr_t relative(const unsigned char *p, size_t i) {
    int32_t x; memcpy(&x, p + i * 4, 4);
    return (uintptr_t)p + (intptr_t)x;
}

int main(int argc, char **argv) {
    unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], 0, 10) : 0;
    size_t observations = 0;
#define CHECK(condition) do { ++observations; if (!(condition)) { \
    fprintf(stderr, "global-objects fault=%u observation=%zu\n", fault, observations); return 1; \
} } while (0)
    const unsigned char *escape = global_objects_escape();
    const unsigned char expected[] = {27, '[', 'J', 27, ']', '9', ';', '4', ';', '0', 27, '\\', 0};
    CHECK(word64(escape) == UINT64_C(0x1122334455667788));
    CHECK(word64(escape + 24) == UINT64_C(0x0102030405060708));
    for (size_t i = 0; i < sizeof expected; ++i) {
        unsigned actual = escape[8 + i] ^ (fault == 1 && i == 11 ? 1 : 0);
        CHECK(actual == expected[i]);
    }
    unsigned char *first = global_objects_first(), *second = global_objects_second();
    const unsigned char *poison = global_objects_poison();
    // Poison cells have no defined value. Only the surrounding defined cells
    // are observed; no zero-refinement assumption is imposed on LLVM.
    CHECK(word32(poison) == UINT32_C(0x11223344));
    CHECK(word32(poison + 8) == UINT32_MAX);
    CHECK(word64(poison + 16) == (uintptr_t)first);
    CHECK(word64(poison + 32) == (uintptr_t)second);
    const unsigned char *fp = global_objects_float();
    CHECK(fp[0] == 90);
    CHECK((word32(fp + 4) ^ (fault == 2 ? 1u : 0u)) == UINT32_C(0x7f800001));
    CHECK(word32(fp + 8) == 1);
    CHECK(word64(fp + 16) == UINT64_C(0x8000000000000000));
    CHECK(word64(fp + 24) == 1);
    CHECK(word64(fp + 32) == UINT64_C(0xfff0000000000123));
    CHECK(word64(fp + 48) == UINT64_C(0x0123456789abcdef));
    CHECK(word64(fp + 56) == UINT64_C(0x7fff000000000123));
    CHECK(word64(fp + 64) == (uintptr_t)first);
    CHECK((uintptr_t)fp % 16 == 0);
    const unsigned char *half = global_objects_half();
    CHECK(word16(half) == 0x8000);
    CHECK(word16(half + 2) == 0x7c01);
    CHECK(word16(half + 4) == 1);
    CHECK((uintptr_t)half % 2 == 0);
    const unsigned char *x87 = global_objects_extended();
    CHECK(word64(x87) == UINT64_C(0x8000000000000001));
    CHECK(word16(x87 + 8) == 0x7fff);
    CHECK(word64(x87 + 16) == 0);
    CHECK(word16(x87 + 24) == 0x8000);
    CHECK((uintptr_t)x87 % 16 == 0);
    const unsigned char *table = global_objects_relative();
    CHECK(relative(table, 0) == (uintptr_t)first);
    CHECK(relative(table, 1) == (uintptr_t)second + 4);
    CHECK(relative(table, 2) == (uintptr_t)table + 8);
    CHECK(relative(table, 3) == (uintptr_t)first - 7);
    for (size_t i = 0; i < 64; ++i) {
        CHECK(first[i] == (i == 0 ? 17 : i == 56 ? 238 : 0));
        CHECK(second[i] == (i == 0 ? 34 : i == 56 ? 221 : 0));
    }
    unsigned char *const *leaves = global_objects_many();
    for (size_t i = 0; i < 4097; ++i) {
        CHECK(*leaves[i] == i % 251);
        if (i != 0) CHECK(leaves[i] != leaves[i - 1]);
        *leaves[i] ^= 0x5a;
    }
    if (fault == 3) *leaves[2048] ^= 1;
    for (size_t i = 0; i < 4097; ++i) CHECK(*leaves[i] == ((i % 251) ^ 0x5a));
    printf("global-objects observations=%zu escapes=poison=floats=relative=capacity=neighbors=preserved\n", observations);
    return 0;
}
