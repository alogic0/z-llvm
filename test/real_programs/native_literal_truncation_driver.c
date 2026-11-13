#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case { kernel run; unsigned kind,position,declared,bits; uint64_t raw,y; };
static uint64_t constant_value(const struct test_case *item){return item->raw&((UINT64_C(1)<<item->bits)-1);}
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
        static const uint64_t edges[]={0,1,UINT64_MAX,UINT64_C(0x8000000000000000),1023,1024,2047,2048,2049,65503,65504,65505,65519,65520,65521,65535,65536,65537};
        if(seed<sizeof edges/sizeof edges[0])words[item->position]=edges[seed];if(seed==3)words[item->position]=UINT64_C(1)<<(item->bits-1);
        unsigned char *input=map+2*page-sizeof words;memcpy(input,words,sizeof words);
        uint64_t salt=UINT64_C(0x9182736455aaccdd)^seed;
        struct {uint64_t pre,data[3],post;} output;memset(&output,0xa5,sizeof output);
        uint64_t answer=item->run(input,output.data,salt),expected[3],returned;
        uint64_t value=constant_value(item);
        expected[0]=checksum(words,value,0,0);expected[1]=salt;expected[2]=words[0];returned=expected[0]^salt;
        if(fault==1)output.data[0]^=1;if(fault==2)answer^=1;if(fault==3)output.post^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"scalar-followup case=%zu kind=%u seed=%u observation=%zu fault=%u\n",which,item->kind,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==returned);for(unsigned i=0;i<3;i++)CHECK(output.data[i]==expected[i]);
        CHECK(output.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(output.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,words,sizeof words)==0);
#undef CHECK
    }
    printf("native-literal-truncation observations=%zu integer-mask-model=native-widths=literal-spellings=live-aliases=stack-calls=guard-pages=preserved\n",observations);
    return munmap(map,page*3)!=0;
}
extern uint64_t literal_truncation_probe_0(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_1(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_2(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_3(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_4(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_5(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_6(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_7(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_8(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_9(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_10(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_11(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_12(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_13(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_14(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_15(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_16(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_17(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_18(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_19(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_20(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_21(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_22(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_23(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_24(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_25(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_26(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_27(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_28(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_29(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_30(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_31(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_32(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_33(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_34(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_35(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_36(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_37(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_38(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_39(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_40(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_41(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_42(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_43(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_44(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_45(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_46(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_47(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_48(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_49(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_50(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_51(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_52(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_53(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_54(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_55(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_56(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_57(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_58(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_59(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_60(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_61(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_62(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_63(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_64(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_65(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_66(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_67(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_68(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_69(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_70(const void *,void *,uint64_t);
extern uint64_t literal_truncation_probe_71(const void *,void *,uint64_t);
static const struct test_case cases[]={
{literal_truncation_probe_0,0,0,16,8,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_1,0,0,16,8,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_2,0,0,16,8,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_3,0,0,16,8,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_4,0,0,16,8,UINT64_C(65535),UINT64_C(0)},
{literal_truncation_probe_5,0,0,16,8,UINT64_C(65535),UINT64_C(0)},
{literal_truncation_probe_6,0,0,16,8,UINT64_C(32768),UINT64_C(0)},
{literal_truncation_probe_7,0,0,16,8,UINT64_C(32768),UINT64_C(0)},
{literal_truncation_probe_8,0,0,16,8,UINT64_C(32767),UINT64_C(0)},
{literal_truncation_probe_9,0,0,16,8,UINT64_C(32767),UINT64_C(0)},
{literal_truncation_probe_10,0,0,16,8,UINT64_C(65534),UINT64_C(0)},
{literal_truncation_probe_11,0,0,16,8,UINT64_C(65534),UINT64_C(0)},
{literal_truncation_probe_12,0,0,32,8,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_13,0,0,32,8,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_14,0,0,32,8,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_15,0,0,32,8,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_16,0,0,32,8,UINT64_C(4294967295),UINT64_C(0)},
{literal_truncation_probe_17,0,0,32,8,UINT64_C(4294967295),UINT64_C(0)},
{literal_truncation_probe_18,0,0,32,8,UINT64_C(2147483648),UINT64_C(0)},
{literal_truncation_probe_19,0,0,32,8,UINT64_C(2147483648),UINT64_C(0)},
{literal_truncation_probe_20,0,0,32,8,UINT64_C(2147483647),UINT64_C(0)},
{literal_truncation_probe_21,0,0,32,8,UINT64_C(2147483647),UINT64_C(0)},
{literal_truncation_probe_22,0,0,32,8,UINT64_C(4294967294),UINT64_C(0)},
{literal_truncation_probe_23,0,0,32,8,UINT64_C(4294967294),UINT64_C(0)},
{literal_truncation_probe_24,0,0,32,16,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_25,0,0,32,16,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_26,0,0,32,16,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_27,0,0,32,16,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_28,0,0,32,16,UINT64_C(4294967295),UINT64_C(0)},
{literal_truncation_probe_29,0,0,32,16,UINT64_C(4294967295),UINT64_C(0)},
{literal_truncation_probe_30,0,0,32,16,UINT64_C(2147483648),UINT64_C(0)},
{literal_truncation_probe_31,0,0,32,16,UINT64_C(2147483648),UINT64_C(0)},
{literal_truncation_probe_32,0,0,32,16,UINT64_C(2147483647),UINT64_C(0)},
{literal_truncation_probe_33,0,0,32,16,UINT64_C(2147483647),UINT64_C(0)},
{literal_truncation_probe_34,0,0,32,16,UINT64_C(4294967294),UINT64_C(0)},
{literal_truncation_probe_35,0,0,32,16,UINT64_C(4294967294),UINT64_C(0)},
{literal_truncation_probe_36,0,0,64,8,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_37,0,0,64,8,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_38,0,0,64,8,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_39,0,0,64,8,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_40,0,0,64,8,UINT64_C(18446744073709551615),UINT64_C(0)},
{literal_truncation_probe_41,0,0,64,8,UINT64_C(18446744073709551615),UINT64_C(0)},
{literal_truncation_probe_42,0,0,64,8,UINT64_C(9223372036854775808),UINT64_C(0)},
{literal_truncation_probe_43,0,0,64,8,UINT64_C(9223372036854775808),UINT64_C(0)},
{literal_truncation_probe_44,0,0,64,8,UINT64_C(9223372036854775807),UINT64_C(0)},
{literal_truncation_probe_45,0,0,64,8,UINT64_C(9223372036854775807),UINT64_C(0)},
{literal_truncation_probe_46,0,0,64,8,UINT64_C(18446744073709551614),UINT64_C(0)},
{literal_truncation_probe_47,0,0,64,8,UINT64_C(18446744073709551614),UINT64_C(0)},
{literal_truncation_probe_48,0,0,64,16,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_49,0,0,64,16,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_50,0,0,64,16,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_51,0,0,64,16,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_52,0,0,64,16,UINT64_C(18446744073709551615),UINT64_C(0)},
{literal_truncation_probe_53,0,0,64,16,UINT64_C(18446744073709551615),UINT64_C(0)},
{literal_truncation_probe_54,0,0,64,16,UINT64_C(9223372036854775808),UINT64_C(0)},
{literal_truncation_probe_55,0,0,64,16,UINT64_C(9223372036854775808),UINT64_C(0)},
{literal_truncation_probe_56,0,0,64,16,UINT64_C(9223372036854775807),UINT64_C(0)},
{literal_truncation_probe_57,0,0,64,16,UINT64_C(9223372036854775807),UINT64_C(0)},
{literal_truncation_probe_58,0,0,64,16,UINT64_C(18446744073709551614),UINT64_C(0)},
{literal_truncation_probe_59,0,0,64,16,UINT64_C(18446744073709551614),UINT64_C(0)},
{literal_truncation_probe_60,0,0,64,32,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_61,0,0,64,32,UINT64_C(0),UINT64_C(0)},
{literal_truncation_probe_62,0,0,64,32,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_63,0,0,64,32,UINT64_C(1),UINT64_C(0)},
{literal_truncation_probe_64,0,0,64,32,UINT64_C(18446744073709551615),UINT64_C(0)},
{literal_truncation_probe_65,0,0,64,32,UINT64_C(18446744073709551615),UINT64_C(0)},
{literal_truncation_probe_66,0,0,64,32,UINT64_C(9223372036854775808),UINT64_C(0)},
{literal_truncation_probe_67,0,0,64,32,UINT64_C(9223372036854775808),UINT64_C(0)},
{literal_truncation_probe_68,0,0,64,32,UINT64_C(9223372036854775807),UINT64_C(0)},
{literal_truncation_probe_69,0,0,64,32,UINT64_C(9223372036854775807),UINT64_C(0)},
{literal_truncation_probe_70,0,0,64,32,UINT64_C(18446744073709551614),UINT64_C(0)},
{literal_truncation_probe_71,0,0,64,32,UINT64_C(18446744073709551614),UINT64_C(0)},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
