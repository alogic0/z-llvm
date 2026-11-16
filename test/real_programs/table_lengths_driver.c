#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

extern uint32_t length_table_64_value(uint64_t);
extern uint32_t length_table_64_copy(uint64_t, void *);
extern uint32_t length_table_256_value(uint64_t);
extern uint32_t length_table_256_copy(uint64_t, void *);

static int mismatch(unsigned which, unsigned input, unsigned fault) {
    fprintf(stderr, "table-lengths which=%u input=%u fault=%u\n", which, input, fault);
    return 1;
}

int main(int argc, char **argv) {
    unsigned fault = argc == 2 ? (unsigned)strtoul(argv[1], NULL, 10) : 0;
    if (argc > 2 || fault > 6) return 2;
    long page = sysconf(_SC_PAGESIZE);
    if (page < 1024) return 2;
    unsigned char *mapping = mmap(NULL, (size_t)page * 3, PROT_NONE,
                                 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (mapping == MAP_FAILED) return 2;
    unsigned char *area = mapping + page;
    if (mprotect(area, (size_t)page, PROT_READ | PROT_WRITE)) return 2;
    const uint64_t edges[] = {0, 1, 63, 64, 127, 128, 255, UINT64_MAX};
    unsigned observations = 0;
    for (unsigned i = 0; i < 520; ++i) {
        uint64_t index = i < 8 ? edges[i] : UINT64_C(0x9e3779b97f4a7c15) * (i - 8);
        for (unsigned which = 0; which < 4; ++which) {
            unsigned mask = which < 2 ? 63 : 255;
            uint16_t expected = (uint16_t)(((index & mask) * 257 + 0x9e37) & 65535);
            memset(area, 0xa5, (size_t)page);
            void *out = area + page - 2;
            uint32_t actual = which == 0 ? length_table_64_value(index) :
                              which == 1 ? length_table_64_copy(index, out) :
                              which == 2 ? length_table_256_value(index) :
                                           length_table_256_copy(index, out);
            if ((fault == 1 && which == 0) || (fault == 3 && which == 2)) actual ^= 1;
            if (actual != expected) return mismatch(which, i, fault);
            if (which & 1) {
                uint16_t stored;
                memcpy(&stored, out, 2);
                if ((fault == 2 && which == 1) || (fault == 4 && which == 3)) stored ^= 1;
                if (stored != expected) return mismatch(which, i, fault);
                if ((fault == 5 && which == 1) || (fault == 6 && which == 3)) area[0] ^= 1;
                for (long guard = 0; guard < page - 2; ++guard)
                    if (area[guard] != 0xa5) return mismatch(which, i, fault);
            } else {
                for (long guard = 0; guard < page; ++guard)
                    if (area[guard] != 0xa5) return mismatch(which, i, fault);
            }
            ++observations;
        }
    }
    if (munmap(mapping, (size_t)page * 3)) return 2;
    printf("table-lengths observations=%u protected-page-stores=guards=preserved\n", observations);
    return 0;
}
