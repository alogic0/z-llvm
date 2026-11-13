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
        if(item->kind==0) {
            expected[0]=checksum(words,reverse32((uint32_t)words[item->position]),item->position,item->declared);
            expected[1]=salt;expected[2]=words[0];returned=expected[0]^salt;
        } else if(item->kind==1||item->kind==2) {
            if(item->kind==1) expected[0]=item->declared?(words[0]^words[2]):(words[1]+words[2]);
            else expected[0]=(UINT64_C(32)*(item->declared?words[0]:words[1]))^words[2];
            expected[1]=salt;expected[2]=words[0];returned=expected[0]^salt;
        } else {
            uint64_t mask=item->bits==64?UINT64_MAX:(UINT64_C(1)<<item->bits)-1;
            expected[0]=(UINT64_C(0xa5a5a5a5a5a5a5a5)&~mask)|item->raw;
            expected[1]=checksum(words,0,0,0);expected[2]=item->raw;
            returned=expected[1]^item->raw^salt;
        }
        if(fault==1)output.data[0]^=1;if(fault==2)answer^=1;if(fault==3)output.post^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"scalar-followup case=%zu kind=%u seed=%u observation=%zu fault=%u\n",which,item->kind,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==returned);for(unsigned i=0;i<3;i++)CHECK(output.data[i]==expected[i]);
        CHECK(output.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(output.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,words,sizeof words)==0);
#undef CHECK
    }
    printf("literal-fp-bitcasts observations=%zu exact-payloads=live-aliases=cfg-phis=stack-calls=guard-pages=preserved\n",observations);
    return munmap(map,page*3)!=0;
}
extern uint64_t literal_fp_bitcasts_probe_0(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_1(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_2(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_3(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_4(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_5(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_6(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_7(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_8(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_9(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_10(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_11(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_12(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_13(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_14(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_15(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_16(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_17(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_18(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_19(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_20(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_21(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_22(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_23(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_24(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_25(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_26(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_27(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_28(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_29(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_30(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_31(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_32(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_33(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_34(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_35(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_36(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_37(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_38(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_39(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_40(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_41(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_42(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_43(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_44(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_45(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_46(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_47(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_48(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_49(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_50(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_51(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_52(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_53(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_54(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_55(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_56(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_57(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_58(const void *,void *,uint64_t);
extern uint64_t literal_fp_bitcasts_probe_59(const void *,void *,uint64_t);
static const struct test_case cases[]={
{literal_fp_bitcasts_probe_0,3,0,0,16,UINT64_C(0)},
{literal_fp_bitcasts_probe_1,3,0,0,16,UINT64_C(0)},
{literal_fp_bitcasts_probe_2,3,1,0,16,UINT64_C(1)},
{literal_fp_bitcasts_probe_3,3,1,0,16,UINT64_C(1)},
{literal_fp_bitcasts_probe_4,3,2,0,16,UINT64_C(65535)},
{literal_fp_bitcasts_probe_5,3,2,0,16,UINT64_C(65535)},
{literal_fp_bitcasts_probe_6,3,3,0,16,UINT64_C(32768)},
{literal_fp_bitcasts_probe_7,3,3,0,16,UINT64_C(32768)},
{literal_fp_bitcasts_probe_8,3,4,0,16,UINT64_C(0)},
{literal_fp_bitcasts_probe_9,3,4,0,16,UINT64_C(0)},
{literal_fp_bitcasts_probe_10,3,5,0,16,UINT64_C(4660)},
{literal_fp_bitcasts_probe_11,3,5,0,16,UINT64_C(4660)},
{literal_fp_bitcasts_probe_12,3,0,0,16,UINT64_C(1)},
{literal_fp_bitcasts_probe_13,3,0,0,16,UINT64_C(1)},
{literal_fp_bitcasts_probe_14,3,1,0,16,UINT64_C(4660)},
{literal_fp_bitcasts_probe_15,3,1,0,16,UINT64_C(4660)},
{literal_fp_bitcasts_probe_16,3,2,0,16,UINT64_C(0)},
{literal_fp_bitcasts_probe_17,3,2,0,16,UINT64_C(0)},
{literal_fp_bitcasts_probe_18,3,3,0,16,UINT64_C(57072)},
{literal_fp_bitcasts_probe_19,3,3,0,16,UINT64_C(57072)},
{literal_fp_bitcasts_probe_20,3,4,0,32,UINT64_C(0)},
{literal_fp_bitcasts_probe_21,3,4,0,32,UINT64_C(0)},
{literal_fp_bitcasts_probe_22,3,5,0,32,UINT64_C(1)},
{literal_fp_bitcasts_probe_23,3,5,0,32,UINT64_C(1)},
{literal_fp_bitcasts_probe_24,3,0,0,32,UINT64_C(4294967295)},
{literal_fp_bitcasts_probe_25,3,0,0,32,UINT64_C(4294967295)},
{literal_fp_bitcasts_probe_26,3,1,0,32,UINT64_C(32768)},
{literal_fp_bitcasts_probe_27,3,1,0,32,UINT64_C(32768)},
{literal_fp_bitcasts_probe_28,3,2,0,32,UINT64_C(2139095040)},
{literal_fp_bitcasts_probe_29,3,2,0,32,UINT64_C(2139095040)},
{literal_fp_bitcasts_probe_30,3,3,0,32,UINT64_C(2146964020)},
{literal_fp_bitcasts_probe_31,3,3,0,32,UINT64_C(2146964020)},
{literal_fp_bitcasts_probe_32,3,4,0,32,UINT64_C(1)},
{literal_fp_bitcasts_probe_33,3,4,0,32,UINT64_C(1)},
{literal_fp_bitcasts_probe_34,3,5,0,32,UINT64_C(4660)},
{literal_fp_bitcasts_probe_35,3,5,0,32,UINT64_C(4660)},
{literal_fp_bitcasts_probe_36,3,0,0,32,UINT64_C(0)},
{literal_fp_bitcasts_probe_37,3,0,0,32,UINT64_C(0)},
{literal_fp_bitcasts_probe_38,3,1,0,32,UINT64_C(2596069104)},
{literal_fp_bitcasts_probe_39,3,1,0,32,UINT64_C(2596069104)},
{literal_fp_bitcasts_probe_40,3,2,0,64,UINT64_C(0)},
{literal_fp_bitcasts_probe_41,3,2,0,64,UINT64_C(0)},
{literal_fp_bitcasts_probe_42,3,3,0,64,UINT64_C(1)},
{literal_fp_bitcasts_probe_43,3,3,0,64,UINT64_C(1)},
{literal_fp_bitcasts_probe_44,3,4,0,64,UINT64_C(18446744073709551615)},
{literal_fp_bitcasts_probe_45,3,4,0,64,UINT64_C(18446744073709551615)},
{literal_fp_bitcasts_probe_46,3,5,0,64,UINT64_C(9223372036854808576)},
{literal_fp_bitcasts_probe_47,3,5,0,64,UINT64_C(9223372036854808576)},
{literal_fp_bitcasts_probe_48,3,0,0,64,UINT64_C(8935281850574700544)},
{literal_fp_bitcasts_probe_49,3,0,0,64,UINT64_C(8935281850574700544)},
{literal_fp_bitcasts_probe_50,3,1,0,64,UINT64_C(9205677894728684084)},
{literal_fp_bitcasts_probe_51,3,1,0,64,UINT64_C(9205677894728684084)},
{literal_fp_bitcasts_probe_52,3,2,0,64,UINT64_C(9218868437227405313)},
{literal_fp_bitcasts_probe_53,3,2,0,64,UINT64_C(9218868437227405313)},
{literal_fp_bitcasts_probe_54,3,3,0,64,UINT64_C(9221120237041095220)},
{literal_fp_bitcasts_probe_55,3,3,0,64,UINT64_C(9221120237041095220)},
{literal_fp_bitcasts_probe_56,3,4,0,64,UINT64_C(9223372036854775808)},
{literal_fp_bitcasts_probe_57,3,4,0,64,UINT64_C(9223372036854775808)},
{literal_fp_bitcasts_probe_58,3,5,0,64,UINT64_C(1311768467463790320)},
{literal_fp_bitcasts_probe_59,3,5,0,64,UINT64_C(1311768467463790320)},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
