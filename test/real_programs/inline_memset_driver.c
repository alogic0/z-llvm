#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

typedef uint64_t (*fill_fn)(void *, uint8_t, uint64_t);
extern uint64_t inline_set_0(void *, uint8_t, uint64_t);
extern uint64_t inline_set_1(void *, uint8_t, uint64_t);
extern uint64_t inline_set_2(void *, uint8_t, uint64_t);
extern uint64_t inline_set_4(void *, uint8_t, uint64_t);
extern uint64_t inline_set_8(void *, uint8_t, uint64_t);
extern uint64_t inline_set_16(void *, uint8_t, uint64_t);
extern uint64_t inline_set_33(void *, uint8_t, uint64_t);
extern uint64_t inline_set_256(void *, uint8_t, uint64_t);
static const struct { fill_fn run; unsigned bytes; } cases[] = {
    {inline_set_0, 0}, {inline_set_1, 1}, {inline_set_2, 2}, {inline_set_4, 4},
    {inline_set_8, 8}, {inline_set_16, 16}, {inline_set_33, 33}, {inline_set_256, 256},
};

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], 0, 10) : 0;
    if (argc > 2 || fault > 3) return 2;
    const size_t page = (size_t)sysconf(_SC_PAGESIZE);
    if (page < 256) return 2;
    uint8_t *mapping = mmap(0, page * 2, PROT_READ | PROT_WRITE,
                           MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED || mprotect(mapping + page, page, PROT_NONE)) return 2;
    unsigned observations = 0;
    for (unsigned which = 0; which != 8; ++which) {
        const unsigned length = cases[which].bytes;
        uint8_t *output = mapping + page - length;
        for (unsigned byte = 0; byte != 256; ++byte) {
            memset(mapping, 0xa7, page);
            const uint64_t keep = UINT64_C(0xfedcba9876543211) * (byte + 1);
            uint64_t result = cases[which].run(output, (uint8_t)byte, keep);
            if (fault == 1) result ^= 1;
            if (fault == 2) output[-1] ^= 1;
            if (fault == 3 && length) output[length - 1] ^= 1;
            int mismatch = result != (keep ^ byte ^ length);
            for (size_t at = 0; at != page; ++at)
                if (mapping[at] != (at < page - length ? 0xa7 : byte)) mismatch = 1;
            if (mismatch) {
                fprintf(stderr, "inline-memset case=%u byte=%u fault=%u observation=%u\n",
                        which, byte, fault, observations);
                return 1;
            }
            ++observations;
        }
    }
    if (munmap(mapping, page * 2)) return 2;
    printf("inline-memset observations=%u independent-c-bytes=live-values=zero-length=guard-pages=preserved\n", observations);
    return 0;
}
