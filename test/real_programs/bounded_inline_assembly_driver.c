#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case { kernel run; unsigned kind,position,declared,bits; uint64_t raw; };
static uint32_t reverse32(uint32_t x) {
    uint32_t r=0; for(unsigned i=0;i<32;i++){r=(r<<1)|(x&1);x>>=1;} return r;
}
static uint64_t checksum(const uint64_t *words,uint64_t initial,unsigned position,unsigned declared) {
    for(unsigned i=0;i<6;i++) initial=(initial*UINT64_C(1099511628211))^
        ((declared&&i==position)?(uint32_t)words[i]:words[i]);
    return initial;
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++) {
        const struct test_case *item=&cases[which];
        uint64_t words[6]; for(unsigned i=0;i<6;i++)words[i]=
            ((uint64_t)seed*UINT64_C(0x9182736455aaccdd))^((uint64_t)i*UINT64_C(0x123456789abcdef1));
        if(seed==1)memset(words,255,sizeof words);
        if(seed==2)for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x8000000080000000)^(UINT64_C(1)<<i);
        unsigned char *input=map+2*page-sizeof words;memcpy(input,words,sizeof words);
        uint64_t salt=UINT64_C(0x9182736455aaccdd)^seed;
        struct {uint64_t pre,data[3],post;} output;memset(&output,0xa5,sizeof output);
        uint64_t answer=item->run(input,output.data,salt),expected[3],returned;
        uint64_t value=item->kind==0||item->kind==3?item->raw:item->kind==1?(uint32_t)((uint32_t)words[item->position]+(item->declared?13:(uint32_t)words[(item->position+1)%6])):words[item->position];
        expected[0]=checksum(words,value,0,0);expected[1]=salt;expected[2]=words[0];returned=expected[0]^salt;
        if(fault==1)output.data[0]^=1;if(fault==2)answer^=1;if(fault==3)output.post^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"scalar-followup case=%zu kind=%u seed=%u observation=%zu fault=%u\n",which,item->kind,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==returned);for(unsigned i=0;i<3;i++)CHECK(output.data[i]==expected[i]);
        CHECK(output.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(output.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,words,sizeof words)==0);
#undef CHECK
    }
    printf("bounded-inline-assembly observations=%zu exact-asm-effects=live-aliases=opaque-memory-ordering=stack-calls=guard-pages=preserved\n",observations);
    return munmap(map,page*3)!=0;
}
extern uint64_t bounded_asm_probe_0(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_1(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_2(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_3(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_4(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_5(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_6(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_7(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_8(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_9(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_10(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_11(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_12(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_13(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_14(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_15(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_16(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_17(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_18(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_19(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_20(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_21(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_22(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_23(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_24(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_25(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_26(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_27(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_28(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_29(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_30(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_31(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_32(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_33(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_34(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_35(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_36(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_37(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_38(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_39(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_40(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_41(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_42(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_43(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_44(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_45(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_46(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_47(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_48(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_49(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_50(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_51(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_52(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_53(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_54(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_55(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_56(const void *,void *,uint64_t);
extern uint64_t bounded_asm_probe_57(const void *,void *,uint64_t);
static const struct test_case cases[]={
{bounded_asm_probe_0,0,0,0,32,UINT64_C(0)},
{bounded_asm_probe_1,0,0,0,32,UINT64_C(1)},
{bounded_asm_probe_2,0,0,0,32,UINT64_C(4294967295)},
{bounded_asm_probe_3,0,0,0,32,UINT64_C(123)},
{bounded_asm_probe_4,0,0,0,32,UINT64_C(2147483648)},
{bounded_asm_probe_5,0,0,0,32,UINT64_C(4294967295)},
{bounded_asm_probe_6,0,0,0,64,UINT64_C(0)},
{bounded_asm_probe_7,0,0,0,64,UINT64_C(1)},
{bounded_asm_probe_8,0,0,0,64,UINT64_C(18446744073709551615)},
{bounded_asm_probe_9,0,0,0,64,UINT64_C(123)},
{bounded_asm_probe_10,0,0,0,64,UINT64_C(9223372036854775808)},
{bounded_asm_probe_11,0,0,0,64,UINT64_C(18446744073709551615)},
{bounded_asm_probe_12,1,0,0,32,UINT64_C(0)},
{bounded_asm_probe_13,1,0,1,32,UINT64_C(0)},
{bounded_asm_probe_14,1,1,0,32,UINT64_C(0)},
{bounded_asm_probe_15,1,1,1,32,UINT64_C(0)},
{bounded_asm_probe_16,1,2,0,32,UINT64_C(0)},
{bounded_asm_probe_17,1,2,1,32,UINT64_C(0)},
{bounded_asm_probe_18,1,3,0,32,UINT64_C(0)},
{bounded_asm_probe_19,1,3,1,32,UINT64_C(0)},
{bounded_asm_probe_20,1,4,0,32,UINT64_C(0)},
{bounded_asm_probe_21,1,4,1,32,UINT64_C(0)},
{bounded_asm_probe_22,1,5,0,32,UINT64_C(0)},
{bounded_asm_probe_23,1,5,1,32,UINT64_C(0)},
{bounded_asm_probe_24,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_25,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_26,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_27,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_28,3,0,0,64,UINT64_C(1311768467463790321)},
{bounded_asm_probe_29,0,0,0,32,UINT64_C(0)},
{bounded_asm_probe_30,0,0,0,32,UINT64_C(1)},
{bounded_asm_probe_31,0,0,0,32,UINT64_C(4294967295)},
{bounded_asm_probe_32,0,0,0,32,UINT64_C(123)},
{bounded_asm_probe_33,0,0,0,32,UINT64_C(2147483648)},
{bounded_asm_probe_34,0,0,0,32,UINT64_C(4294967295)},
{bounded_asm_probe_35,0,0,0,64,UINT64_C(0)},
{bounded_asm_probe_36,0,0,0,64,UINT64_C(1)},
{bounded_asm_probe_37,0,0,0,64,UINT64_C(18446744073709551615)},
{bounded_asm_probe_38,0,0,0,64,UINT64_C(123)},
{bounded_asm_probe_39,0,0,0,64,UINT64_C(9223372036854775808)},
{bounded_asm_probe_40,0,0,0,64,UINT64_C(18446744073709551615)},
{bounded_asm_probe_41,1,0,0,32,UINT64_C(0)},
{bounded_asm_probe_42,1,0,1,32,UINT64_C(0)},
{bounded_asm_probe_43,1,1,0,32,UINT64_C(0)},
{bounded_asm_probe_44,1,1,1,32,UINT64_C(0)},
{bounded_asm_probe_45,1,2,0,32,UINT64_C(0)},
{bounded_asm_probe_46,1,2,1,32,UINT64_C(0)},
{bounded_asm_probe_47,1,3,0,32,UINT64_C(0)},
{bounded_asm_probe_48,1,3,1,32,UINT64_C(0)},
{bounded_asm_probe_49,1,4,0,32,UINT64_C(0)},
{bounded_asm_probe_50,1,4,1,32,UINT64_C(0)},
{bounded_asm_probe_51,1,5,0,32,UINT64_C(0)},
{bounded_asm_probe_52,1,5,1,32,UINT64_C(0)},
{bounded_asm_probe_53,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_54,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_55,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_56,2,0,0,64,UINT64_C(0)},
{bounded_asm_probe_57,3,0,0,64,UINT64_C(1311768467463790321)},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
