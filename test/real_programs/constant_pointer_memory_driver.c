#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern unsigned char *constant_pointer_output(void);
extern uint64_t constant_pointer_copy3(void *, uint64_t);
extern uint64_t constant_pointer_copy7(const void *, uint64_t);
extern uint64_t constant_pointer_alias(void *, uint64_t);
extern uint64_t constant_pointer_negative(void *, uint64_t);
extern uint64_t constant_pointer_dynamic(uint64_t, uint64_t, uint64_t, void *, uint64_t);
extern uint64_t constant_pointer_both(uint64_t);

// The imported symbol names an interior byte, allowing a defined negative
// constant offset without relying on the frontend's aggregate-alias parser.
const unsigned char external_input[128] = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF";
__asm__(".globl constant_middle\n.set constant_middle, external_input+32");

static unsigned char source(unsigned index) { return "0123456789ABCDEF"[index % 16]; }
static int check(const unsigned char *bytes, size_t size, size_t start, unsigned offset, unsigned count) {
    for (size_t i = 0; i < size; ++i)
        if (bytes[i] != (i >= start && i < start + count ? source(offset + i - start) : 165)) return 0;
    return 1;
}

int main(void) {
    const uint64_t values[] = {0, 1, 127, 128, UINT32_MAX, UINT64_C(1) << 63,
                              UINT64_MAX, UINT64_C(0xdeadbeef01234567)};
    const unsigned lengths[] = {0, 1, 2, 3, 7, 31, 64};
    long page = sysconf(_SC_PAGESIZE);
    if (page < 128) return 1;
    unsigned char *guard = mmap(NULL, (size_t)page * 2, PROT_READ | PROT_WRITE,
                                MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (guard == MAP_FAILED || mprotect(guard + page, (size_t)page, PROT_NONE)) return 2;
    unsigned char output[128], input[128];
    unsigned char *global = constant_pointer_output();
    if ((uintptr_t)global & 63) return 3;
    unsigned observations = 0;
    for (unsigned n = 0; n < 8; ++n) {
        uint64_t live = values[n];
        for (unsigned i = 0; i < 128; ++i) input[i] = source(i);
        memset(output, 165, sizeof output);
        if (constant_pointer_copy3(output + 5, live) != live || !check(output, 128, 5, 9, 3)) return 4;
        ++observations;
        memset(global, 165, 128);
        if (constant_pointer_copy7(input + 4, live) != live || !check(global, 128, 11, 4, 7)) return 5;
        ++observations;
        memset(output, 165, sizeof output);
        if (constant_pointer_alias(output + 9, live) != (live ^ UINT64_C(123456789)) || !check(output, 128, 9, 17, 31)) return 6;
        ++observations;
        memset(output, 165, sizeof output);
        if (constant_pointer_negative(output + 15, live) != live || !check(output, 128, 15, 25, 1)) return 7;
        ++observations;
        memset(global, 165, 128);
        if (constant_pointer_both(live) != live || !check(global, 128, 1, 3, 64)) return 8;
        ++observations;
        for (unsigned l = 0; l < sizeof lengths / sizeof lengths[0]; ++l) {
            unsigned count = lengths[l];
            memset(guard, 165, (size_t)page);
            uint64_t a = live + 17, b = live * 37;
            if (constant_pointer_dynamic(a, count, b, guard + page - count, live) != (a ^ b ^ live) ||
                !check(guard, (size_t)page, (size_t)page - count, 23, count)) return 9;
            ++observations;
        }
    }
    if (munmap(guard, (size_t)page * 2)) return 10;
    printf("constant-pointer-memory observations=%u flags=aliases=negative=dynamic=live=guards=preserved\n", observations);
    return 0;
}
