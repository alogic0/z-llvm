#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run;unsigned n,kind;};
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[3];
    for(unsigned m=0;m<3;m++){
        maps[m]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
        if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;
    }
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
        unsigned n=cases[which].n,k=cases[which].kind,packed=(n+7)/8,extent=n+2*packed;
        unsigned char *a=maps[0]+2*page-n,*b=maps[1]+2*page-n,*out=maps[2]+2*page-extent-8;
        unsigned char sa[64],sb[64],expected[80]={0},guard[8];
        memset(guard,0xa5,8);memset(out-8,0xa5,extent+16);
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;
        unsigned any=0;
        for(unsigned lane=0;lane<n;lane++){
            unsigned x=(seed+lane)&1,y=((seed>>1)+lane/2)&1;
            a[lane]=(unsigned char)((seed*37+lane*82)&254)|x;
            b[lane]=(unsigned char)((seed*93+lane*44)&254)|y;
            int l=k>=3?-(int)x:(int)x,r=k>=3?-(int)y:(int)y;
            int full=k%3==0?l+r:k%3==1?l-r:l*r;
            unsigned raw=(unsigned)full&1;
            unsigned ov=k>=3?(full< -1||full>0):(full<0||full>1);
            expected[lane]=(unsigned char)raw;
            expected[n+lane/8]|=(unsigned char)(ov<<(lane%8));
            expected[n+packed+lane/8]|=(unsigned char)(raw<<(lane%8));any|=ov;
        }
        memcpy(sa,a,n);memcpy(sb,b,n);
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page,PROT_READ))return 2;
        uint64_t salt=UINT64_C(0xfedcba9876543211)*seed,answer=cases[which].run(out,a,b,salt);
        if(fault==1)out[0]^=1;if(fault==2)out[n]^=1;if(fault==3)out[extent]^=1;
        int flags=1,wrapped=1;
        for(unsigned j=0;j<packed;j++){
            unsigned mask=j+1==packed&&n%8?(1u<<(n%8))-1:255;
            flags&=(out[n+j]&mask)==(expected[n+j]&mask);
            wrapped&=(out[n+packed+j]&mask)==(expected[n+packed+j]&mask);
        }
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"boolean-checked case=%zu n=%u kind=%u seed=%u observation=%zu fault=%u\n",which,n,k,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==(salt^any));CHECK(memcmp(out,expected,n)==0);CHECK(flags);CHECK(wrapped);
        CHECK(memcmp(out-8,guard,8)==0);CHECK(memcmp(out+extent,guard,8)==0);
        CHECK(memcmp(a,sa,n)==0);CHECK(memcmp(b,sb,n)==0);
#undef CHECK
    }
    printf("boolean-checked observations=%zu exhaustive-one-bit-pairs=signed-unsigned=packed-flags=canonical-lanes=readonly-inputs=guard-pages=preserved\n",observations);
    for(unsigned m=0;m<3;m++)if(munmap(maps[m],page*3))return 2;
    return 0;
}
extern uint64_t boolean_checked_probe_0(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_1(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_2(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_3(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_4(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_5(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_6(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_7(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_8(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_9(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_10(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_11(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_12(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_13(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_14(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_15(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_16(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_17(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_18(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_19(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_20(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_21(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_22(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_23(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_24(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_25(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_26(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_27(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_28(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_29(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_30(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_31(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_32(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_33(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_34(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_35(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_36(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_37(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_38(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_39(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_40(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_41(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_42(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_43(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_44(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_45(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_46(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_47(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_48(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_49(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_50(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_51(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_52(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_53(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_54(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_55(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_56(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_57(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_58(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_59(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_60(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_61(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_62(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_63(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_64(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_65(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_66(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_67(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_68(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_69(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_70(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_71(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_72(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_73(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_74(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_75(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_76(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_77(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_78(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_79(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_80(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_81(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_82(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_83(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_84(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_85(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_86(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_87(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_88(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_89(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_90(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_91(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_92(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_93(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_94(void *,const void *,const void *,uint64_t);
extern uint64_t boolean_checked_probe_95(void *,const void *,const void *,uint64_t);
static const struct test_case cases[]={
{boolean_checked_probe_0,1,0},
{boolean_checked_probe_1,1,0},
{boolean_checked_probe_2,1,1},
{boolean_checked_probe_3,1,1},
{boolean_checked_probe_4,1,2},
{boolean_checked_probe_5,1,2},
{boolean_checked_probe_6,1,3},
{boolean_checked_probe_7,1,3},
{boolean_checked_probe_8,1,4},
{boolean_checked_probe_9,1,4},
{boolean_checked_probe_10,1,5},
{boolean_checked_probe_11,1,5},
{boolean_checked_probe_12,2,0},
{boolean_checked_probe_13,2,0},
{boolean_checked_probe_14,2,1},
{boolean_checked_probe_15,2,1},
{boolean_checked_probe_16,2,2},
{boolean_checked_probe_17,2,2},
{boolean_checked_probe_18,2,3},
{boolean_checked_probe_19,2,3},
{boolean_checked_probe_20,2,4},
{boolean_checked_probe_21,2,4},
{boolean_checked_probe_22,2,5},
{boolean_checked_probe_23,2,5},
{boolean_checked_probe_24,3,0},
{boolean_checked_probe_25,3,0},
{boolean_checked_probe_26,3,1},
{boolean_checked_probe_27,3,1},
{boolean_checked_probe_28,3,2},
{boolean_checked_probe_29,3,2},
{boolean_checked_probe_30,3,3},
{boolean_checked_probe_31,3,3},
{boolean_checked_probe_32,3,4},
{boolean_checked_probe_33,3,4},
{boolean_checked_probe_34,3,5},
{boolean_checked_probe_35,3,5},
{boolean_checked_probe_36,4,0},
{boolean_checked_probe_37,4,0},
{boolean_checked_probe_38,4,1},
{boolean_checked_probe_39,4,1},
{boolean_checked_probe_40,4,2},
{boolean_checked_probe_41,4,2},
{boolean_checked_probe_42,4,3},
{boolean_checked_probe_43,4,3},
{boolean_checked_probe_44,4,4},
{boolean_checked_probe_45,4,4},
{boolean_checked_probe_46,4,5},
{boolean_checked_probe_47,4,5},
{boolean_checked_probe_48,8,0},
{boolean_checked_probe_49,8,0},
{boolean_checked_probe_50,8,1},
{boolean_checked_probe_51,8,1},
{boolean_checked_probe_52,8,2},
{boolean_checked_probe_53,8,2},
{boolean_checked_probe_54,8,3},
{boolean_checked_probe_55,8,3},
{boolean_checked_probe_56,8,4},
{boolean_checked_probe_57,8,4},
{boolean_checked_probe_58,8,5},
{boolean_checked_probe_59,8,5},
{boolean_checked_probe_60,16,0},
{boolean_checked_probe_61,16,0},
{boolean_checked_probe_62,16,1},
{boolean_checked_probe_63,16,1},
{boolean_checked_probe_64,16,2},
{boolean_checked_probe_65,16,2},
{boolean_checked_probe_66,16,3},
{boolean_checked_probe_67,16,3},
{boolean_checked_probe_68,16,4},
{boolean_checked_probe_69,16,4},
{boolean_checked_probe_70,16,5},
{boolean_checked_probe_71,16,5},
{boolean_checked_probe_72,32,0},
{boolean_checked_probe_73,32,0},
{boolean_checked_probe_74,32,1},
{boolean_checked_probe_75,32,1},
{boolean_checked_probe_76,32,2},
{boolean_checked_probe_77,32,2},
{boolean_checked_probe_78,32,3},
{boolean_checked_probe_79,32,3},
{boolean_checked_probe_80,32,4},
{boolean_checked_probe_81,32,4},
{boolean_checked_probe_82,32,5},
{boolean_checked_probe_83,32,5},
{boolean_checked_probe_84,64,0},
{boolean_checked_probe_85,64,0},
{boolean_checked_probe_86,64,1},
{boolean_checked_probe_87,64,1},
{boolean_checked_probe_88,64,2},
{boolean_checked_probe_89,64,2},
{boolean_checked_probe_90,64,3},
{boolean_checked_probe_91,64,3},
{boolean_checked_probe_92,64,4},
{boolean_checked_probe_93,64,4},
{boolean_checked_probe_94,64,5},
{boolean_checked_probe_95,64,5},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
