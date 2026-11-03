#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern void *global_copy_destination(void);
extern void *global_copy_source(void);
extern uint64_t global_copy2(void *, uint64_t);
extern uint64_t global_copy12(void *, uint64_t);
extern uint64_t global_copy16(void *, uint64_t);
extern uint64_t global_copy80(uint64_t);
extern uint64_t global_store_scalars(uint32_t, uint64_t);

static int bytes_match(const unsigned char *bytes, unsigned begin, const void *expected, unsigned count) {
    for (unsigned index = 0; index < 128; ++index) {
        unsigned char byte = index >= begin && index < begin + count ? ((const unsigned char *)expected)[index - begin] : 165;
        if (bytes[index] != byte) return 0;
    }
    return 1;
}

int main(void) {
    const uint64_t values[] = {0, 1, 127, 128, UINT32_MAX, UINT64_C(1) << 63,
                               UINT64_MAX, UINT64_C(0xdeadbeef01234567)};
    unsigned char input[128], output[128];
    unsigned char *destination = global_copy_destination();
    const unsigned char *source = global_copy_source();
    if (((uintptr_t)destination & 63) || ((uintptr_t)source & 15)) return 1;
    for (unsigned index = 0; index < 128; ++index) if (source[index] != "0123456789ABCDEF"[index % 16]) return 2;
    unsigned observations = 0;
    for (unsigned value = 0; value < 8; ++value) {
        for (unsigned byte = 0; byte < 128; ++byte) input[byte] = (unsigned char)(byte * 37 + value * 11);
        memset(output, 165, 128);
        if (global_copy2(output + 3, values[value]) != values[value] || !bytes_match(output, 3, source + 5, 2)) return 3;
        ++observations;
        memset(destination, 165, 128);
        if (global_copy12(input + 7, values[value]) != values[value] || !bytes_match(destination, 17, input + 7, 12)) return 4;
        ++observations;
        struct { void *pointer; uint64_t length; } pair = {input + value, values[value]};
        memset(destination, 165, 128);
        if (global_copy16(pair.pointer, pair.length) != pair.length || !bytes_match(destination, 32, &pair, 16)) return 5;
        ++observations;
        memset(destination, 165, 128);
        if (global_copy80(values[value]) != (values[value] ^ UINT64_C(123456789)) || !bytes_match(destination, 48, source + 7, 80)) return 6;
        ++observations;
        unsigned char expected[128];
        memset(expected, 165, 128);
        expected[5] = expected[6] = 255;
        expected[17] = (unsigned char)values[value];
        uint32_t low = (uint32_t)values[value];
        memcpy(expected + 32, &low, 4);
        memset(destination, 165, 128);
        if (global_store_scalars(low, values[value]) != values[value] || memcmp(destination, expected, 128)) return 8;
        ++observations;
        for (unsigned index = 0; index < 128; ++index) if (source[index] != "0123456789ABCDEF"[index % 16]) return 7;
    }
    printf("global-memory observations=%u lengths=2,12,16,80 stores=8,16,32 pointers=live=guards=preserved\n", observations);
    return 0;
}
