#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern void vector_cast_narrow(void *, void *, void *);
extern void vector_cast_widen(void *, void *, void *);
extern void vector_cast_phi(void *, void *, uint64_t);
extern void vector_cast_pressure(void *, double, double, double, double, double, double, double, double);
extern float vector_cast_partial(double);

__attribute__((noinline)) void vector_cast_clobber(void) {
    __asm__ volatile("pxor %%xmm0, %%xmm0\n\tpxor %%xmm1, %%xmm1\n\t"
                     "pxor %%xmm2, %%xmm2\n\tpxor %%xmm3, %%xmm3\n\t"
                     "pxor %%xmm4, %%xmm4\n\tpxor %%xmm5, %%xmm5\n\t"
                     "pxor %%xmm6, %%xmm6\n\tpxor %%xmm7, %%xmm7"
                     : : : "xmm0", "xmm1", "xmm2", "xmm3", "xmm4", "xmm5", "xmm6", "xmm7");
}

static uint32_t bits32(float value) { uint32_t bits; memcpy(&bits, &value, 4); return bits; }
static uint64_t bits64(double value) { uint64_t bits; memcpy(&bits, &value, 8); return bits; }
static int same32(float a, float b) {
    uint32_t x = bits32(a), y = bits32(b);
    return x == y || ((x & 0x7fffffffU) > 0x7f800000U && (y & 0x7fffffffU) > 0x7f800000U);
}
static int same64(double a, double b) {
    uint64_t x = bits64(a), y = bits64(b);
    return x == y || ((x & UINT64_C(0x7fffffffffffffff)) > UINT64_C(0x7ff0000000000000) &&
                     (y & UINT64_C(0x7fffffffffffffff)) > UINT64_C(0x7ff0000000000000));
}
static int guards(const unsigned char *bytes, unsigned offset, unsigned size, unsigned total) {
    for (unsigned i = 0; i < total; ++i)
        if ((i < offset || i >= offset + size) && bytes[i] != 0xa5) return 0;
    return 1;
}

int main(void) {
    const uint64_t double_cases[] = {
        0, UINT64_C(0x8000000000000000), UINT64_C(0x3ff0000000000000),
        UINT64_C(0x3ff0000010000000), UINT64_C(0x3ff0000020000000), UINT64_C(0x3ff0000030000000),
        UINT64_C(0x3690000000000000), UINT64_C(0x36a0000000000000), UINT64_C(0x36b0000000000000),
        UINT64_C(0x47efffffe0000000), UINT64_C(0x47f0000000000000), UINT64_C(0xc7f0000000000000),
        UINT64_C(0x7ff0000000000000), UINT64_C(0xfff0000000000000), UINT64_C(0x7ff8123456789abc),
        UINT64_C(0x7ff0000000000001), UINT64_C(0xfff8123456789abc), UINT64_C(0x0000000000000001)
    };
    const uint32_t float_cases[] = {0, 0x80000000U, 0x3f800000U, 0xbf800001U, 1, 0x007fffffU,
        0x00800000U, 0x7f7fffffU, 0x7f800000U, 0xff800000U, 0x7fc12345U, 0x7f800001U};
    unsigned observations = 0;
    for (unsigned iteration = 0; iteration < 256; ++iteration) {
        double values[8], result64[2];
        float inputs32[2], result32[2], expected32[2];
        for (unsigned lane = 0; lane < 8; ++lane) {
            uint64_t bits = double_cases[(iteration + lane * 7) % (sizeof(double_cases) / 8)];
            if (iteration >= 128) {
                bits = UINT64_C(0x3fd0000000000000) ^ ((UINT64_C(0x9e3779b97f4a7c15) * (iteration + lane)) & UINT64_C(0x803fffffffffffff));
            }
            memcpy(&values[lane], &bits, 8);
        }
        for (unsigned lane = 0; lane < 2; ++lane) {
            uint32_t bits = float_cases[(iteration + lane * 5) % (sizeof(float_cases) / 4)];
            memcpy(&inputs32[lane], &bits, 4);
            volatile double original = values[lane];
            expected32[lane] = (float)original;
        }
        unsigned char input[48], out[160], kept[48];
        const unsigned offset = 1 + iteration % 7;
        memset(input, 0xa5, sizeof(input));
        memcpy(input + offset, values, 16);
        memset(out, 0xa5, sizeof(out));
        memset(kept, 0xa5, sizeof(kept));
        vector_cast_narrow(input + offset, out + offset, kept + offset);
        memcpy(result32, out + offset, 8);
        if (!same32(result32[0], expected32[0]) || !same32(result32[1], expected32[1]) ||
            memcmp(kept + offset, values, 16) || memcmp(input + offset, values, 16) ||
            !guards(out, offset, 8, sizeof(out)) || !guards(kept, offset, 16, sizeof(kept))) return 1;
        ++observations;

        memcpy(input + offset, inputs32, 8);
        memset(out, 0xa5, sizeof(out));
        memset(kept, 0xa5, sizeof(kept));
        vector_cast_widen(input + offset, out + offset, kept + offset);
        memcpy(result64, out + offset, 16);
        if (!same64(result64[0], (double)inputs32[0]) || !same64(result64[1], (double)inputs32[1]) ||
            memcmp(kept + offset, inputs32, 8) || !guards(out, offset, 16, sizeof(out)) ||
            !guards(kept, offset, 8, sizeof(kept))) return 2;
        ++observations;

        memcpy(input + offset, values, 16);
        memset(out, 0xa5, sizeof(out));
        vector_cast_phi(input + offset, out + offset, iteration % 2);
        memcpy(result64, out + offset, 16);
        if (!same64(result64[0], (double)expected32[iteration % 2]) ||
            !same64(result64[1], (double)expected32[1 - iteration % 2]) ||
            !guards(out, offset, 16, sizeof(out))) return 3;
        ++observations;

        memset(out, 0xa5, sizeof(out));
        vector_cast_pressure(out + offset, values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7]);
        if (memcmp(out + offset, values, 64) || !guards(out, offset, 128, sizeof(out))) return 4;
        for (unsigned lane = 0; lane < 8; ++lane) {
            double observed;
            memcpy(&observed, out + offset + 64 + lane * 8, 8);
            volatile double original = values[lane];
            if (!same64(observed, (double)(float)original)) return 5;
        }
        ++observations;
        if (!same32(vector_cast_partial(values[0]), expected32[0])) return 6;
        ++observations;
    }
    printf("vector-fp-casts observations=%u rounding=special-values=checked aliases=phi=calls=preserved memory=guarded\n", observations);
    return 0;
}
