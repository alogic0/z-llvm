#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case {kernel run;unsigned kind,from,to,predicate,pattern;};
enum {COPY,COMPARE,TRUNCATE,ZERO_EXTEND,SIGN_EXTEND,CONSTANT};
static size_t bytes_for(unsigned bits){return (bits+7)/8;}
static unsigned char last_mask(unsigned bits){return bits%8?(1u<<(bits%8))-1:255;}
static void cast_bytes(unsigned char *out,unsigned to,const unsigned char *in,unsigned from,int sign){
    unsigned char fill=sign&&((in[(from-1)/8]>>((from-1)%8))&1)?255:0;
    size_t size=bytes_for(to);memset(out,fill,size);
    size_t common=bytes_for(from)<size?bytes_for(from):size;memcpy(out,in,common);
    if(to>from&&from%8)out[(from-1)/8]=(in[(from-1)/8]&last_mask(from))|(fill&~last_mask(from));
    out[size-1]&=last_mask(to);
}
static int predicate(const unsigned char *a,const unsigned char *b,unsigned bits,unsigned code){
    int cmp=0;for(size_t i=bytes_for(bits);i-->0;){unsigned x=a[i],y=b[i];if(i==bytes_for(bits)-1){x&=last_mask(bits);y&=last_mask(bits);}if(x!=y){cmp=x<y?-1:1;break;}}
    int signed_cmp=cmp;unsigned sa=(a[(bits-1)/8]>>((bits-1)%8))&1,sb=(b[(bits-1)/8]>>((bits-1)%8))&1;
    if(sa!=sb)signed_cmp=sa?-1:1;
    switch(code){case 0:return cmp==0;case 1:return cmp!=0;case 2:return cmp<0;case 3:return cmp<=0;case 4:return cmp>0;case 5:return cmp>=0;case 6:return signed_cmp<0;case 7:return signed_cmp<=0;case 8:return signed_cmp>0;default:return signed_cmp>=0;}
}
static uint64_t low(const unsigned char *data,unsigned bits){uint64_t x=0;for(size_t i=0;i<bytes_for(bits)&&i<8;i++)x|=(uint64_t)data[i]<<(i*8);if(bits<64)x&=(UINT64_C(1)<<bits)-1;return x;}
static void constant_bytes(unsigned char *out,unsigned bits,unsigned pattern){
    size_t size=bytes_for(bits);memset(out,pattern==1||pattern==3?255:0,size);
    if(pattern==2)out[(bits-1)/8]=1u<<((bits-1)%8);
    if(pattern==3)out[(bits-1)/8]&=~(1u<<((bits-1)%8));
    out[size-1]&=last_mask(bits);
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *mapping=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(mapping==MAP_FAILED||mprotect(mapping+page,page,PROT_READ|PROT_WRITE))return 2;
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
        const struct test_case *item=&cases[which];size_t stride=((item->from+127)/128)*16,size=48+stride+bytes_for(item->from);unsigned char saved[304];
        for(size_t i=0;i<size;i++)saved[i]=(unsigned char)((i*73u+seed*31u)^((i+17u)*(seed+3u)));
        unsigned char *x=saved+48,*y=x+stride;size_t n=bytes_for(item->from);
        if(seed==0){memset(x,0,n);memset(y,0,n);}if(seed==1){memset(x,255,n);memset(y,255,n);}
        if(seed==2){memset(x,0,n);memset(y,0,n);x[(item->from-1)/8]=1u<<((item->from-1)%8);}
        if(seed==3){memset(x,0,n);memset(y,0,n);y[(item->from-1)/8]=1u<<((item->from-1)%8);}
        if(seed>=4&&seed<36){memset(x,0,n);memset(y,0,n);unsigned bit=((seed-4)*37u)%item->from;x[bit/8]=1u<<(bit%8);if(seed&1)y[bit/8]=1u<<(bit%8);}
        if(seed==36)memcpy(y,x,n);
        if(seed>=37&&seed<53){memcpy(y,x,n);size_t offset=((seed-37)*8u)%n;y[offset]^=1;}
        unsigned char *input=mapping+2*page-size;memcpy(input,saved,size);uint64_t words[6];memcpy(words,saved,48);
        uint64_t salt=UINT64_C(0x8123456789abcdef)^((uint64_t)seed*UINT64_C(0x9182736455aaccdd));
        struct packet {uint64_t pre;unsigned char data[280];uint64_t post;} actual,expected;
        memset(&actual,0xa5,sizeof actual);memset(&expected,0xa5,sizeof expected);
        size_t payload=bytes_for(item->to);uint64_t initial;
        if(item->kind==COMPARE){int condition=predicate(x,y,item->from,item->predicate);cast_bytes(expected.data,item->to,condition?x:y,item->from,0);cast_bytes(expected.data+payload,item->to,condition?y:x,item->from,0);initial=low(expected.data,item->to)^low(expected.data+payload,item->to)^(uint64_t)condition;payload*=2;}
        else {if(item->kind==CONSTANT)constant_bytes(expected.data,item->to,item->pattern);else cast_bytes(expected.data,item->to,y,item->from,item->kind==SIGN_EXTEND);initial=low(expected.data,item->to);}
        uint64_t checksum=initial;for(unsigned i=0;i<6;i++)checksum=(checksum*UINT64_C(1099511628211))^words[i];
        memcpy(expected.data+payload,&checksum,8);memcpy(expected.data+payload+8,&salt,8);memcpy(expected.data+payload+16,&words[0],8);
        uint64_t answer=item->run(input,actual.data,salt),returned=checksum^salt;
        if(fault==1)actual.data[0]^=1;if(fault==2)answer^=1;if(fault==3)actual.post^=1;
        uint64_t recorded_checksum,recorded_salt,recorded_first;memcpy(&recorded_checksum,actual.data+payload,8);memcpy(&recorded_salt,actual.data+payload+8,8);memcpy(&recorded_first,actual.data+payload+16,8);
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"memory-limbs case=%zu kind=%u from=%u to=%u seed=%u observation=%zu fault=%u\n",which,item->kind,item->from,item->to,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==returned);CHECK(memcmp(actual.data,expected.data,payload)==0);CHECK(recorded_checksum==checksum);CHECK(recorded_salt==salt);CHECK(recorded_first==words[0]);
        CHECK(actual.pre==expected.pre);CHECK(actual.post==expected.post);CHECK(memcmp(actual.data+payload+24,expected.data+payload+24,sizeof actual.data-payload-24)==0);CHECK(memcmp(input,saved,size)==0);
#undef CHECK
    }
    printf("memory-limbs observations=%zu byte-model=integer-predicates=cast-domains=exact-tails=guard-pages=live-aliases=stack-calls=preserved\n",observations);return munmap(mapping,page*3)!=0;
}
extern uint64_t memory_limbs_probe_0(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_1(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_2(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_3(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_4(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_5(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_6(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_7(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_8(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_9(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_10(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_11(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_12(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_13(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_14(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_15(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_16(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_17(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_18(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_19(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_20(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_21(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_22(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_23(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_24(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_25(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_26(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_27(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_28(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_29(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_30(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_31(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_32(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_33(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_34(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_35(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_36(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_37(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_38(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_39(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_40(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_41(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_42(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_43(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_44(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_45(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_46(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_47(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_48(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_49(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_50(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_51(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_52(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_53(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_54(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_55(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_56(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_57(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_58(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_59(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_60(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_61(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_62(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_63(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_64(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_65(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_66(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_67(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_68(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_69(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_70(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_71(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_72(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_73(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_74(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_75(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_76(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_77(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_78(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_79(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_80(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_81(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_82(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_83(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_84(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_85(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_86(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_87(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_88(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_89(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_90(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_91(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_92(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_93(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_94(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_95(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_96(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_97(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_98(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_99(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_100(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_101(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_102(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_103(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_104(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_105(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_106(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_107(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_108(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_109(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_110(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_111(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_112(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_113(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_114(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_115(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_116(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_117(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_118(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_119(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_120(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_121(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_122(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_123(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_124(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_125(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_126(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_127(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_128(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_129(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_130(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_131(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_132(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_133(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_134(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_135(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_136(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_137(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_138(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_139(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_140(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_141(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_142(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_143(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_144(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_145(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_146(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_147(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_148(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_149(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_150(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_151(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_152(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_153(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_154(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_155(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_156(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_157(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_158(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_159(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_160(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_161(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_162(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_163(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_164(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_165(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_166(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_167(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_168(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_169(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_170(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_171(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_172(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_173(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_174(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_175(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_176(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_177(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_178(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_179(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_180(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_181(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_182(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_183(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_184(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_185(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_186(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_187(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_188(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_189(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_190(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_191(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_192(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_193(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_194(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_195(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_196(const void *,void *,uint64_t);
extern uint64_t memory_limbs_probe_197(const void *,void *,uint64_t);
static const struct test_case cases[]={
{memory_limbs_probe_0,0,800,800,0,0},
{memory_limbs_probe_1,1,800,800,0,0},
{memory_limbs_probe_2,1,800,800,1,0},
{memory_limbs_probe_3,1,800,800,2,0},
{memory_limbs_probe_4,1,800,800,3,0},
{memory_limbs_probe_5,1,800,800,4,0},
{memory_limbs_probe_6,1,800,800,5,0},
{memory_limbs_probe_7,1,800,800,6,0},
{memory_limbs_probe_8,1,800,800,7,0},
{memory_limbs_probe_9,1,800,800,8,0},
{memory_limbs_probe_10,1,800,800,9,0},
{memory_limbs_probe_11,5,800,800,0,0},
{memory_limbs_probe_12,5,800,800,0,1},
{memory_limbs_probe_13,5,800,800,0,2},
{memory_limbs_probe_14,5,800,800,0,3},
{memory_limbs_probe_15,2,800,8,0,0},
{memory_limbs_probe_16,3,8,800,0,0},
{memory_limbs_probe_17,4,8,800,0,0},
{memory_limbs_probe_18,2,800,16,0,0},
{memory_limbs_probe_19,3,16,800,0,0},
{memory_limbs_probe_20,4,16,800,0,0},
{memory_limbs_probe_21,2,800,32,0,0},
{memory_limbs_probe_22,3,32,800,0,0},
{memory_limbs_probe_23,4,32,800,0,0},
{memory_limbs_probe_24,2,800,64,0,0},
{memory_limbs_probe_25,3,64,800,0,0},
{memory_limbs_probe_26,4,64,800,0,0},
{memory_limbs_probe_27,2,800,128,0,0},
{memory_limbs_probe_28,3,128,800,0,0},
{memory_limbs_probe_29,4,128,800,0,0},
{memory_limbs_probe_30,0,800,800,0,0},
{memory_limbs_probe_31,1,800,800,0,0},
{memory_limbs_probe_32,1,800,800,1,0},
{memory_limbs_probe_33,1,800,800,2,0},
{memory_limbs_probe_34,1,800,800,3,0},
{memory_limbs_probe_35,1,800,800,4,0},
{memory_limbs_probe_36,1,800,800,5,0},
{memory_limbs_probe_37,1,800,800,6,0},
{memory_limbs_probe_38,1,800,800,7,0},
{memory_limbs_probe_39,1,800,800,8,0},
{memory_limbs_probe_40,1,800,800,9,0},
{memory_limbs_probe_41,5,800,800,0,0},
{memory_limbs_probe_42,5,800,800,0,1},
{memory_limbs_probe_43,5,800,800,0,2},
{memory_limbs_probe_44,5,800,800,0,3},
{memory_limbs_probe_45,2,800,8,0,0},
{memory_limbs_probe_46,3,8,800,0,0},
{memory_limbs_probe_47,4,8,800,0,0},
{memory_limbs_probe_48,2,800,16,0,0},
{memory_limbs_probe_49,3,16,800,0,0},
{memory_limbs_probe_50,4,16,800,0,0},
{memory_limbs_probe_51,2,800,32,0,0},
{memory_limbs_probe_52,3,32,800,0,0},
{memory_limbs_probe_53,4,32,800,0,0},
{memory_limbs_probe_54,2,800,64,0,0},
{memory_limbs_probe_55,3,64,800,0,0},
{memory_limbs_probe_56,4,64,800,0,0},
{memory_limbs_probe_57,2,800,128,0,0},
{memory_limbs_probe_58,3,128,800,0,0},
{memory_limbs_probe_59,4,128,800,0,0},
{memory_limbs_probe_60,0,896,896,0,0},
{memory_limbs_probe_61,1,896,896,0,0},
{memory_limbs_probe_62,1,896,896,1,0},
{memory_limbs_probe_63,1,896,896,2,0},
{memory_limbs_probe_64,1,896,896,3,0},
{memory_limbs_probe_65,1,896,896,4,0},
{memory_limbs_probe_66,1,896,896,5,0},
{memory_limbs_probe_67,1,896,896,6,0},
{memory_limbs_probe_68,1,896,896,7,0},
{memory_limbs_probe_69,1,896,896,8,0},
{memory_limbs_probe_70,1,896,896,9,0},
{memory_limbs_probe_71,5,896,896,0,0},
{memory_limbs_probe_72,5,896,896,0,1},
{memory_limbs_probe_73,5,896,896,0,2},
{memory_limbs_probe_74,5,896,896,0,3},
{memory_limbs_probe_75,2,896,8,0,0},
{memory_limbs_probe_76,3,8,896,0,0},
{memory_limbs_probe_77,4,8,896,0,0},
{memory_limbs_probe_78,2,896,16,0,0},
{memory_limbs_probe_79,3,16,896,0,0},
{memory_limbs_probe_80,4,16,896,0,0},
{memory_limbs_probe_81,2,896,32,0,0},
{memory_limbs_probe_82,3,32,896,0,0},
{memory_limbs_probe_83,4,32,896,0,0},
{memory_limbs_probe_84,2,896,64,0,0},
{memory_limbs_probe_85,3,64,896,0,0},
{memory_limbs_probe_86,4,64,896,0,0},
{memory_limbs_probe_87,2,896,128,0,0},
{memory_limbs_probe_88,3,128,896,0,0},
{memory_limbs_probe_89,4,128,896,0,0},
{memory_limbs_probe_90,0,896,896,0,0},
{memory_limbs_probe_91,1,896,896,0,0},
{memory_limbs_probe_92,1,896,896,1,0},
{memory_limbs_probe_93,1,896,896,2,0},
{memory_limbs_probe_94,1,896,896,3,0},
{memory_limbs_probe_95,1,896,896,4,0},
{memory_limbs_probe_96,1,896,896,5,0},
{memory_limbs_probe_97,1,896,896,6,0},
{memory_limbs_probe_98,1,896,896,7,0},
{memory_limbs_probe_99,1,896,896,8,0},
{memory_limbs_probe_100,1,896,896,9,0},
{memory_limbs_probe_101,5,896,896,0,0},
{memory_limbs_probe_102,5,896,896,0,1},
{memory_limbs_probe_103,5,896,896,0,2},
{memory_limbs_probe_104,5,896,896,0,3},
{memory_limbs_probe_105,2,896,8,0,0},
{memory_limbs_probe_106,3,8,896,0,0},
{memory_limbs_probe_107,4,8,896,0,0},
{memory_limbs_probe_108,2,896,16,0,0},
{memory_limbs_probe_109,3,16,896,0,0},
{memory_limbs_probe_110,4,16,896,0,0},
{memory_limbs_probe_111,2,896,32,0,0},
{memory_limbs_probe_112,3,32,896,0,0},
{memory_limbs_probe_113,4,32,896,0,0},
{memory_limbs_probe_114,2,896,64,0,0},
{memory_limbs_probe_115,3,64,896,0,0},
{memory_limbs_probe_116,4,64,896,0,0},
{memory_limbs_probe_117,2,896,128,0,0},
{memory_limbs_probe_118,3,128,896,0,0},
{memory_limbs_probe_119,4,128,896,0,0},
{memory_limbs_probe_120,0,1024,1024,0,0},
{memory_limbs_probe_121,1,1024,1024,0,0},
{memory_limbs_probe_122,1,1024,1024,1,0},
{memory_limbs_probe_123,1,1024,1024,2,0},
{memory_limbs_probe_124,1,1024,1024,3,0},
{memory_limbs_probe_125,1,1024,1024,4,0},
{memory_limbs_probe_126,1,1024,1024,5,0},
{memory_limbs_probe_127,1,1024,1024,6,0},
{memory_limbs_probe_128,1,1024,1024,7,0},
{memory_limbs_probe_129,1,1024,1024,8,0},
{memory_limbs_probe_130,1,1024,1024,9,0},
{memory_limbs_probe_131,5,1024,1024,0,0},
{memory_limbs_probe_132,5,1024,1024,0,1},
{memory_limbs_probe_133,5,1024,1024,0,2},
{memory_limbs_probe_134,5,1024,1024,0,3},
{memory_limbs_probe_135,2,1024,8,0,0},
{memory_limbs_probe_136,3,8,1024,0,0},
{memory_limbs_probe_137,4,8,1024,0,0},
{memory_limbs_probe_138,2,1024,16,0,0},
{memory_limbs_probe_139,3,16,1024,0,0},
{memory_limbs_probe_140,4,16,1024,0,0},
{memory_limbs_probe_141,2,1024,32,0,0},
{memory_limbs_probe_142,3,32,1024,0,0},
{memory_limbs_probe_143,4,32,1024,0,0},
{memory_limbs_probe_144,2,1024,64,0,0},
{memory_limbs_probe_145,3,64,1024,0,0},
{memory_limbs_probe_146,4,64,1024,0,0},
{memory_limbs_probe_147,2,1024,128,0,0},
{memory_limbs_probe_148,3,128,1024,0,0},
{memory_limbs_probe_149,4,128,1024,0,0},
{memory_limbs_probe_150,0,1024,1024,0,0},
{memory_limbs_probe_151,1,1024,1024,0,0},
{memory_limbs_probe_152,1,1024,1024,1,0},
{memory_limbs_probe_153,1,1024,1024,2,0},
{memory_limbs_probe_154,1,1024,1024,3,0},
{memory_limbs_probe_155,1,1024,1024,4,0},
{memory_limbs_probe_156,1,1024,1024,5,0},
{memory_limbs_probe_157,1,1024,1024,6,0},
{memory_limbs_probe_158,1,1024,1024,7,0},
{memory_limbs_probe_159,1,1024,1024,8,0},
{memory_limbs_probe_160,1,1024,1024,9,0},
{memory_limbs_probe_161,5,1024,1024,0,0},
{memory_limbs_probe_162,5,1024,1024,0,1},
{memory_limbs_probe_163,5,1024,1024,0,2},
{memory_limbs_probe_164,5,1024,1024,0,3},
{memory_limbs_probe_165,2,1024,8,0,0},
{memory_limbs_probe_166,3,8,1024,0,0},
{memory_limbs_probe_167,4,8,1024,0,0},
{memory_limbs_probe_168,2,1024,16,0,0},
{memory_limbs_probe_169,3,16,1024,0,0},
{memory_limbs_probe_170,4,16,1024,0,0},
{memory_limbs_probe_171,2,1024,32,0,0},
{memory_limbs_probe_172,3,32,1024,0,0},
{memory_limbs_probe_173,4,32,1024,0,0},
{memory_limbs_probe_174,2,1024,64,0,0},
{memory_limbs_probe_175,3,64,1024,0,0},
{memory_limbs_probe_176,4,64,1024,0,0},
{memory_limbs_probe_177,2,1024,128,0,0},
{memory_limbs_probe_178,3,128,1024,0,0},
{memory_limbs_probe_179,4,128,1024,0,0},
{memory_limbs_probe_180,3,800,896,0,0},
{memory_limbs_probe_181,4,800,896,0,0},
{memory_limbs_probe_182,2,896,800,0,0},
{memory_limbs_probe_183,3,800,896,0,0},
{memory_limbs_probe_184,4,800,896,0,0},
{memory_limbs_probe_185,2,896,800,0,0},
{memory_limbs_probe_186,3,800,1024,0,0},
{memory_limbs_probe_187,4,800,1024,0,0},
{memory_limbs_probe_188,2,1024,800,0,0},
{memory_limbs_probe_189,3,800,1024,0,0},
{memory_limbs_probe_190,4,800,1024,0,0},
{memory_limbs_probe_191,2,1024,800,0,0},
{memory_limbs_probe_192,3,896,1024,0,0},
{memory_limbs_probe_193,4,896,1024,0,0},
{memory_limbs_probe_194,2,1024,896,0,0},
{memory_limbs_probe_195,3,896,1024,0,0},
{memory_limbs_probe_196,4,896,1024,0,0},
{memory_limbs_probe_197,2,1024,896,0,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
