#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#define DECLARE(n) extern uint64_t limb_multiply_##n(uint8_t *, uint8_t *, const uint8_t *, const uint8_t *, uint64_t)
DECLARE(140); DECLARE(200); DECLARE(256); DECLARE(495);
static unsigned bit(const uint8_t *p, unsigned n) { return (p[n / 8] >> (n % 8)) & 1; }
static void put(uint8_t *p, unsigned n) { p[n / 8] |= (uint8_t)(1u << (n % 8)); }
static void product(uint8_t *out, const uint8_t *x, const uint8_t *y, unsigned n) {
    memset(out, 0, 128);
    // Independent base-256 arithmetic, retaining exactly n result bytes.
    for (unsigned i = 0; i < n; i++) {
        unsigned carry = 0;
        for (unsigned j = 0; i + j < n; j++) {
            unsigned sum = (unsigned)x[i] * y[j] + out[i + j] + carry;
            out[i + j] = (uint8_t)sum;
            carry = sum >> 8;
        }
    }
}
static void special(uint8_t *out, unsigned bits, unsigned seed) {
    memset(out, 0, 64);
    if (seed == 1) out[0] = 1;
    if (seed == 2) memset(out, 255, (bits + 7) / 8);
    if (seed == 3 || seed == 5) put(out, bits - 1);
    if (seed == 4) for (unsigned i = 0; i + 1 < bits; i++) put(out, i);
    if (seed == 5) out[0] |= 1;
    if (seed == 6) memset(out, 255, 8);
    if (seed == 7) put(out, bits / 2);
}
int main(int argc, char **argv) {
    unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    const unsigned widths[] = {140, 200, 256, 495};
    uint64_t (*kernels[])(uint8_t *, uint8_t *, const uint8_t *, const uint8_t *, uint64_t) = {limb_multiply_140, limb_multiply_200, limb_multiply_256, limb_multiply_495};
    size_t page = (size_t)sysconf(_SC_PAGESIZE), observations = 0;
    uint8_t *mapping = mmap(NULL, page * 4, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED || mprotect(mapping + page, page, PROT_NONE) || mprotect(mapping + 3 * page, page, PROT_NONE)) return 2;
    uint64_t random = UINT64_C(0xf06dea67e461de5b);
    for (unsigned w = 0; w < 4; w++) for (unsigned seed = 0; seed < 128; seed++) {
        unsigned bits = widths[w], bytes = (bits + 7) / 8, full_bytes = (2 * bits + 7) / 8;
        uint8_t x[128] = {0}, y[128] = {0};
        if (seed < 64) { special(x, bits, seed / 8); special(y, bits, seed % 8); }
        else for (unsigned i = 0; i < bytes; i++) {
            random ^= random << 13; random ^= random >> 7; random ^= random << 17;
            x[i] = (uint8_t)random; y[i] = (uint8_t)(random >> 32);
        }
        if (seed >= 96) { memset(y, 0, sizeof y); y[0] = (uint8_t)(1 + seed % 7); }
        if (bits % 8) { x[bytes - 1] &= (1u << (bits % 8)) - 1; y[bytes - 1] &= (1u << (bits % 8)) - 1; }
        uint8_t unsigned_product[128], signed_product[128], extended_x[128], extended_y[128];
        product(unsigned_product, x, y, full_bytes);
        memcpy(extended_x, x, 128); memcpy(extended_y, y, 128);
        for (unsigned i = bits; i < 2 * bits; i++) {
            if (bit(x, bits - 1)) put(extended_x, i);
            if (bit(y, bits - 1)) put(extended_y, i);
        }
        product(signed_product, extended_x, extended_y, full_bytes);
        unsigned flags_expected[2] = {0, 0}, sign = bit(signed_product, bits - 1);
        for (unsigned i = bits; i < 2 * bits; i++) { flags_expected[0] |= bit(unsigned_product, i); flags_expected[1] |= bit(signed_product, i) != sign; }
        uint8_t *xp = mapping + page - bytes, *yp = mapping + 3 * page - bytes;
        memcpy(xp, x, bytes); memcpy(yp, y, bytes);
        struct { uint8_t pre[9], data[3][64], post[9]; } out;
        struct { uint8_t pre[3], data[2], post[3]; } flags;
        memset(&out, 0xa5, sizeof out); memset(&flags, 0xa5, sizeof flags);
        uint64_t salt = seed * UINT64_C(0x9e3779b97f4a7c15) + w;
        uint64_t returned = kernels[w](&out.data[0][0], flags.data, xp, yp, salt);
        if (fault == 1) out.data[0][0] ^= 1;
        if (fault == 2) flags.data[0] ^= 1;
        if (fault == 3) out.post[0] ^= 1;
#define CHECK(c) do { ++observations; if (!(c)) { fprintf(stderr, "limb-multiply bits=%u seed=%u observation=%zu fault=%u\n", bits, seed, observations, fault); return 1; } } while (0)
        CHECK(returned == (salt ^ 90));
        for (unsigned op = 0; op < 3; op++) for (unsigned i = 0; i < 64; i++) {
            unsigned mask = i + 1 == bytes && bits % 8 ? (1u << (bits % 8)) - 1 : 255;
            CHECK((out.data[op][i] & mask) == ((i < bytes ? unsigned_product[i] : 0xa5) & mask));
        }
        CHECK(flags.data[0] == flags_expected[0]); CHECK(flags.data[1] == flags_expected[1]);
        unsigned prefix = 1, suffix = 1, flag_prefix = 1, flag_suffix = 1;
        for (unsigned i = 0; i < 9; i++) { prefix &= out.pre[i] == 0xa5; suffix &= out.post[i] == 0xa5; }
        for (unsigned i = 0; i < 3; i++) { flag_prefix &= flags.pre[i] == 0xa5; flag_suffix &= flags.post[i] == 0xa5; }
        CHECK(prefix); CHECK(suffix); CHECK(flag_prefix); CHECK(flag_suffix);
        CHECK(memcmp(xp, x, bytes) == 0); CHECK(memcmp(yp, y, bytes) == 0);
    }
    printf("limb-multiply observations=%zu modular-products=signed-unsigned-flags=base256-oracle=guard-pages=live-values=preserved\n", observations);
    return munmap(mapping, page * 4) != 0;
}
