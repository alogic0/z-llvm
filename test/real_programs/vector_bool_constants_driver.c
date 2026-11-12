#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel_t)(const void *, void *, void *);
#define DECLARE(n) extern uint64_t bool_constants_##n(const void *, void *, void *)
DECLARE(2); DECLARE(3); DECLARE(4); DECLARE(7); DECLARE(8); DECLARE(16); DECLARE(32); DECLARE(64);
int main(int argc, char **argv) {
    unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    const unsigned widths[] = {2, 3, 4, 7, 8, 16, 32, 64};
    const kernel_t kernels[] = {bool_constants_2, bool_constants_3, bool_constants_4, bool_constants_7, bool_constants_8, bool_constants_16, bool_constants_32, bool_constants_64};
    size_t page = (size_t)sysconf(_SC_PAGESIZE), observations = 0;
    unsigned char *mapping = mmap(NULL, page * 2, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED || mprotect(mapping + page, page, PROT_NONE)) return 2;
    uint64_t random = UINT64_C(0xf06dea67e461de5b);
    for (unsigned shape = 0; shape < 8; shape++) for (unsigned sample = 0; sample < 128; sample++) {
        unsigned n = widths[shape], bytes = (n + 7) / 8;
        uint64_t mask = n == 64 ? UINT64_MAX : (UINT64_C(1) << n) - 1;
        random ^= random << 13; random ^= random >> 7; random ^= random << 17;
        uint64_t word = sample == 0 ? 0 : sample == 1 ? UINT64_MAX : sample == 2 ? UINT64_C(0xaaaaaaaaaaaaaaaa) : sample == 3 ? UINT64_C(0x5555555555555555) : random;
        word &= mask; // Canonical unused padding bits for the LLVM reference route.
        unsigned char *input = mapping + page - bytes, saved[8];
        memcpy(input, &word, bytes); memcpy(saved, input, bytes);
        unsigned char output[80], packed[24];
        memset(output, 0xa5, sizeof output); memset(packed, 0xa5, sizeof packed);
        uint64_t result = kernels[shape](input, output + 1, packed + 1);
        if (fault == 1) result ^= 1;
        if (fault == 2) output[1] ^= 1;
        if (fault == 3) packed[1 + bytes] ^= 1;
#define CHECK(c) do { ++observations; if (!(c)) { fprintf(stderr, "vector-bool-constants n=%u sample=%u observation=%zu fault=%u\n", n, sample, observations, fault); return 1; } } while (0)
        CHECK(result == ((word & mask) ? 1u : 2u));
        CHECK(memcmp(input, saved, bytes) == 0);
        CHECK(output[0] == 0xa5);
        for (unsigned i = 0; i < n; i++) CHECK(output[1 + i] == ((i % 2 == 0) && ((word >> i) & 1)));
        for (unsigned i = n + 1; i < sizeof output; i++) CHECK(output[i] == 0xa5);
        CHECK(packed[0] == 0xa5);
        uint64_t got = 0; memcpy(&got, packed + 1, bytes);
        CHECK((got & mask) == ((~word) & mask));
        for (unsigned i = bytes + 1; i < sizeof packed; i++) CHECK(packed[i] == 0xa5);
    }
    printf("vector-bool-constants observations=%zu literal-lanes=splats=live-masks=exact-stores=guard-pages=preserved\n", observations);
    return munmap(mapping, page * 2) != 0;
}
