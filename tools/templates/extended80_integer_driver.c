#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void) {
    static uint64_t state=UINT64_C(0x123456789abcdef0);
    state^=state<<13;state^=state>>7;state^=state<<17;return state;
}
static u128 mask(unsigned width) {return width==128?~(u128)0:((u128)1<<width)-1;}
static u128 read_bits(const uint8_t *bytes,unsigned count) {
    u128 value=0;for(unsigned i=0;i<count;++i)value|=(u128)bytes[i]<<(8*i);return value;
}
static void write_bits(uint8_t *bytes,u128 value,unsigned count) {
    for(unsigned i=0;i<count;++i)bytes[i]=(uint8_t)(value>>(8*i));
}
__attribute__((noinline)) uint64_t extended80_integer_clobber(uint64_t seed) {
    uint64_t result=seed^key;
    __asm__ volatile(
        "xor %%eax,%%eax\n\txor %%ecx,%%ecx\n\txor %%edx,%%edx\n\t"
        "xor %%edi,%%edi\n\txor %%esi,%%esi\n\txor %%r8d,%%r8d\n\t"
        "xor %%r9d,%%r9d\n\txor %%r10d,%%r10d\n\txor %%r11d,%%r11d\n\t"
        "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\tpxor %%xmm2,%%xmm2\n\t"
        "pxor %%xmm3,%%xmm3\n\tpxor %%xmm4,%%xmm4\n\tpxor %%xmm5,%%xmm5\n\t"
        "pxor %%xmm6,%%xmm6\n\tpxor %%xmm7,%%xmm7\n\tpxor %%xmm8,%%xmm8\n\t"
        "pxor %%xmm9,%%xmm9\n\tpxor %%xmm10,%%xmm10\n\tpxor %%xmm11,%%xmm11\n\t"
        "pxor %%xmm12,%%xmm12\n\tpxor %%xmm13,%%xmm13\n\tpxor %%xmm14,%%xmm14\n\tpxor %%xmm15,%%xmm15"
        :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11",
        "xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7",
        "xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");
    return result;
}

/* Round a nonnegative integer magnitude once to a64bit significand. */
static u128 integer_float(u128 raw,unsigned width,unsigned sign) {
    u128 bits=raw&mask(width);
    unsigned negative=sign&&(unsigned)((bits>>(width-1))&1);
    u128 magnitude=negative?((~bits+1)&mask(width)):bits;
    if(!magnitude)return 0;
    unsigned top=0;for(u128 scan=magnitude;scan>>=1;)++top;
    unsigned exponent=16383+top;
    u128 significand;
    if(top<=63)significand=magnitude<<(63-top);
    else {
        unsigned shift=top-63;
        significand=magnitude>>shift;
        u128 remainder=magnitude&mask(shift),halfway=(u128)1<<(shift-1);
        if(remainder>halfway||(remainder==halfway&&(significand&1)))++significand;
        if(significand==((u128)1<<64)){significand>>=1;++exponent;}
    }
    return ((u128)(exponent|(negative<<15))<<64)|significand;
}

/* Only execute source casts whose truncated mathematical integer fits. */
static int float_integer(u128 raw,unsigned width,unsigned sign,u128 *answer) {
    unsigned se=(unsigned)(raw>>64),negative=(se>>15)&1,exponent=se&0x7fff;
    uint64_t significand=(uint64_t)raw;
    if(exponent==0x7fff)return 0;
    int top=(exponent?(int)exponent:1)-16383;
    if(top>127)return 0;
    u128 magnitude=top<0?0:top>=63?(u128)significand<<(top-63):significand>>(63-top);
    if(sign) {
        u128 limit=(u128)1<<(width-1);
        if(negative?magnitude>limit:magnitude>=limit)return 0;
    } else {
        if(negative&&magnitude)return 0;
        if(width<128&&magnitude>mask(width))return 0;
    }
    *answer=negative?-magnitude:magnitude;
    return 1;
}

static u128 input_float(unsigned width,unsigned sign,unsigned row,u128 *answer) {
    for(unsigned attempt=0;;++attempt) {
        u128 raw;
        if(!attempt&&row<4)raw=row==0?0:row==1?(u128)0x8000<<64:row==2?1:((u128)0x8000<<64)|1;
        else {
            int top=(int)(random_word()%(width+67))-65;
            unsigned negative=sign&&(unsigned)(random_word()&1);
            uint64_t significand=random_word()|UINT64_C(0x8000000000000000);
            if(!attempt&&row>=4&&row<12) {
                top=(int)width-(int)(row-3);
                significand=row&1?UINT64_MAX:UINT64_C(0x8000000000000000);
            }
            raw=((u128)((unsigned)(16383+top)|(negative<<15))<<64)|significand;
        }
        if(float_integer(raw,width,sign,answer))return raw;
    }
}

static int mismatch(unsigned which,unsigned row,const char *stage) {
    fprintf(stderr,"extended80 integer mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);
    return 1;
}

static int check_to(unsigned which,unsigned row) {
    const struct to_case *test=&to_cases[which];
    u128 raw=((u128)random_word()<<64)|random_word();
    if(row<128)raw=(u128)1<<row;
    else if(row<256)raw=~((u128)1<<(row-128));
    else if(row==256)raw=0;
    else if(row==257)raw=~(u128)0;
    u128 expected=integer_float(test->constant?test->raw:raw,test->width,test->sign);
    uint64_t live=(uint64_t)raw^(uint64_t)(raw>>64)^row;
    uint8_t guarded[24];memset(guarded,0xa7,sizeof guarded);
    u128 actual=test->function(raw,guarded+1,live);
    if(fault==1)actual^=1;
    if(fault==2)guarded[1]^=1;
    if(fault==3)guarded[11]^=1;
    if(actual!=(raw^(live^key)))return mismatch(which,row,"to-live");
    if(read_bits(guarded+1,10)!=expected)return mismatch(which,row,"to-rounding");
    if(guarded[0]!=0xa7)return mismatch(which,row,"to-prefix");
    for(unsigned i=11;i<sizeof guarded;++i)if(guarded[i]!=0xa7)return mismatch(which,row,"to-suffix");
    ++observations;return 0;
}

static int check_from(uint8_t *input,unsigned which,unsigned row) {
    const struct from_case *test=&from_cases[which];
    u128 expected,raw=input_float(test->width,test->sign,row,&expected);
    write_bits(input,raw,10);
    uint8_t original[10];memcpy(original,input,10);
    uint64_t live=(uint64_t)raw^(uint64_t)(raw>>64)^row;
    uint8_t guarded[24];memset(guarded,0xa7,sizeof guarded);
    u128 actual=test->function(input,guarded+1,live);
    if(fault==1)actual^=1;
    if(fault==2)guarded[1]^=1;
    if(fault==3)guarded[17]^=1;
    if(actual!=(expected^(live^key)))return mismatch(24+which,row,"from-live");
    if(read_bits(guarded+1,16)!=expected)return mismatch(24+which,row,"from-truncation");
    if(guarded[0]!=0xa7)return mismatch(24+which,row,"from-prefix");
    for(unsigned i=17;i<sizeof guarded;++i)if(guarded[i]!=0xa7)return mismatch(24+which,row,"from-suffix");
    if(memcmp(input,original,10))return mismatch(24+which,row,"from-input-mutated");
    ++observations;return 0;
}

int main(int argc,char **argv) {
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);
    if(argc>2||fault>3)return 2;
    long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof to_cases/sizeof to_cases[0];++which)
        for(unsigned row=0;row<4096;++row)if(check_to(which,row))return 1;
    for(unsigned which=0;which<sizeof from_cases/sizeof from_cases[0];++which)
        for(unsigned row=0;row<4096;++row)if(check_from(mapping+page-10,which,row))return 1;
    if(observations!=180224)return mismatch(0,0,"count");
    if(munmap(mapping,(size_t)page*2))return 2;
    puts("extended80-integer observations=180224 rounding=truncation=widths=literal=live=guards=preserved");
    return 0;
}
