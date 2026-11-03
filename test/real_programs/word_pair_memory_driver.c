#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern uint64_t word_pair_copy(void *, uint64_t, void *);
extern uint64_t word_pair_extract(void *, uint64_t);

int main(void) {
    unsigned char bytes[64] = {0};
    void *pointers[] = {0, bytes, bytes + 1, bytes + 63};
    uint64_t lengths[] = {0, 1, 127, 128, UINT32_MAX, UINT64_MAX,
                          UINT64_C(1) << 63, UINT64_C(0xdeadbeef01234567)};
    unsigned observations = 0;
    for (unsigned p = 0; p < 4; ++p) {
        for (unsigned n = 0; n < 8; ++n) {
            struct {
                uint64_t before;
                struct { void *pointer; uint64_t length; } pair;
                uint64_t after;
            } output;
            memset(&output, 0xa5, sizeof(output));
            uint64_t result = word_pair_copy(pointers[p], lengths[n], &output.pair);
            if (result != lengths[n] || output.pair.pointer != pointers[p] ||
                output.pair.length != lengths[n] ||
                output.before != UINT64_C(0xa5a5a5a5a5a5a5a5) ||
                output.after != UINT64_C(0xa5a5a5a5a5a5a5a5)) {
                fprintf(stderr, "word-pair copy mismatch pointer=%u length=%u\n", p, n);
                return 1;
            }
            ++observations;
            if (word_pair_extract(pointers[p], lengths[n]) !=
                ((uint64_t)(uintptr_t)pointers[p] ^ lengths[n])) {
                fprintf(stderr, "word-pair extract mismatch pointer=%u length=%u\n", p, n);
                return 1;
            }
            ++observations;
        }
    }
    printf("word-pair-memory observations=%u copy=independent pointers=preserved guards=preserved\n", observations);
    return 0;
}
