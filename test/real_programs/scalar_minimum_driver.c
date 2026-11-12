#define _GNU_SOURCE
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(unsigned char *,const unsigned char *,uint64_t);
#define DECL(B,N,O) extern uint64_t floating_minmax_##B##_##N##_##O(unsigned char *,const unsigned char *,uint64_t)
#define DECLS(B) DECL(B,2,min);DECL(B,2,max);DECL(B,3,min);DECL(B,3,max);DECL(B,4,min);DECL(B,4,max)
DECLS(16);DECLS(32);DECLS(64);DECLS(80);DECLS(128);
static uint64_t observations;
static void check(int pass,unsigned bits,unsigned lanes,unsigned op,unsigned sample,unsigned fault) {
    observations++;
    if(!pass){fprintf(stderr,"floating-minmax bits=%u lanes=%u op=%u sample=%u observation=%llu fault=%u\n",bits,lanes,op,sample,(unsigned long long)observations,fault);exit(1);}
}
static void snan(void *out,unsigned bits) {
    const uint16_t h=0x7c01;const uint32_t f=0x7f800001;const uint64_t d=UINT64_C(0x7ff0000000000001);
    const uint64_t x[2]={UINT64_C(0x8000000000000001),0x7fff},q[2]={1,UINT64_C(0x7fff000000000000)};
    memset(out,0,16);
    if(bits==16)memcpy(out,&h,2);else if(bits==32)memcpy(out,&f,4);else if(bits==64)memcpy(out,&d,8);else if(bits==80)memcpy(out,x,10);else memcpy(out,q,16);
}
#define TABLE(B) {{floating_minmax_##B##_2_min,floating_minmax_##B##_2_max},{floating_minmax_##B##_3_min,floating_minmax_##B##_3_max},{floating_minmax_##B##_4_min,floating_minmax_##B##_4_max}}
#define RUN(B,F) \
static F pair_##B(F x,F y,unsigned maximum) { \
    if(x==(F)0 && y==(F)0){int negative=maximum?(__builtin_signbit(x)&&__builtin_signbit(y)):(__builtin_signbit(x)||__builtin_signbit(y));return negative?(F)-0.0:(F)0.0;} \
    if(B==80)return(F)(maximum?fmaxl((long double)x,(long double)y):fminl((long double)x,(long double)y)); \
    if(B==128)return(F)(maximum?fmaxf128((_Float128)x,(_Float128)y):fminf128((_Float128)x,(_Float128)y)); \
    if(__builtin_isnan(x))return y;if(__builtin_isnan(y))return x; \
    if(x==(F)0 && y==(F)0){int negative=maximum?(__builtin_signbit(x)&&__builtin_signbit(y)):(__builtin_signbit(x)||__builtin_signbit(y));return negative?(F)-0.0:(F)0.0;} \
    return maximum?(x>y?x:y):(x<y?x:y); \
} \
static void run_##B(unsigned char *map,size_t page,unsigned fault) { \
    const kernel functions[3][2]=TABLE(B);const unsigned bytes=B/8; \
    for(unsigned ni=0;ni<3;ni++)for(unsigned op=0;op<2;op++)for(unsigned sample=0;sample<64;sample++) { \
        unsigned n=ni+2;F values[4]; \
        for(unsigned i=0;i<4;i++)values[i]=(F)((int)((sample*7+i*11)%31)-15)/(F)4; \
        if(sample==0){values[0]=(F)0.0;values[1]=(F)-0.0;values[2]=(F)1;values[3]=(F)-1;} \
        if(sample==1){values[0]=(F)0.0;values[1]=(F)-0.0;values[2]=(F)-0.0;values[3]=(F)0.0;} \
        if(sample==2){values[0]=(F)0x1p-24L;values[1]=(F)-0x1p-24L;values[2]=(F)0.0;values[3]=(F)-0.0;} \
        if(sample==3){values[0]=(F)__builtin_infl();values[1]=(F)0;values[2]=(F)-__builtin_infl();values[3]=(F)1;} \
        if(sample==4){values[0]=(F)__builtin_nanl("");values[1]=(F)1;values[2]=(F)-2;values[3]=(F)3;} \
        if(sample==5)for(unsigned i=0;i<4;i++)values[i]=(F)-0.0; \
        if(sample==6)for(unsigned i=0;i<4;i++)values[i]=(F)0.0; \
        if(sample==9)for(unsigned i=0;i<4;i++)values[i]=(F)__builtin_nanl(""); \
        if(n==2 && (sample==7 || sample==8)){unsigned char raw[16];snan(raw,B);values[0]=(F)1;values[1]=(F)1;memcpy(&values[sample==7?0:1],raw,bytes);} \
        unsigned char *input=map+page-n*bytes;for(unsigned i=0;i<n;i++)memcpy(input+i*bytes,&values[i],bytes); \
        unsigned char saved[64];memcpy(saved,input,n*bytes); \
        F expected=values[0];for(unsigned i=1;i<n;i++)expected=pair_##B(expected,values[i],op); \
        struct{unsigned char pre[9],data[16],post[9];}out;memset(&out,0xa5,sizeof out); \
        uint64_t salt=sample*UINT64_C(0x9e3779b97f4a7c15)+n+op;uint64_t result=functions[ni][op](out.data,input,salt); \
        if(fault==1)result^=1;if(fault==2)memset(out.data,0xff,bytes);if(fault==3)out.post[0]^=1; \
        F actual=(F)0;memcpy(&actual,out.data,bytes); \
        int equal=__builtin_isnan(expected)?__builtin_isnan(actual):(actual==expected && (expected!=(F)0 || !!__builtin_signbit(actual)==!!__builtin_signbit(expected))); \
        check(result==(salt^90),B,n,op,sample,fault);check(equal,B,n,op,sample,fault); \
        int pre=1,post=1,tail=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}for(unsigned i=bytes;i<16;i++)tail&=out.data[i]==0xa5; \
        check(pre,B,n,op,sample,fault);check(tail,B,n,op,sample,fault);check(post,B,n,op,sample,fault);check(memcmp(input,saved,n*bytes)==0,B,n,op,sample,fault); \
    } \
}
RUN(16,_Float16) RUN(32,float) RUN(64,double) RUN(80,long double) RUN(128,__float128)
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;
    size_t page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *map=mmap(0,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(map==MAP_FAILED || mprotect(map+page,page,PROT_NONE))return 2;
    run_16(map,page,fault);run_32(map,page,fault);run_64(map,page,fault);run_80(map,page,fault);run_128(map,page,fault);
    if(munmap(map,page*2) || observations!=11520)return 2;
    printf("floating-minmax observations=%llu all-five-formats=pinned-nan-contract=signed-zeros=exact-tails=guard-pages=preserved\n",(unsigned long long)observations);
    return 0;
}
