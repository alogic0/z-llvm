#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(unsigned char *,const unsigned char *,const unsigned char *,uint64_t);
#define DECL(B,N,O) extern uint64_t floating_reduce_##B##_##N##_##O(unsigned char *,const unsigned char *,const unsigned char *,uint64_t)
#define DECLS(B) DECL(B,2,add);DECL(B,2,mul);DECL(B,3,add);DECL(B,3,mul);DECL(B,4,add);DECL(B,4,mul)
DECLS(16);DECLS(32);DECLS(64);DECLS(80);DECLS(128);
static uint64_t observations;
static void check(int pass,unsigned bits,unsigned lanes,unsigned op,unsigned sample,unsigned fault) {
    observations++;
    if(!pass){fprintf(stderr,"floating-reductions bits=%u lanes=%u op=%u sample=%u observation=%llu fault=%u\n",bits,lanes,op,sample,(unsigned long long)observations,fault);exit(1);}
}
#define TABLE(B) {{floating_reduce_##B##_2_add,floating_reduce_##B##_2_mul},{floating_reduce_##B##_3_add,floating_reduce_##B##_3_mul},{floating_reduce_##B##_4_add,floating_reduce_##B##_4_mul}}
#define RUN(B,F) \
static void run_##B(unsigned char *map,size_t page,unsigned fault) { \
    const kernel functions[3][2]=TABLE(B); \
    const unsigned bytes=B/8; \
    for(unsigned ni=0;ni<3;ni++)for(unsigned op=0;op<2;op++)for(unsigned sample=0;sample<64;sample++) { \
        unsigned n=ni+2; \
        F values[4],seed=op?(F)1:(F)-0.0; \
        for(unsigned i=0;i<4;i++) values[i]=(F)((int)((sample*7+i*11)%31)-15)/(F)4; \
        if(sample==0){values[0]=(F)0.0;values[1]=(F)-0.0;values[2]=(F)1;values[3]=(F)-1;} \
        if(sample==1){long double large=B==16?0x1p11L:B==32?0x1p24L:B==64?0x1p53L:B==80?0x1p64L:0x1p113L;values[0]=(F)large;values[1]=(F)1;values[2]=(F)-large;values[3]=(F)1;} \
        if(sample==2){values[0]=(F)0x1p-24L;values[1]=(F)0.5;values[2]=(F)0.5;values[3]=(F)-0x1p-24L;} \
        if(sample==3){values[0]=(F)__builtin_infl();values[1]=(F)0;values[2]=(F)-__builtin_infl();values[3]=(F)1;} \
        if(sample==4){values[0]=(F)__builtin_nanl("");values[1]=(F)1;values[2]=(F)-2;values[3]=(F)3;} \
        if(sample==5){seed=(F)-0.0;for(unsigned i=0;i<4;i++)values[i]=(F)-0.0;} \
        if(sample==6){seed=(F)-1;for(unsigned i=0;i<4;i++)values[i]=(F)0.0;} \
        volatile F expected=seed; \
        for(unsigned i=0;i<n;i++) expected=op?(F)(expected*values[i]):(F)(expected+values[i]); \
        unsigned char *input=map+page-n*bytes,*sp=map+3*page-bytes; \
        for(unsigned i=0;i<n;i++)memcpy(input+i*bytes,&values[i],bytes); \
        memcpy(sp,&seed,bytes); \
        unsigned char saved[64],saved_seed[16];memcpy(saved,input,n*bytes);memcpy(saved_seed,sp,bytes); \
        struct{unsigned char pre[9],data[16],post[9];}out;memset(&out,0xa5,sizeof out); \
        uint64_t salt=sample*UINT64_C(0x9e3779b97f4a7c15)+n+op; \
        uint64_t result=functions[ni][op](out.data,input,sp,salt); \
        if(fault==1)result^=1;if(fault==2)memset(out.data,0xff,bytes);if(fault==3)out.post[0]^=1; \
        F actual=(F)0;memcpy(&actual,out.data,bytes); \
        int equal=__builtin_isnan(expected)?__builtin_isnan(actual):(actual==expected && (expected!=(F)0 || __builtin_signbit(actual)==__builtin_signbit(expected))); \
        check(result==(salt^90),B,n,op,sample,fault);check(equal,B,n,op,sample,fault); \
        int pre=1,post=1,tail=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}for(unsigned i=bytes;i<16;i++)tail&=out.data[i]==0xa5; \
        check(pre,B,n,op,sample,fault);check(tail,B,n,op,sample,fault);check(post,B,n,op,sample,fault); \
        check(memcmp(input,saved,n*bytes)==0,B,n,op,sample,fault);check(memcmp(sp,saved_seed,bytes)==0,B,n,op,sample,fault); \
    } \
}
RUN(16,_Float16) RUN(32,float) RUN(64,double) RUN(80,long double) RUN(128,__float128)
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;
    size_t page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *map=mmap(0,page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(map==MAP_FAILED || mprotect(map+page,page,PROT_NONE) || mprotect(map+3*page,page,PROT_NONE))return 2;
    run_16(map,page,fault);run_32(map,page,fault);run_64(map,page,fault);run_80(map,page,fault);run_128(map,page,fault);
    if(munmap(map,page*4) || observations!=13440)return 2;
    printf("floating-reductions observations=%llu ordered-add-mul=all-five-formats=rounding=signed-zeros=exact-tails=guard-pages=preserved\n",(unsigned long long)observations);
    return 0;
}
