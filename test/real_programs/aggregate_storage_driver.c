#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { uintptr_t first, second; } Pair;
extern uint64_t aggregate_frame_8(uint64_t, uint64_t, void *);
extern uint64_t aggregate_frame_24(uint64_t, uint64_t, void *);
extern uint64_t aggregate_frame_48(uint64_t, uint64_t, void *);
extern uint64_t aggregate_frame_256(uint64_t, uint64_t, void *);
extern uint64_t aggregate_replace(const Pair *, Pair *, uint64_t);
extern Pair aggregate_return_pi(const Pair *);
extern Pair aggregate_return_ip(const Pair *);
extern Pair aggregate_return_pp(const Pair *);
extern Pair aggregate_return_ii(const Pair *);
extern uint64_t aggregate_call(void *, uint64_t, Pair *, uint64_t);
extern uint64_t aggregate_permutation(uint64_t, uint64_t, uint64_t, uint64_t);
extern uint64_t aggregate_symbol(Pair *);
extern uint64_t aggregate_marker;

static void clobber(void) {
    __asm__ volatile (
        "mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
}

__attribute__((noinline))
uint64_t aggregate_storage_fill(void *slot, uint64_t bytes, uint64_t a, uint64_t b) {
    if ((uintptr_t)slot & 15) abort();
    for (uint64_t offset = 0; offset < bytes; offset += 8) {
        uint64_t value = a + (offset / 8) * b;
        memcpy((char *)slot + offset, &value, 8);
    }
    clobber();
    return a ^ b;
}

__attribute__((noinline))
Pair aggregate_pair_helper(void *pointer, uint64_t length) {
    Pair result = {(uintptr_t)pointer, length + 7};
    clobber();
    return result;
}

__attribute__((noinline))
uint64_t aggregate_permutation_helper(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
    uint64_t result = a + b * 3 + c * 5 + d * 7;
    clobber();
    return result;
}

int main(void) {
    const uint64_t inputs[] = {0, 1, 127, 128, UINT32_MAX, UINT64_MAX,
                              UINT64_C(1) << 63, UINT64_C(0xdeadbeef01234567)};
    uint64_t (*frames[])(uint64_t, uint64_t, void *) = {
        aggregate_frame_8, aggregate_frame_24, aggregate_frame_48, aggregate_frame_256
    };
    Pair (*returns[])(const Pair *) = {
        aggregate_return_pi, aggregate_return_ip, aggregate_return_pp, aggregate_return_ii
    };
    const unsigned lengths[] = {1, 3, 6, 32};
    unsigned observations = 0;
    for (unsigned i = 0; i < 8; ++i) for (unsigned j = 0; j < 8; ++j) {
        const uint64_t a = inputs[i], b = inputs[j];
        for (unsigned f = 0; f < 4; ++f) {
            uint64_t output[34], expected[34];
            memset(output, 0xa5, sizeof(output));
            memset(expected, 0xa5, sizeof(expected));
            for (unsigned k = 0; k < lengths[f]; ++k) expected[k + 1] = a + k * b;
            const uint64_t result = frames[f](a, b, output + 1);
            const uint64_t answer = (a ^ (a + (lengths[f] - 1) * b)) + UINT64_MAX + (a ^ b);
            if (result != answer || memcmp(output, expected, sizeof(output))) {
                fprintf(stderr, "aggregate frame mismatch f=%u i=%u j=%u\n", f, i, j);
                return 1;
            }
            ++observations;
        }
        const Pair source = {a, b};
        for (unsigned f = 0; f < 4; ++f) {
            const Pair result = returns[f](&source);
            if (memcmp(&result, &source, sizeof(source))) {
                fprintf(stderr, "aggregate return mismatch f=%u i=%u j=%u\n", f, i, j);
                return 1;
            }
            ++observations;
        }
        struct { uint64_t before; Pair pair; uint64_t after; } guarded;
        memset(&guarded, 0xa5, sizeof(guarded));
        const uint64_t guard = UINT64_C(0xa5a5a5a5a5a5a5a5);
        if (aggregate_replace(&source, &guarded.pair, a) != b ||
            guarded.pair.first != a || guarded.pair.second != b + a ||
            guarded.before != guard || guarded.after != guard || source.first != a || source.second != b) {
            fprintf(stderr, "aggregate replace mismatch i=%u j=%u\n", i, j);
            return 1;
        }
        ++observations;
        if (aggregate_call((void *)(uintptr_t)a, b, &guarded.pair, a) != ((b + 7) ^ a) ||
            guarded.pair.first != a || guarded.pair.second != b + 7 ||
            guarded.before != guard || guarded.after != guard) {
            fprintf(stderr, "aggregate call mismatch i=%u j=%u\n", i, j);
            return 1;
        }
        ++observations;
        if (aggregate_permutation(a, b, ~a, ~b) != ~b + (~a) * 3 + a * 5 + b * 7) {
            fprintf(stderr, "aggregate argument permutation mismatch i=%u j=%u\n", i, j);
            return 1;
        }
        ++observations;
        if (aggregate_symbol(&guarded.pair) != 55 || guarded.pair.first != (uintptr_t)&aggregate_marker ||
            guarded.pair.second != 55 || guarded.before != guard || guarded.after != guard) {
            fprintf(stderr, "aggregate symbol mismatch i=%u j=%u\n", i, j);
            return 1;
        }
        ++observations;
    }
    printf("aggregate-storage observations=%u layouts=padding=pairs=calls=permutations=alignment=live=guards=preserved\n", observations);
    return 0;
}
