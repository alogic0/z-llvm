#define DRIVER_NAME "vector-range-facts"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-defined-lane-bytes=typed-vector-ranges=signed-and-wrapped=nonzero-wide-patterns=cc-and-fastcc=closed-private-vectors=call-clobbers=guard-pages=preserved"
#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,void *,const void *,uint64_t);
struct test_case {kernel run;unsigned bits,kind,mutate;};
struct test_model {size_t input_bytes,expected_bytes,output_bytes,masked_byte;unsigned last_mask;uint64_t answer;};
static struct test_model oracle(const struct test_case *,unsigned,uint64_t,unsigned char *,unsigned char *,unsigned char *);
__attribute__((noinline)) uint64_t complete_clobber(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h){
    __asm__ volatile("":::"rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","memory");
    return a^(b*3)^(c*5)^(d*7)^(e*11)^(f*13)^(g*17)^(h*19);
}
static uint64_t clobber_model(uint64_t salt){return salt^6^15^28^55^78^119^152;}
static int matching(const unsigned char *a,const unsigned char *b,size_t n,size_t masked,unsigned mask){
#ifndef DRIVER_BYTE_MASK
#define DRIVER_BYTE_MASK(index) 255
#endif
    for(size_t j=0;j<n;j++)if((a[j]&(j==masked?mask:DRIVER_BYTE_MASK(j)))!=(b[j]&(j==masked?mask:DRIVER_BYTE_MASK(j))))return 0;
    return 1;
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[3];for(unsigned m=0;m<3;m++){
        maps[m]=mmap(0,page*5,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
        if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page*3,PROT_READ|PROT_WRITE))return 2;
    }
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<DRIVER_SEEDS;seed++){
        unsigned char saved[8192],expected_input[256],gold[8208],zeros[8192]={0},guard[8];
        memset(saved,0,sizeof saved);memset(expected_input,0,sizeof expected_input);memset(gold,0,sizeof gold);memset(guard,0xa5,8);
        uint64_t salt=(seed+1)*UINT64_C(0xfedcba9876543211);
        struct test_model model=oracle(&cases[which],seed,salt,saved,expected_input,gold);
        if(!model.input_bytes||model.input_bytes>sizeof saved||!model.expected_bytes||model.expected_bytes>sizeof expected_input||!model.output_bytes||model.output_bytes>sizeof gold)return 2;
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page*3,PROT_READ|PROT_WRITE))return 2;
        unsigned char *input=maps[0]+4*page-model.input_bytes,*expected=maps[1]+4*page-model.expected_bytes,*out=maps[2]+4*page-model.output_bytes-8;
        memcpy(input,saved,model.input_bytes);memcpy(expected,expected_input,model.expected_bytes);
        memcpy(input-8,guard,8);memcpy(expected-8,guard,8);memset(out-8,0xa5,model.output_bytes+16);
        if(!cases[which].mutate&&mprotect(maps[0]+page,page*3,PROT_READ))return 2;
        if(mprotect(maps[1]+page,page*3,PROT_READ))return 2;
        uint64_t answer=cases[which].run(out,input,expected,salt);
        if(fault==1)out[0]^=1;if(fault==2)answer^=1;if(fault==3)out[model.output_bytes]^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"%s case=%zu bits=%u kind=%u mutate=%u seed=%u observation=%zu fault=%u\n",DRIVER_NAME,which,cases[which].bits,cases[which].kind,cases[which].mutate,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==model.answer);
        CHECK(matching(out,gold,model.output_bytes,model.masked_byte,model.last_mask));
        CHECK(matching(input,cases[which].mutate?zeros:saved,model.input_bytes,cases[which].mutate?model.input_bytes-1:SIZE_MAX,cases[which].mutate?model.last_mask:255));
        CHECK(memcmp(expected,expected_input,model.expected_bytes)==0);
        CHECK(memcmp(input-8,guard,8)==0);CHECK(memcmp(expected-8,guard,8)==0);
        CHECK(memcmp(out-8,guard,8)==0);CHECK(memcmp(out+model.output_bytes,guard,8)==0);
#undef CHECK
    }
    printf("%s observations=%zu %s\n",DRIVER_NAME,observations,DRIVER_CONTRACT);
    for(unsigned m=0;m<3;m++)if(munmap(maps[m],page*5))return 2;
    return 0;
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned lanes=item->kind%128,kind=item->kind/128,bytes=item->bits/8;size_t payload=(size_t)lanes*bytes;
    uint64_t state=seed+UINT64_C(0x123456789abcdef1);
    for(unsigned lane=0;lane<lanes;lane++){
        unsigned char *value=input+lane*bytes;
        if(kind<3){int n=kind==0?4+(int)((seed+lane)%17):kind==1?(int)((seed+lane)%10)-5:(int)((seed+lane)%8)-4;memset(value,n<0?255:0,bytes);value[0]=(unsigned char)n;}
        else{unsigned nonzero=0;for(unsigned b=0;b<bytes;b++){state=state*UINT64_C(6364136223846793005)+1;value[b]=(unsigned char)(state>>32);nonzero|=value[b];}if(!nonzero)value[0]=1;}
    }
    uint64_t token=clobber_model(salt);memcpy(gold,input,payload);memcpy(gold+payload,&token,8);
    return (struct test_model){lanes==3?16:payload,1,payload+8,SIZE_MAX,255,token};
}
extern uint64_t vector_range_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_59(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_60(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_61(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_62(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_63(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_64(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_65(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_66(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_67(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_68(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_69(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_70(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_71(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_72(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_73(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_74(void *,void *,const void *,uint64_t);
extern uint64_t vector_range_probe_75(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{vector_range_probe_0,8,2,0},
{vector_range_probe_1,8,2,0},
{vector_range_probe_2,8,130,0},
{vector_range_probe_3,8,130,0},
{vector_range_probe_4,8,258,0},
{vector_range_probe_5,8,258,0},
{vector_range_probe_6,8,386,0},
{vector_range_probe_7,8,386,0},
{vector_range_probe_8,8,32,0},
{vector_range_probe_9,8,32,0},
{vector_range_probe_10,8,160,0},
{vector_range_probe_11,8,160,0},
{vector_range_probe_12,8,288,0},
{vector_range_probe_13,8,288,0},
{vector_range_probe_14,8,416,0},
{vector_range_probe_15,8,416,0},
{vector_range_probe_16,8,64,0},
{vector_range_probe_17,8,64,0},
{vector_range_probe_18,8,192,0},
{vector_range_probe_19,8,192,0},
{vector_range_probe_20,8,320,0},
{vector_range_probe_21,8,320,0},
{vector_range_probe_22,8,448,0},
{vector_range_probe_23,8,448,0},
{vector_range_probe_24,32,3,0},
{vector_range_probe_25,32,3,0},
{vector_range_probe_26,32,131,0},
{vector_range_probe_27,32,131,0},
{vector_range_probe_28,32,259,0},
{vector_range_probe_29,32,259,0},
{vector_range_probe_30,32,387,0},
{vector_range_probe_31,32,387,0},
{vector_range_probe_32,32,2,0},
{vector_range_probe_33,32,2,0},
{vector_range_probe_34,32,130,0},
{vector_range_probe_35,32,130,0},
{vector_range_probe_36,32,258,0},
{vector_range_probe_37,32,258,0},
{vector_range_probe_38,32,386,0},
{vector_range_probe_39,32,386,0},
{vector_range_probe_40,32,16,0},
{vector_range_probe_41,32,16,0},
{vector_range_probe_42,32,144,0},
{vector_range_probe_43,32,144,0},
{vector_range_probe_44,32,272,0},
{vector_range_probe_45,32,272,0},
{vector_range_probe_46,32,400,0},
{vector_range_probe_47,32,400,0},
{vector_range_probe_48,32,64,0},
{vector_range_probe_49,32,192,0},
{vector_range_probe_50,32,320,0},
{vector_range_probe_51,32,448,0},
{vector_range_probe_52,64,2,0},
{vector_range_probe_53,64,2,0},
{vector_range_probe_54,64,130,0},
{vector_range_probe_55,64,130,0},
{vector_range_probe_56,64,258,0},
{vector_range_probe_57,64,258,0},
{vector_range_probe_58,64,386,0},
{vector_range_probe_59,64,386,0},
{vector_range_probe_60,64,8,0},
{vector_range_probe_61,64,8,0},
{vector_range_probe_62,64,136,0},
{vector_range_probe_63,64,136,0},
{vector_range_probe_64,64,264,0},
{vector_range_probe_65,64,264,0},
{vector_range_probe_66,64,392,0},
{vector_range_probe_67,64,392,0},
{vector_range_probe_68,128,16,0},
{vector_range_probe_69,128,144,0},
{vector_range_probe_70,128,272,0},
{vector_range_probe_71,128,400,0},
{vector_range_probe_72,128,64,0},
{vector_range_probe_73,128,192,0},
{vector_range_probe_74,128,320,0},
{vector_range_probe_75,128,448,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
