#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x5123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
static void write_bits(uint8_t *p,u128 v,unsigned n){for(unsigned i=0;i<n;++i)p[i]=(uint8_t)(v>>(8*i));}
static u128 read_bits(const uint8_t *p,unsigned n){u128 v=0;for(unsigned i=0;i<n;++i)v|=(u128)p[i]<<(8*i);return v;}
__attribute__((noinline)) uint64_t floating_sign_clobber(uint64_t seed){
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
        :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");return result;
}
/* All expected results are integer bit operations; no FP oracle can quiet or
   canonicalize payloads. The first rows span zeros, subnormals, infinities,
   signaling/quiet NaNs, pseudo-denormals and unsupported extended encodings. */
static u128 input(unsigned width,unsigned row){
    u128 sign=(u128)1<<(width-1),magnitude=sign-1;
    u128 infinity=width==80?((u128)0x7fff<<64)|((u128)1<<63):(u128)0x7fff<<112;
    u128 quiet=(u128)1<<(width==80?62:111);
    switch(row){case 0:return 0;case 1:return sign;case 2:return 1;case 3:return sign|1;
    case 4:return magnitude;case 5:return sign|magnitude;case 6:return infinity;
    case 7:return sign|infinity;case 8:return infinity|1;case 9:return sign|infinity|1;
    case 10:return infinity|quiet|0x123;case 11:return sign|infinity|quiet|0x123;
    case 12:return (u128)1<<63;case 13:return ((u128)1<<64)|((u128)1<<63);
    case 14:return (u128)0x3fff<<64;case 15:return (u128)0x7fff<<64;
    default:return (((u128)random_word()<<64)|random_word())&(sign|magnitude);}
}
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"floating sign mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(uint8_t *left,uint8_t *right,unsigned which,unsigned row){
    const struct sign_case *test=&cases[which];unsigned size=test->width/8;
    u128 a=input(test->width,row),b=input(test->width,row<256?row/16:row+17);
    u128 sign=(u128)1<<(test->width-1),expected;
    switch(test->operation){case 0:expected=a^sign;break;case 1:expected=a&~sign;break;case 2:expected=(a&~sign)|(b&sign);break;default:abort();}
    write_bits(left,a,size);write_bits(right,b,size);uint8_t before_left[16],before_right[16];memcpy(before_left,left,size);memcpy(before_right,right,size);
    uint64_t live=(uint64_t)a^(uint64_t)(b>>64)^row;
    uint8_t out[32];memset(out,0xa7,sizeof out);uint64_t actual=test->function(left,right,out+1,live);
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[1+size]^=1;
    if(actual!=((uint64_t)expected^(live^key))||read_bits(out+1,size)!=expected)return mismatch(which,row,"payload-live");
    if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=1+size;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    if(memcmp(before_left,left,size)||memcmp(before_right,right,size))return mismatch(which,row,"inputs-mutated");
    ++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE)||mprotect(mapping+3*page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which){unsigned size=cases[which].width/8;
        for(unsigned row=0;row<8192;++row)if(check(mapping+page-size,mapping+3*page-size,which,row))return 1;}
    if(observations!=49152)return mismatch(0,0,"count");if(munmap(mapping,(size_t)page*4))return 2;
    puts("floating-signs observations=49152 neg=abs=copysign=payloads=live=guards=preserved");return 0;
}
