#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern unsigned char *packed_address(void);
extern void *packed_cell(void *, int64_t);
extern void *packed_nested(void *);
extern void *packed_i24(void *);
extern void *packed_fp80(void *);
extern void packed_store(void *, uint64_t);

uint64_t packed_echo(uint64_t v) { return v ^ UINT64_C(0xdeadbeef12345678); }

int main(void) {
    unsigned observations = 0;
    for (unsigned i = 0; i < 128; ++i) {
        unsigned char *p = packed_address();
        unsigned char *payload;
        uint64_t (*function)(uint64_t);
        memcpy(&payload, p + 1, sizeof(payload));
        memcpy(&function, p + 11, sizeof(function));
        const uint64_t value = UINT64_C(0x123456789abcdef0) ^ (UINT64_MAX * i);
        if (((uintptr_t)p & 63) || p[0] != 165 || p[9] != 0x34 || p[10] != 0x12 ||
            memcmp(payload, "load", 5) || function != packed_echo || function(value) != packed_echo(value) ||
            memcmp(p + 19, "\x07\x44\x33\x22\x11\x08\xff\xff\xff\xff", 10) ||
            p[29] != 9 || memcmp(p + 37, "\x08\x07\x06\x05\x04\x03\x02\x01", 8) || p[45] != 90) return 1;
        ++observations;
        unsigned char buffer[256];
        memset(buffer, 0xa5, sizeof(buffer));
        unsigned char *base = buffer + 96 + i % 16;
        int64_t index = (int64_t)(i % 17) - 8;
        if (packed_cell(base, index) != base + index * 5 + 1) return 2;
        ++observations;
        if (packed_nested(base) != base + 9) return 3;
        ++observations;
        if (packed_i24(base) != base + 4) return 4;
        ++observations;
        if (packed_fp80(base) != base + 16) return 5;
        ++observations;
        packed_store(base, value);
        uint64_t observed;
        memcpy(&observed, base + 1, sizeof(observed));
        if (observed != value) return 6;
        for (unsigned j = 0; j < sizeof(buffer); ++j)
            if ((buffer + j < base + 1 || buffer + j >= base + 9) && buffer[j] != 0xa5) return 7;
        ++observations;
    }
    printf("packed-globals observations=%u layout=relocations=strides=mutation=checked\n", observations);
    return 0;
}
