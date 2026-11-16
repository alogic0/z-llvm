#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern uint32_t original_optional(const uint32_t *) __asm__("runtime_optional_pointer_main.optionalPtrValue");
extern uint32_t optional_phi_adjust(const uint32_t *);
extern uint32_t renamed_optional_read(const uint32_t *, uint32_t, uint32_t);
extern uint32_t optional_live_pressure(const uint32_t *, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

static int mismatch(unsigned which, unsigned input, unsigned fault) {
    fprintf(stderr, "optional-composition which=%u input=%u fault=%u\n", which, input, fault);
    return 1;
}

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 8) return 2;
    long page = sysconf(_SC_PAGESIZE);
    if (page < 1024) return 2;
    unsigned char *mapping = mmap(NULL, (size_t)page * 3, PROT_NONE,
                                 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED) return 2;
    unsigned char *area = mapping + page;
    if (mprotect(area, (size_t)page, PROT_READ | PROT_WRITE)) return 2;
    const uint32_t edges[] = {0, 1, 7, 8, UINT32_MAX, UINT32_C(0x80000000), UINT32_C(0x7fffffff), UINT32_C(0xa55a1234)};
    uint32_t seed = UINT32_C(0x719f3a25);
    unsigned observations = 0;
    for (unsigned i = 0; i < 264; ++i) {
        seed = seed * UINT32_C(1664525) + UINT32_C(1013904223);
        uint32_t word = i < 8 ? edges[i] : seed;
        uint32_t a = seed ^ UINT32_C(0xb718225e), b = ~seed;
        uint32_t c = seed + 173, d = seed * 5, e = seed ^ (seed >> 9);
        uint32_t *stored = (uint32_t *)(void *)(area + page - 4);
        const uint32_t *payload = i & 1 ? stored : NULL;
        for (unsigned which = 0; which < 4; ++which) {
            memset(area, 0xa5, (size_t)page);
            memcpy(stored, &word, 4);
            uint32_t expected = payload ? word : UINT32_MAX;
            if (which == 1 && payload) expected += 8;
            if (which == 2) expected = (payload ? word + a + 17 : UINT32_MAX) ^ (a ^ b);
            if (which == 3) {
                expected += a + 11; expected ^= b + 13;
                expected += c ^ UINT32_C(22136); expected ^= d + 17;
                expected += e ^ UINT32_C(39612); expected ^= a * 7;
                expected += b ^ d; expected ^= c + e;
            }
            uint32_t actual = which == 0 ? original_optional(payload) :
                              which == 1 ? optional_phi_adjust(payload) :
                              which == 2 ? renamed_optional_read(payload, a, b) :
                                           optional_live_pressure(payload, a, b, c, d, e);
            if (fault == which + 1) actual ^= 1;
            if (actual != expected) return mismatch(which, i, fault);
            if (fault == which + 5) area[0] ^= 1;
            uint32_t after;
            memcpy(&after, stored, 4);
            if (after != word) return mismatch(which, i, fault);
            for (long guard = 0; guard < page - 4; ++guard)
                if (area[guard] != 0xa5) return mismatch(which, i, fault);
            ++observations;
        }
    }
    if (munmap(mapping, (size_t)page * 3)) return 2;
    printf("optional-composition observations=%u renamed=cfg-variants=pressure=guards=preserved\n", observations);
    return 0;
}
