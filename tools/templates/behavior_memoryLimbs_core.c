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
