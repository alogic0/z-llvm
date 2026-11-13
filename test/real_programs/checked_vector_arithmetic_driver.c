#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run;unsigned n,bits,kind,zero;};
static uint64_t read_lane(const unsigned char *p,unsigned bytes){uint64_t r=0;for(unsigned i=0;i<bytes;i++)r|=(uint64_t)p[i]<<(8*i);return r;}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[3];for(unsigned m=0;m<3;m++){maps[m]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;}
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
        const struct test_case *item=&cases[which];unsigned n=item->n,bits=item->bits,bytes=bits/8;
        size_t input_size=n*bytes,flag_bytes=(n+7)/8,extent=input_size+flag_bytes;
        unsigned char *a=maps[0]+2*page-input_size,*b=maps[1]+2*page-input_size,*out=maps[2]+2*page-extent-8;
        unsigned char saved_a[256],saved_b[256],expected[272]={0},guards[8];memset(guards,0xa5,8);memset(out-8,0xa5,extent+16);
        uint64_t mask=(UINT64_C(1)<<bits)-1,sign=UINT64_C(1)<<(bits-1);
        uint64_t edges[]={0,1,sign-1,sign,mask-1,mask,mask/3,mask/5};
        unsigned any=0;
        for(unsigned lane=0;lane<n;lane++){
            uint64_t x=seed<8?edges[(seed+lane)%8]:(((uint64_t)seed*UINT64_C(0x9182736455aaccdd))^((uint64_t)lane*UINT64_C(0x123456789abcdef1)))&mask;
            uint64_t y=seed<8?edges[(seed+3+lane*3)%8]:(~x&mask);
            for(unsigned byte=0;byte<bytes;byte++){a[lane*bytes+byte]=(unsigned char)(x>>(byte*8));b[lane*bytes+byte]=(unsigned char)(y>>(byte*8));}
            uint64_t left=item->zero?0:x,raw;unsigned overflow;
            if(item->kind<3){
                uint64_t full=item->kind==0?left+y:item->kind==1?left-y:left*y;
                raw=full&mask;overflow=item->kind==1?left<y:full>mask;
            }else{
                int64_t l=(int64_t)left,r=(int64_t)y;
                if(left&sign)l-=(INT64_C(1)<<bits);if(y&sign)r-=(INT64_C(1)<<bits);
                int64_t full=item->kind==3?l+r:item->kind==4?l-r:l*r;
                raw=(uint64_t)full&mask;overflow=full<-(int64_t)sign||full>(int64_t)(sign-1);
            }
            for(unsigned byte=0;byte<bytes;byte++)expected[lane*bytes+byte]=(unsigned char)(raw>>(byte*8));
            if(overflow)expected[input_size+lane/8]|=(unsigned char)(1u<<(lane%8));any|=overflow;
        }
        memcpy(saved_a,a,input_size);memcpy(saved_b,b,input_size);
        uint64_t salt=UINT64_C(0xfedcba9876543211)*seed,answer=item->run(out,a,b,salt);
        if(fault==1)out[0]^=1;if(fault==2)out[input_size]^=1;if(fault==3)out[extent]^=1;
        int flags_equal=1;for(size_t byte=0;byte<flag_bytes;byte++){
            unsigned byte_mask=(byte+1==flag_bytes&&n%8)?(1u<<(n%8))-1:255;
            flags_equal&=(out[input_size+byte]&byte_mask)==(expected[input_size+byte]&byte_mask);
        }
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"checked-vector case=%zu n=%u bits=%u kind=%u zero=%u seed=%u observation=%zu fault=%u\n",which,n,bits,item->kind,item->zero,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==(salt^any));CHECK(memcmp(out,expected,input_size)==0);CHECK(flags_equal);
        CHECK(memcmp(out-8,guards,8)==0);CHECK(memcmp(out+extent,guards,8)==0);CHECK(memcmp(a,saved_a,input_size)==0);CHECK(memcmp(b,saved_b,input_size)==0);
#undef CHECK
    }
    printf("checked-vector-arithmetic observations=%zu wrapped-lanes=packed-overflow-flags=live-values=exact-stores=guard-pages=preserved\n",observations);
    for(unsigned m=0;m<3;m++)if(munmap(maps[m],page*3)!=0)return 2;return 0;
}
extern uint64_t checked_vector_probe_0(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_1(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_2(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_3(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_4(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_5(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_6(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_7(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_8(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_9(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_10(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_11(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_12(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_13(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_14(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_15(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_16(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_17(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_18(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_19(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_20(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_21(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_22(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_23(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_24(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_25(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_26(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_27(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_28(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_29(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_30(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_31(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_32(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_33(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_34(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_35(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_36(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_37(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_38(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_39(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_40(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_41(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_42(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_43(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_44(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_45(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_46(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_47(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_48(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_49(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_50(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_51(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_52(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_53(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_54(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_55(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_56(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_57(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_58(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_59(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_60(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_61(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_62(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_63(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_64(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_65(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_66(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_67(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_68(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_69(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_70(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_71(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_72(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_73(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_74(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_75(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_76(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_77(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_78(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_79(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_80(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_81(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_82(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_83(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_84(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_85(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_86(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_87(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_88(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_89(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_90(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_91(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_92(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_93(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_94(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_95(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_96(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_97(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_98(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_99(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_100(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_101(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_102(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_103(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_104(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_105(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_106(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_107(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_108(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_109(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_110(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_111(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_112(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_113(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_114(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_115(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_116(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_117(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_118(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_119(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_120(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_121(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_122(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_123(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_124(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_125(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_126(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_127(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_128(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_129(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_130(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_131(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_132(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_133(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_134(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_135(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_136(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_137(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_138(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_139(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_140(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_141(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_142(void *,const void *,const void *,uint64_t);
extern uint64_t checked_vector_probe_143(void *,const void *,const void *,uint64_t);
static const struct test_case cases[]={
{checked_vector_probe_0,2,32,0,0},
{checked_vector_probe_1,2,32,0,0},
{checked_vector_probe_2,2,32,0,1},
{checked_vector_probe_3,2,32,0,1},
{checked_vector_probe_4,2,32,1,0},
{checked_vector_probe_5,2,32,1,0},
{checked_vector_probe_6,2,32,1,1},
{checked_vector_probe_7,2,32,1,1},
{checked_vector_probe_8,2,32,2,0},
{checked_vector_probe_9,2,32,2,0},
{checked_vector_probe_10,2,32,2,1},
{checked_vector_probe_11,2,32,2,1},
{checked_vector_probe_12,2,32,3,0},
{checked_vector_probe_13,2,32,3,0},
{checked_vector_probe_14,2,32,3,1},
{checked_vector_probe_15,2,32,3,1},
{checked_vector_probe_16,2,32,4,0},
{checked_vector_probe_17,2,32,4,0},
{checked_vector_probe_18,2,32,4,1},
{checked_vector_probe_19,2,32,4,1},
{checked_vector_probe_20,2,32,5,0},
{checked_vector_probe_21,2,32,5,0},
{checked_vector_probe_22,2,32,5,1},
{checked_vector_probe_23,2,32,5,1},
{checked_vector_probe_24,3,32,0,0},
{checked_vector_probe_25,3,32,0,0},
{checked_vector_probe_26,3,32,1,0},
{checked_vector_probe_27,3,32,1,0},
{checked_vector_probe_28,3,32,2,0},
{checked_vector_probe_29,3,32,2,0},
{checked_vector_probe_30,3,32,3,0},
{checked_vector_probe_31,3,32,3,0},
{checked_vector_probe_32,3,32,4,0},
{checked_vector_probe_33,3,32,4,0},
{checked_vector_probe_34,3,32,5,0},
{checked_vector_probe_35,3,32,5,0},
{checked_vector_probe_36,4,8,0,0},
{checked_vector_probe_37,4,8,0,0},
{checked_vector_probe_38,4,8,0,1},
{checked_vector_probe_39,4,8,0,1},
{checked_vector_probe_40,4,8,1,0},
{checked_vector_probe_41,4,8,1,0},
{checked_vector_probe_42,4,8,1,1},
{checked_vector_probe_43,4,8,1,1},
{checked_vector_probe_44,4,8,2,0},
{checked_vector_probe_45,4,8,2,0},
{checked_vector_probe_46,4,8,2,1},
{checked_vector_probe_47,4,8,2,1},
{checked_vector_probe_48,4,8,3,0},
{checked_vector_probe_49,4,8,3,0},
{checked_vector_probe_50,4,8,3,1},
{checked_vector_probe_51,4,8,3,1},
{checked_vector_probe_52,4,8,4,0},
{checked_vector_probe_53,4,8,4,0},
{checked_vector_probe_54,4,8,4,1},
{checked_vector_probe_55,4,8,4,1},
{checked_vector_probe_56,4,8,5,0},
{checked_vector_probe_57,4,8,5,0},
{checked_vector_probe_58,4,8,5,1},
{checked_vector_probe_59,4,8,5,1},
{checked_vector_probe_60,2,8,0,0},
{checked_vector_probe_61,2,8,0,0},
{checked_vector_probe_62,2,8,1,0},
{checked_vector_probe_63,2,8,1,0},
{checked_vector_probe_64,2,8,2,0},
{checked_vector_probe_65,2,8,2,0},
{checked_vector_probe_66,2,8,3,0},
{checked_vector_probe_67,2,8,3,0},
{checked_vector_probe_68,2,8,4,0},
{checked_vector_probe_69,2,8,4,0},
{checked_vector_probe_70,2,8,5,0},
{checked_vector_probe_71,2,8,5,0},
{checked_vector_probe_72,4,16,0,0},
{checked_vector_probe_73,4,16,0,0},
{checked_vector_probe_74,4,16,1,0},
{checked_vector_probe_75,4,16,1,0},
{checked_vector_probe_76,4,16,2,0},
{checked_vector_probe_77,4,16,2,0},
{checked_vector_probe_78,4,16,3,0},
{checked_vector_probe_79,4,16,3,0},
{checked_vector_probe_80,4,16,4,0},
{checked_vector_probe_81,4,16,4,0},
{checked_vector_probe_82,4,16,5,0},
{checked_vector_probe_83,4,16,5,0},
{checked_vector_probe_84,8,8,0,0},
{checked_vector_probe_85,8,8,0,0},
{checked_vector_probe_86,8,8,1,0},
{checked_vector_probe_87,8,8,1,0},
{checked_vector_probe_88,8,8,2,0},
{checked_vector_probe_89,8,8,2,0},
{checked_vector_probe_90,8,8,3,0},
{checked_vector_probe_91,8,8,3,0},
{checked_vector_probe_92,8,8,4,0},
{checked_vector_probe_93,8,8,4,0},
{checked_vector_probe_94,8,8,5,0},
{checked_vector_probe_95,8,8,5,0},
{checked_vector_probe_96,4,32,0,0},
{checked_vector_probe_97,4,32,0,0},
{checked_vector_probe_98,4,32,1,0},
{checked_vector_probe_99,4,32,1,0},
{checked_vector_probe_100,4,32,2,0},
{checked_vector_probe_101,4,32,2,0},
{checked_vector_probe_102,4,32,3,0},
{checked_vector_probe_103,4,32,3,0},
{checked_vector_probe_104,4,32,4,0},
{checked_vector_probe_105,4,32,4,0},
{checked_vector_probe_106,4,32,5,0},
{checked_vector_probe_107,4,32,5,0},
{checked_vector_probe_108,8,32,0,0},
{checked_vector_probe_109,8,32,0,0},
{checked_vector_probe_110,8,32,1,0},
{checked_vector_probe_111,8,32,1,0},
{checked_vector_probe_112,8,32,2,0},
{checked_vector_probe_113,8,32,2,0},
{checked_vector_probe_114,8,32,3,0},
{checked_vector_probe_115,8,32,3,0},
{checked_vector_probe_116,8,32,4,0},
{checked_vector_probe_117,8,32,4,0},
{checked_vector_probe_118,8,32,5,0},
{checked_vector_probe_119,8,32,5,0},
{checked_vector_probe_120,1,8,0,0},
{checked_vector_probe_121,1,8,0,0},
{checked_vector_probe_122,1,8,1,0},
{checked_vector_probe_123,1,8,1,0},
{checked_vector_probe_124,1,8,2,0},
{checked_vector_probe_125,1,8,2,0},
{checked_vector_probe_126,1,8,3,0},
{checked_vector_probe_127,1,8,3,0},
{checked_vector_probe_128,1,8,4,0},
{checked_vector_probe_129,1,8,4,0},
{checked_vector_probe_130,1,8,5,0},
{checked_vector_probe_131,1,8,5,0},
{checked_vector_probe_132,64,32,0,0},
{checked_vector_probe_133,64,32,0,0},
{checked_vector_probe_134,64,32,1,0},
{checked_vector_probe_135,64,32,1,0},
{checked_vector_probe_136,64,32,2,0},
{checked_vector_probe_137,64,32,2,0},
{checked_vector_probe_138,64,32,3,0},
{checked_vector_probe_139,64,32,3,0},
{checked_vector_probe_140,64,32,4,0},
{checked_vector_probe_141,64,32,4,0},
{checked_vector_probe_142,64,32,5,0},
{checked_vector_probe_143,64,32,5,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
