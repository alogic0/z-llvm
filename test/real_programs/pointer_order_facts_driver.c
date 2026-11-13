#define DRIVER_NAME "pointer-order-facts"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-c-integer-address-order=all-eight-relational-predicates=high-address-bits=null-and-constant-pointers-on-either-side=caller-and-owned-and-global-geps=quoted-symbols=exact-differences=live-results-after-clobbers=guard-pages=preserved"
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
extern unsigned char pointer_order_global[128];
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned form=item->kind/8,predicate=item->kind%8;
    static const uint64_t edges[8]={0,1,4095,UINT64_C(0x7fffffffffffffff),UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000001),UINT64_MAX-1,UINT64_MAX};
    uint64_t left=seed<32?edges[seed%8]:(seed+1)*UINT64_C(0x9182736455aaccdd),right=seed<32?edges[(seed/8+seed)%8]:~left;
    if(form==1||form==3){left=seed%64;right=(seed*17+7)%64;}
    if(form==2){left=0;right=seed%64;}
    if(form==4)left=0;
    if(form==5)left=UINT64_C(0x8000000000000000);
    if(form==6)left=(uintptr_t)pointer_order_global;
    if(form==7){left=31;right=seed%64;}
    if(form==8)right=0;
    if(form==9)right=UINT64_MAX;
    memcpy(input,&left,8);memcpy(input+8,&right,8);
    uint64_t x=left,y=right;if(predicate>=4){x^=UINT64_C(0x8000000000000000);y^=UINT64_C(0x8000000000000000);}
    uint64_t result=predicate%4==0?x<y:predicate%4==1?x<=y:predicate%4==2?x>y:x>=y;
    uint64_t delta=right-left,token=clobber_model(salt);
    memcpy(gold,&result,8);memcpy(gold+8,&delta,8);memcpy(gold+16,&token,8);
    return (struct test_model){128,1,24,SIZE_MAX,255,token^result};
}
extern uint64_t pointer_order_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_59(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_60(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_61(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_62(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_63(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_64(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_65(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_66(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_67(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_68(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_69(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_70(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_71(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_72(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_73(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_74(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_75(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_76(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_77(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_78(void *,void *,const void *,uint64_t);
extern uint64_t pointer_order_probe_79(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{pointer_order_probe_0,64,0,0},
{pointer_order_probe_1,64,8,0},
{pointer_order_probe_2,64,16,0},
{pointer_order_probe_3,64,24,0},
{pointer_order_probe_4,64,32,0},
{pointer_order_probe_5,64,40,0},
{pointer_order_probe_6,64,48,0},
{pointer_order_probe_7,64,56,0},
{pointer_order_probe_8,64,64,0},
{pointer_order_probe_9,64,72,0},
{pointer_order_probe_10,64,1,0},
{pointer_order_probe_11,64,9,0},
{pointer_order_probe_12,64,17,0},
{pointer_order_probe_13,64,25,0},
{pointer_order_probe_14,64,33,0},
{pointer_order_probe_15,64,41,0},
{pointer_order_probe_16,64,49,0},
{pointer_order_probe_17,64,57,0},
{pointer_order_probe_18,64,65,0},
{pointer_order_probe_19,64,73,0},
{pointer_order_probe_20,64,2,0},
{pointer_order_probe_21,64,10,0},
{pointer_order_probe_22,64,18,0},
{pointer_order_probe_23,64,26,0},
{pointer_order_probe_24,64,34,0},
{pointer_order_probe_25,64,42,0},
{pointer_order_probe_26,64,50,0},
{pointer_order_probe_27,64,58,0},
{pointer_order_probe_28,64,66,0},
{pointer_order_probe_29,64,74,0},
{pointer_order_probe_30,64,3,0},
{pointer_order_probe_31,64,11,0},
{pointer_order_probe_32,64,19,0},
{pointer_order_probe_33,64,27,0},
{pointer_order_probe_34,64,35,0},
{pointer_order_probe_35,64,43,0},
{pointer_order_probe_36,64,51,0},
{pointer_order_probe_37,64,59,0},
{pointer_order_probe_38,64,67,0},
{pointer_order_probe_39,64,75,0},
{pointer_order_probe_40,64,4,0},
{pointer_order_probe_41,64,12,0},
{pointer_order_probe_42,64,20,0},
{pointer_order_probe_43,64,28,0},
{pointer_order_probe_44,64,36,0},
{pointer_order_probe_45,64,44,0},
{pointer_order_probe_46,64,52,0},
{pointer_order_probe_47,64,60,0},
{pointer_order_probe_48,64,68,0},
{pointer_order_probe_49,64,76,0},
{pointer_order_probe_50,64,5,0},
{pointer_order_probe_51,64,13,0},
{pointer_order_probe_52,64,21,0},
{pointer_order_probe_53,64,29,0},
{pointer_order_probe_54,64,37,0},
{pointer_order_probe_55,64,45,0},
{pointer_order_probe_56,64,53,0},
{pointer_order_probe_57,64,61,0},
{pointer_order_probe_58,64,69,0},
{pointer_order_probe_59,64,77,0},
{pointer_order_probe_60,64,6,0},
{pointer_order_probe_61,64,14,0},
{pointer_order_probe_62,64,22,0},
{pointer_order_probe_63,64,30,0},
{pointer_order_probe_64,64,38,0},
{pointer_order_probe_65,64,46,0},
{pointer_order_probe_66,64,54,0},
{pointer_order_probe_67,64,62,0},
{pointer_order_probe_68,64,70,0},
{pointer_order_probe_69,64,78,0},
{pointer_order_probe_70,64,7,0},
{pointer_order_probe_71,64,15,0},
{pointer_order_probe_72,64,23,0},
{pointer_order_probe_73,64,31,0},
{pointer_order_probe_74,64,39,0},
{pointer_order_probe_75,64,47,0},
{pointer_order_probe_76,64,55,0},
{pointer_order_probe_77,64,63,0},
{pointer_order_probe_78,64,71,0},
{pointer_order_probe_79,64,79,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
