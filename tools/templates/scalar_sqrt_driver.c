#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>
_Static_assert(sizeof(long double)==16&&LDBL_MANT_DIG==64&&LDBL_MAX_EXP==16384,"requires extended80 ABI");
_Static_assert(sizeof(_Float128)==16&&__FLT128_MANT_DIG__==113,"requires binary128 ABI");
static unsigned observations,fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static uint64_t random_word(void){static uint64_t s=UINT64_C(0x8123456789abcdef);s^=s<<13;s^=s>>7;s^=s<<17;return s;}
static u128 mask(unsigned width){return width==128?~(u128)0:((u128)1<<width)-1;}
static void write_bits(uint8_t *p,u128 raw,unsigned size){for(unsigned i=0;i<size;++i)p[i]=(uint8_t)(raw>>(8*i));}
static unsigned top(void){unsigned short status;__asm__ volatile("fnstsw %0":"=a"(status));return(status>>11)&7;}
__attribute__((noinline)) uint64_t scalar_sqrt_clobber(uint64_t seed){
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
__attribute__((noinline)) static long double expected80(unsigned operation,long double a,long double b,long double c){
    switch(operation){case 0:return truncl(a);case 1:return roundl(a);case 2:return ceill(a);case 3:return floorl(a);
    case 4:return log10l(a);case 5:return log2l(a);case 6:return logl(a);case 7:return exp2l(a);case 8:return expl(a);
    case 9:return tanl(a);case 10:return cosl(a);case 11:return sinl(a);case 13:return fmal(a,b,c);default:abort();}
}
__attribute__((noinline)) static _Float128 expected128(unsigned operation,_Float128 a,_Float128 b,_Float128 c){
    switch(operation){case 0:return truncf128(a);case 1:return roundf128(a);case 2:return ceilf128(a);case 3:return floorf128(a);
    case 4:return log10f128(a);case 5:return log2f128(a);case 6:return logf128(a);case 7:return exp2f128(a);case 8:return expf128(a);
    case 9:return tanf128(a);case 10:return cosf128(a);case 11:return sinf128(a);case 12:return sqrtf128(a);case 13:return fmaf128(a,b,c);default:abort();}
}
__attribute__((noinline)) static float expected32(unsigned operation,float a,float b,float c){
    switch(operation){case 0:return truncf(a);case 1:return roundf(a);case 2:return ceilf(a);case 3:return floorf(a);
    case 4:return log10f(a);case 5:return log2f(a);case 6:return logf(a);case 7:return exp2f(a);case 8:return expf(a);
    case 9:return tanf(a);case 10:return cosf(a);case 11:return sinf(a);case 12:{float r;__asm__("sqrtss %1,%0":"=x"(r):"x"(a));return r;}case 13:return fmaf(a,b,c);default:abort();}
}
__attribute__((noinline)) static double expected64(unsigned operation,double a,double b,double c){
    switch(operation){case 0:return trunc(a);case 1:return round(a);case 2:return ceil(a);case 3:return floor(a);
    case 4:return log10(a);case 5:return log2(a);case 6:return log(a);case 7:return exp2(a);case 8:return exp(a);
    case 9:return tan(a);case 10:return cos(a);case 11:return sin(a);case 12:{double r;__asm__("sqrtsd %1,%0":"=x"(r):"x"(a));return r;}case 13:return fma(a,b,c);default:abort();}
}
static const unsigned sizes[]={10,16,4,8},fractions[]={63,112,23,52},exponent_shifts[]={64,112,23,52},biases[]={16383,16383,127,1023},exponent_maxima[]={32767,32767,255,2047};
static u128 input(unsigned format,unsigned row){
    unsigned fraction=fractions[format],sign_shift=sizes[format]*8-1,exp_shift=exponent_shifts[format],bias=biases[format],exp_max=exponent_maxima[format];
    u128 sign=(u128)1<<sign_shift,one=(u128)bias<<exp_shift,integer=format==0?(u128)1<<63:0;
    u128 infinity=((u128)exp_max<<exp_shift)|integer,quiet=(u128)1<<(fraction-1);
    switch(row){case 0:return 0;case 1:return sign;case 2:return 1;case 3:return sign|1;
    case 4:return ((u128)1<<exp_shift)|integer;case 5:return mask(fraction);
    case 6:return one|integer;case 7:return sign|one|integer;
    case 8:return ((u128)(bias-1)<<exp_shift)|integer;case 9:return sign|((u128)(bias-1)<<exp_shift)|integer;
    case 10:return one|integer|((u128)1<<(fraction-1));case 11:return sign|one|integer|((u128)1<<(fraction-1));
    case 12:return ((u128)(bias+1)<<exp_shift)|integer|((u128)1<<(fraction-2));case 13:return sign|((u128)(bias+1)<<exp_shift)|integer|((u128)1<<(fraction-2));
    case 14:return ((u128)(exp_max-1)<<exp_shift)|integer|mask(fraction);case 15:return sign|((u128)(exp_max-1)<<exp_shift)|integer|mask(fraction);
    case 16:return infinity;case 17:return sign|infinity;case 18:return infinity|quiet|0x123;case 19:return sign|infinity|quiet|0x123;
    case 20:return infinity|1;case 21:return sign|infinity|1;default:break;}
    u128 raw=(((u128)random_word()<<64)|random_word())&mask(sizes[format]*8);
    if(!format){if((raw>>64)&0x7fff)raw|=(u128)1<<63;else raw&=~((u128)1<<63);}return raw;
}
static int nan_bits(u128 raw,unsigned format){return ((raw>>exponent_shifts[format])&exponent_maxima[format])==exponent_maxima[format]&&(raw&mask(fractions[format]));}
static int mismatch(unsigned which,unsigned row,const char *stage){fprintf(stderr,"scalar sqrt mismatch case=%u row=%u stage=%s fault=%u observation=%u\n",which,row,stage,fault,observations);return 1;}
static int check(uint8_t *left,uint8_t *right,uint8_t *third,unsigned which,unsigned row){
    const struct math_case *test=&cases[which];unsigned size=sizes[test->format];
    u128 a=input(test->format,row),b=input(test->format,row<22?(row+7)%22:row+1),c=input(test->format,row<22?(row+13)%22:row+2);
    write_bits(left,a,size);write_bits(right,b,size);write_bits(third,c,size);uint8_t before[3][16];memcpy(before[0],left,size);memcpy(before[1],right,size);memcpy(before[2],third,size);
    u128 expected=0;errno=0;
    if(test->format==0){long double x,y,z;memcpy(&x,&a,16);memcpy(&y,&b,16);memcpy(&z,&c,16);long double r=expected80(test->operation,x,y,z);memcpy(&expected,&r,10);}
    else if(test->format==1){_Float128 x,y,z;memcpy(&x,&a,16);memcpy(&y,&b,16);memcpy(&z,&c,16);_Float128 r=expected128(test->operation,x,y,z);memcpy(&expected,&r,16);}
    else if(test->format==2){float x,y,z;memcpy(&x,&a,4);memcpy(&y,&b,4);memcpy(&z,&c,4);float r=expected32(test->operation,x,y,z);memcpy(&expected,&r,4);}
    else{double x,y,z;memcpy(&x,&a,8);memcpy(&y,&b,8);memcpy(&z,&c,8);double r=expected64(test->operation,x,y,z);memcpy(&expected,&r,8);}
    int expected_errno=errno;uint64_t live=(uint64_t)a^(uint64_t)(b>>64)^(uint64_t)c^row;
    uint8_t out[32];memset(out,0xa7,sizeof out);errno=0;unsigned before_top=top();uint64_t actual=test->function(left,right,third,out+1,live);unsigned after_top=top();int actual_errno=errno;
    if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[1+size]^=1;u128 stored=0;memcpy(&stored,out+1,size);
    if(actual!=(live^key))return mismatch(which,row,"live");
    if(nan_bits(expected,test->format)?!nan_bits(stored,test->format):stored!=expected)return mismatch(which,row,"math-bits");
    if(actual_errno!=expected_errno)return mismatch(which,row,"errno");if(before_top!=after_top)return mismatch(which,row,"x87-top");
    if(out[0]!=0xa7)return mismatch(which,row,"prefix");for(unsigned i=1+size;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,"suffix");
    if(memcmp(before[0],left,size)||memcmp(before[1],right,size)||memcmp(before[2],third,size))return mismatch(which,row,"inputs-mutated");++observations;return 0;
}
int main(int argc,char **argv){
    if(argc==2)fault=(unsigned)strtoul(argv[1],0,10);if(argc>2||fault>3)return 2;long page=sysconf(_SC_PAGESIZE);if(page<4096)return 2;
    uint8_t *mapping=mmap(0,(size_t)page*6,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED||mprotect(mapping+page,(size_t)page,PROT_NONE)||mprotect(mapping+3*page,(size_t)page,PROT_NONE)||mprotect(mapping+5*page,(size_t)page,PROT_NONE))return 2;
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which){unsigned size=sizes[cases[which].format];for(unsigned row=0;row<4096;++row)if(check(mapping+page-size,mapping+3*page-size,mapping+5*page-size,which,row))return 1;}
    if(observations!=8192)return mismatch(0,0,"count");if(munmap(mapping,(size_t)page*6))return 2;
    puts("scalar-sqrt observations=8192 native=llvm=payloads=errno=x87=live=guards=preserved");return 0;
}
