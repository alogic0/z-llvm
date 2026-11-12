#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern const unsigned char *behavior_vector_nan(void), *behavior_vector_extended(void);
extern const unsigned char *behavior_vector_nested(void), *behavior_vector_pointer(void);
extern void behavior_vector_abs3(const void *, void *), behavior_vector_abs64(const void *, void *);
extern void behavior_vector_stack3(const void *, void *), behavior_vector_phi3(int, const void *, void *);
extern uint64_t behavior_vector_compare3(const void *, const void *);
static uint16_t u16(const void *p) { uint16_t x; memcpy(&x, p, 2); return x; }
static uint32_t u32(const void *p) { uint32_t x; memcpy(&x, p, 4); return x; }
static uint64_t u64(const void *p) { uint64_t x; memcpy(&x, p, 8); return x; }
static long double number(const void *p) { long double x = 0; memcpy(&x, p, 10); return x; }
static const struct { uint64_t lo; uint16_t hi; } values[] = {
    {0,0}, {0,0x8000}, {1,0}, {UINT64_C(0x8000000000000000),0x3fff},
    {UINT64_C(0x8000000000000000),0xbfff}, {UINT64_C(0x8000000000000000),0xffff},
    {UINT64_C(0xc000000000000123),0xffff}, {UINT64_C(0x8000000000000001),0xffff}
};
int main(int argc, char **argv) {
    unsigned fault = argc > 1 ? (unsigned)strtoul(argv[1], 0, 10) : 0;
    size_t observations = 0;
#define CHECK(c) do { ++observations; if (!(c)) { fprintf(stderr,"behavior-vectors fault=%u observation=%zu\n",fault,observations); return 1; } } while (0)
    CHECK((u32(behavior_vector_nan()) ^ (fault == 1 ? 1u : 0u)) == UINT32_C(0x7fc00000));
    const unsigned char *extended = behavior_vector_extended(), *nested = behavior_vector_nested();
    CHECK(behavior_vector_pointer() == extended);
    CHECK((uintptr_t)extended % 32 == 0);
    CHECK(u64(extended) == 1 && u16(extended+8) == 0);
    CHECK(u64(extended+10) == 0 && u16(extended+18) == 0x8000);
    CHECK(u64(extended+20) == UINT64_C(0x8000000000000001) && u16(extended+28) == 0x7fff);
    CHECK(nested[0] == 7 && nested[32] == 9);
    CHECK(u32(nested+16) == UINT32_C(0x3f800000));
    CHECK(u32(nested+20) == UINT32_C(0x80000000));
    CHECK(u32(nested+24) == UINT32_C(0x7f800001));
    for (unsigned seed = 0; seed < 8; ++seed) {
        unsigned char input[640], output[656], right[30];
        for (unsigned i=0; i<64; ++i) {
            unsigned k=(seed+i)%8;
            memcpy(input+10*i, &values[k].lo, 8); memcpy(input+10*i+8, &values[k].hi, 2);
        }
        for (unsigned shape=0; shape<2; ++shape) {
            unsigned lanes = shape ? 64 : 3;
            memset(output,0xa5,sizeof output);
            if (shape) behavior_vector_abs64(input,output+8); else behavior_vector_abs3(input,output+8);
            if (fault == 2) output[8+9] ^= 0x80;
            for (unsigned i=0; i<lanes; ++i) {
                unsigned k=(seed+i)%8;
                CHECK(u64(output+8+10*i)==values[k].lo && u16(output+16+10*i)==(values[k].hi&0x7fff));
            }
            for (unsigned i=0; i<8; ++i) CHECK(output[i]==0xa5);
            for (unsigned i=8+10*lanes; i<sizeof output; ++i) CHECK(output[i]==0xa5);
        }
        memset(output,0xa5,sizeof output); behavior_vector_stack3(input,output+8);
        CHECK(memcmp(output+8,input,30)==0 && output[7]==0xa5 && output[38]==0xa5);
        for (unsigned choice=0; choice<2; ++choice) {
            memset(output,0xa5,sizeof output); behavior_vector_phi3(choice,input,output+8);
            for (unsigned i=0; i<30; ++i) CHECK(output[8+i]==(choice?input[i]:0));
            CHECK(output[7]==0xa5 && output[38]==0xa5);
        }
        for (unsigned shift=0; shift<8; ++shift) {
            uint64_t expected=0;
            for (unsigned i=0; i<3; ++i) {
                unsigned k=(seed+shift+i)%8;
                memcpy(right+10*i,&values[k].lo,8); memcpy(right+10*i+8,&values[k].hi,2);
                expected |= (uint64_t)(number(input+10*i)<=number(right+10*i))<<i;
            }
            uint64_t actual = behavior_vector_compare3(input,right) ^ (fault == 3 ? 1u : 0u);
            CHECK(actual==expected);
        }
    }
    printf("behavior-vectors observations=%zu globals=payloads=packed-x87=phis=masks=guards=preserved\n", observations);
    return 0;
}
