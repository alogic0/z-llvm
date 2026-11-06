#include <stdint.h>
#include <stdio.h>
#include <string.h>
extern uint32_t integer_vector_find8(void *, uint8_t, void *);
extern uint32_t integer_vector_find16(void *, uint8_t, void *);
extern uint32_t integer_vector_first16(uint16_t);
extern uint32_t integer_vector_count16(uint16_t);
extern uint64_t integer_vector_arithmetic(void *, void *, void *);
extern void integer_vector_shuffle(void *, void *, void *);
extern uint32_t integer_vector_update(void *, void *, uint32_t, uint8_t);
extern uint32_t integer_vector_build_loop(void *, void *);
__attribute__((noinline)) uint64_t integer_vector_clobber(void *source) {
    memset(source,0x3c,16);
    __asm__ volatile("xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d"
        ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "cc");
    return UINT64_C(0x6a34d1fb823079ce);
}
static uint64_t next(uint64_t *s) { *s ^= *s<<13; *s ^= *s>>7; *s ^= *s<<17; return *s; }
int main(void) {
    unsigned observations=0;
    for (unsigned mask=0; mask<65536; ++mask) {
        unsigned first=15;
        for (unsigned i=0; i<16; ++i) if (mask & (1u<<i)) { first=i; break; }
        uint32_t actual_first=integer_vector_first16(mask), actual_count=integer_vector_count16(mask);
        if (actual_first!=first || actual_count!=(unsigned)__builtin_popcount(mask)) {
            fprintf(stderr,"mask=%u first=%u expected=%u count=%u\n",mask,actual_first,first,actual_count); return 1;
        }
        observations+=2;
    }
    uint64_t state=UINT64_C(0xd58970ca5f1e3b24);
    for (unsigned i=0; i<256; ++i) {
        unsigned char a[48],b[48],out[48],expected[48];
        for (unsigned j=0; j<48; ++j) { a[j]=next(&state); b[j]=next(&state); }
        unsigned offset=1+i%15;
        uint8_t needle=i;
        a[offset+i%16]=needle;
        for (unsigned n=8; n<=16; n+=8) {
            uint16_t mask=0; for(unsigned j=0;j<n;++j) if(a[offset+j]==needle) mask|=1u<<j;
            memset(out,0x5a,sizeof out); memcpy(expected,out,sizeof out);
            expected[offset]=(uint8_t)mask; if(n==16) expected[offset+1]=(uint8_t)(mask>>8);
            uint32_t found=n==8?integer_vector_find8(a+offset,needle,out+offset):integer_vector_find16(a+offset,needle,out+offset);
            if(found!=(mask!=0) || memcmp(out,expected,sizeof out)) { fprintf(stderr,"find width=%u case=%u\n",n,i); return 2; }
            ++observations;
        }
        uint32_t x[4], y[4], values[4], sum=0;
        const unsigned shifts[]={0,1,7,31};
        memcpy(x,a+offset,16); memcpy(y,b+offset,16);
        for(unsigned j=0;j<4;++j) { values[j]=((x[j]+y[j])>>shifts[j])^x[j]; sum+=values[j]; }
        memset(out,0x5a,sizeof out); memcpy(expected,out,sizeof out); memcpy(expected+offset,values,16);
        uint64_t got=integer_vector_arithmetic(a+offset,b+offset,out+offset);
        if(got!=((uint64_t)sum^UINT64_C(0x6a34d1fb823079ce)) || memcmp(out,expected,sizeof out)) return 3;
        ++observations;
        memset(out,0x5a,sizeof out); memcpy(expected,out,sizeof out);
        for(unsigned j=0;j<16;++j) expected[offset+j]=(j&1)?b[offset+j]:a[offset+j];
        integer_vector_shuffle(a+offset,b+offset,out+offset);
        if(memcmp(out,expected,sizeof out)) return 4;
        ++observations;
        memset(out,0x5a,sizeof out); memcpy(expected,out,sizeof out);
        memcpy(expected+offset,a+offset,16); expected[offset+i%16]=(uint8_t)i;
        uint32_t picked=integer_vector_update(a+offset,out+offset,i%16,(uint8_t)i);
        if(picked!=expected[offset+((i%16)^15)] || memcmp(out,expected,sizeof out)) return 5;
        ++observations;
        memset(out,0x5a,sizeof out); memcpy(expected,out,sizeof out); memcpy(expected+offset,b+offset,16);
        uint32_t ends=integer_vector_build_loop(b+offset,out+offset);
        if(ends!=(uint8_t)(b[offset]+b[offset+15]) || memcmp(out,expected,sizeof out)) return 6;
        ++observations;
    }
    printf("integer-vectors observations=%u masks=exhaustive lanes=checked calls=preserved\n",observations);
    return 0;
}
