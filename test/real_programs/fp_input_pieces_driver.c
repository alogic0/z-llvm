#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef double fp_pair __attribute__((vector_size(16)));
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run,direct;unsigned bytes;};
static uint64_t prefix(unsigned i,uint64_t salt){return salt^((i+1)*UINT64_C(0x123456789abcdef1));}
static uint64_t tail(uint64_t salt){return salt^UINT64_C(0x8123456789abcdef);}
static uint64_t checksum(const uint64_t *args,uint64_t last){for(unsigned i=0;i<6;i++)last=(last*UINT64_C(1099511628211))^args[i];return last;}
static uint64_t word(const void *p){uint64_t r;memcpy(&r,p,8);return r;}
static void fill(unsigned char *out,unsigned bytes,unsigned seed,unsigned side){
    static const uint64_t edges[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),UINT64_C(0x7ff8000000001234),UINT64_C(0x7ff0000000000001),UINT64_MAX,1};
    for(unsigned lane=0;lane<4;lane++){
        if(bytes==8){uint64_t value=seed<8?edges[(seed+lane+side)%8]:((uint64_t)seed*UINT64_C(0x9182736455aaccdd))^((lane+side)*UINT64_C(0x123456789abcdef1));memcpy(out+lane*8,&value,8);}
        else if(bytes==16){uint64_t pair[2]={((uint64_t)seed*UINT64_C(0x9182736455aaccdd))^lane,((uint64_t)(lane+side)*UINT64_C(0x123456789abcdef1))^seed};if(seed==1)pair[0]=pair[1]=UINT64_MAX;memcpy(out+lane*16,pair,16);}
        else {uint64_t significant=UINT64_C(0x8000000000000000)|((uint64_t)(seed+lane+side)<<40);uint16_t exponent=(uint16_t)(0x3fff+((seed+lane+side)%4));if(seed&1)exponent|=0x8000;if(seed==0)significant=exponent=0;memcpy(out+lane*10,&significant,8);memcpy(out+lane*10+8,&exponent,2);}
    }
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[4];for(unsigned m=0;m<4;m++){maps[m]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page,PROT_READ|PROT_WRITE))return 2;}
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
        unsigned bytes=cases[which].bytes;size_t input_size=4*bytes,payload=8*bytes,span=payload+8;
        unsigned char *a=maps[0]+2*page-input_size,*b=maps[1]+2*page-input_size,*out=maps[2]+2*page-2*span-8,*direct=maps[3]+2*page-span-8;
        unsigned char saved_a[64],saved_b[64],expected[128],guards[8];memset(guards,0xa5,8);fill(a,bytes,seed,0);fill(b,bytes,seed,7);memcpy(saved_a,a,input_size);memcpy(saved_b,b,input_size);memcpy(expected,a,input_size);memcpy(expected+input_size,b,input_size);
        memset(out-8,0xa5,2*span+16);memset(direct-8,0xa5,span+16);
        uint64_t salt=UINT64_C(0xfedcba9876543211)*seed,args[6];for(unsigned i=0;i<6;i++)args[i]=prefix(i,salt);uint64_t expected_hash=checksum(args,tail(salt));
        uint64_t answer=cases[which].run(out,a,b,salt),direct_answer=cases[which].direct(direct,a,b,salt);
        if(fault==1)out[0]^=1;if(fault==2)out[payload]^=1;if(fault==3)out[2*span]^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"fp-input-pieces case=%zu bytes=%u seed=%u observation=%zu fault=%u\n",which,bytes,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==salt);CHECK(direct_answer==expected_hash);CHECK(memcmp(out,expected,payload)==0);CHECK(word(out+payload)==expected_hash);
        CHECK(memcmp(out+span,expected,payload)==0);CHECK(word(out+span+payload)==expected_hash);CHECK(memcmp(direct,expected,payload)==0);CHECK(word(direct+payload)==expected_hash);
        CHECK(memcmp(out-8,guards,8)==0);CHECK(memcmp(out+2*span,guards,8)==0);CHECK(memcmp(direct-8,guards,8)==0);CHECK(memcmp(direct+span,guards,8)==0);CHECK(memcmp(a,saved_a,input_size)==0);CHECK(memcmp(b,saved_b,input_size)==0);
#undef CHECK
    }
    printf("fp-input-pieces observations=%zu physical-c-llvm-local-interop=double-quad-x87=live-gp-prefixes=stack-slots=exact-payloads=guard-pages=preserved\n",observations);
    for(unsigned m=0;m<4;m++)if(munmap(maps[m],page*3)!=0)return 2;return 0;
}
extern uint64_t fp_piece_body_0(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,fp_pair v0,fp_pair v1,fp_pair v2,fp_pair v3,uint64_t last,void *out);
extern uint64_t fp_piece_probe_0(void *,const void *,const void *,uint64_t);
uint64_t fp_piece_provider_0(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,fp_pair v0,fp_pair v1,fp_pair v2,fp_pair v3,uint64_t last,void *out){uint64_t args[]={p0,p1,p2,p3,p4,p5};unsigned char *bytes=out;memcpy(bytes+0,&v0,16);memcpy(bytes+16,&v1,16);memcpy(bytes+32,&v2,16);memcpy(bytes+48,&v3,16);uint64_t value=checksum(args,last);memcpy(bytes+64,&value,8);return value;}
static uint64_t fp_piece_direct_0(void *out,const void *a,const void *b,uint64_t salt){fp_pair values[4];memset(values,0,sizeof values);memcpy(&values[0],(const unsigned char *)a+0,16);memcpy(&values[1],(const unsigned char *)a+16,16);memcpy(&values[2],(const unsigned char *)b+0,16);memcpy(&values[3],(const unsigned char *)b+16,16);return fp_piece_body_0(prefix(0,salt),prefix(1,salt),prefix(2,salt),prefix(3,salt),prefix(4,salt),prefix(5,salt),values[0],values[1],values[2],values[3],tail(salt),out);}
extern uint64_t fp_piece_body_1(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,fp_pair v0,fp_pair v1,fp_pair v2,fp_pair v3,uint64_t last,void *out);
extern uint64_t fp_piece_probe_1(void *,const void *,const void *,uint64_t);
uint64_t fp_piece_provider_1(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,fp_pair v0,fp_pair v1,fp_pair v2,fp_pair v3,uint64_t last,void *out){uint64_t args[]={p0,p1,p2,p3,p4,p5};unsigned char *bytes=out;memcpy(bytes+0,&v0,16);memcpy(bytes+16,&v1,16);memcpy(bytes+32,&v2,16);memcpy(bytes+48,&v3,16);uint64_t value=checksum(args,last);memcpy(bytes+64,&value,8);return value;}
static uint64_t fp_piece_direct_1(void *out,const void *a,const void *b,uint64_t salt){fp_pair values[4];memset(values,0,sizeof values);memcpy(&values[0],(const unsigned char *)a+0,16);memcpy(&values[1],(const unsigned char *)a+16,16);memcpy(&values[2],(const unsigned char *)b+0,16);memcpy(&values[3],(const unsigned char *)b+16,16);return fp_piece_body_1(prefix(0,salt),prefix(1,salt),prefix(2,salt),prefix(3,salt),prefix(4,salt),prefix(5,salt),values[0],values[1],values[2],values[3],tail(salt),out);}
extern uint64_t fp_piece_body_2(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,__float128 v0,__float128 v1,__float128 v2,__float128 v3,__float128 v4,__float128 v5,__float128 v6,__float128 v7,uint64_t last,void *out);
extern uint64_t fp_piece_probe_2(void *,const void *,const void *,uint64_t);
uint64_t fp_piece_provider_2(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,__float128 v0,__float128 v1,__float128 v2,__float128 v3,__float128 v4,__float128 v5,__float128 v6,__float128 v7,uint64_t last,void *out){uint64_t args[]={p0,p1,p2,p3,p4,p5};unsigned char *bytes=out;memcpy(bytes+0,&v0,16);memcpy(bytes+16,&v1,16);memcpy(bytes+32,&v2,16);memcpy(bytes+48,&v3,16);memcpy(bytes+64,&v4,16);memcpy(bytes+80,&v5,16);memcpy(bytes+96,&v6,16);memcpy(bytes+112,&v7,16);uint64_t value=checksum(args,last);memcpy(bytes+128,&value,8);return value;}
static uint64_t fp_piece_direct_2(void *out,const void *a,const void *b,uint64_t salt){__float128 values[8];memset(values,0,sizeof values);memcpy(&values[0],(const unsigned char *)a+0,16);memcpy(&values[1],(const unsigned char *)a+16,16);memcpy(&values[2],(const unsigned char *)a+32,16);memcpy(&values[3],(const unsigned char *)a+48,16);memcpy(&values[4],(const unsigned char *)b+0,16);memcpy(&values[5],(const unsigned char *)b+16,16);memcpy(&values[6],(const unsigned char *)b+32,16);memcpy(&values[7],(const unsigned char *)b+48,16);return fp_piece_body_2(prefix(0,salt),prefix(1,salt),prefix(2,salt),prefix(3,salt),prefix(4,salt),prefix(5,salt),values[0],values[1],values[2],values[3],values[4],values[5],values[6],values[7],tail(salt),out);}
extern uint64_t fp_piece_body_3(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,__float128 v0,__float128 v1,__float128 v2,__float128 v3,__float128 v4,__float128 v5,__float128 v6,__float128 v7,uint64_t last,void *out);
extern uint64_t fp_piece_probe_3(void *,const void *,const void *,uint64_t);
uint64_t fp_piece_provider_3(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,__float128 v0,__float128 v1,__float128 v2,__float128 v3,__float128 v4,__float128 v5,__float128 v6,__float128 v7,uint64_t last,void *out){uint64_t args[]={p0,p1,p2,p3,p4,p5};unsigned char *bytes=out;memcpy(bytes+0,&v0,16);memcpy(bytes+16,&v1,16);memcpy(bytes+32,&v2,16);memcpy(bytes+48,&v3,16);memcpy(bytes+64,&v4,16);memcpy(bytes+80,&v5,16);memcpy(bytes+96,&v6,16);memcpy(bytes+112,&v7,16);uint64_t value=checksum(args,last);memcpy(bytes+128,&value,8);return value;}
static uint64_t fp_piece_direct_3(void *out,const void *a,const void *b,uint64_t salt){__float128 values[8];memset(values,0,sizeof values);memcpy(&values[0],(const unsigned char *)a+0,16);memcpy(&values[1],(const unsigned char *)a+16,16);memcpy(&values[2],(const unsigned char *)a+32,16);memcpy(&values[3],(const unsigned char *)a+48,16);memcpy(&values[4],(const unsigned char *)b+0,16);memcpy(&values[5],(const unsigned char *)b+16,16);memcpy(&values[6],(const unsigned char *)b+32,16);memcpy(&values[7],(const unsigned char *)b+48,16);return fp_piece_body_3(prefix(0,salt),prefix(1,salt),prefix(2,salt),prefix(3,salt),prefix(4,salt),prefix(5,salt),values[0],values[1],values[2],values[3],values[4],values[5],values[6],values[7],tail(salt),out);}
extern uint64_t fp_piece_body_4(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,long double v0,long double v1,long double v2,long double v3,long double v4,long double v5,long double v6,long double v7,uint64_t last,void *out);
extern uint64_t fp_piece_probe_4(void *,const void *,const void *,uint64_t);
uint64_t fp_piece_provider_4(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,long double v0,long double v1,long double v2,long double v3,long double v4,long double v5,long double v6,long double v7,uint64_t last,void *out){uint64_t args[]={p0,p1,p2,p3,p4,p5};unsigned char *bytes=out;memcpy(bytes+0,&v0,10);memcpy(bytes+10,&v1,10);memcpy(bytes+20,&v2,10);memcpy(bytes+30,&v3,10);memcpy(bytes+40,&v4,10);memcpy(bytes+50,&v5,10);memcpy(bytes+60,&v6,10);memcpy(bytes+70,&v7,10);uint64_t value=checksum(args,last);memcpy(bytes+80,&value,8);return value;}
static uint64_t fp_piece_direct_4(void *out,const void *a,const void *b,uint64_t salt){long double values[8];memset(values,0,sizeof values);memcpy(&values[0],(const unsigned char *)a+0,10);memcpy(&values[1],(const unsigned char *)a+10,10);memcpy(&values[2],(const unsigned char *)a+20,10);memcpy(&values[3],(const unsigned char *)a+30,10);memcpy(&values[4],(const unsigned char *)b+0,10);memcpy(&values[5],(const unsigned char *)b+10,10);memcpy(&values[6],(const unsigned char *)b+20,10);memcpy(&values[7],(const unsigned char *)b+30,10);return fp_piece_body_4(prefix(0,salt),prefix(1,salt),prefix(2,salt),prefix(3,salt),prefix(4,salt),prefix(5,salt),values[0],values[1],values[2],values[3],values[4],values[5],values[6],values[7],tail(salt),out);}
extern uint64_t fp_piece_body_5(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,long double v0,long double v1,long double v2,long double v3,long double v4,long double v5,long double v6,long double v7,uint64_t last,void *out);
extern uint64_t fp_piece_probe_5(void *,const void *,const void *,uint64_t);
uint64_t fp_piece_provider_5(uint64_t p0,uint64_t p1,uint64_t p2,uint64_t p3,uint64_t p4,uint64_t p5,long double v0,long double v1,long double v2,long double v3,long double v4,long double v5,long double v6,long double v7,uint64_t last,void *out){uint64_t args[]={p0,p1,p2,p3,p4,p5};unsigned char *bytes=out;memcpy(bytes+0,&v0,10);memcpy(bytes+10,&v1,10);memcpy(bytes+20,&v2,10);memcpy(bytes+30,&v3,10);memcpy(bytes+40,&v4,10);memcpy(bytes+50,&v5,10);memcpy(bytes+60,&v6,10);memcpy(bytes+70,&v7,10);uint64_t value=checksum(args,last);memcpy(bytes+80,&value,8);return value;}
static uint64_t fp_piece_direct_5(void *out,const void *a,const void *b,uint64_t salt){long double values[8];memset(values,0,sizeof values);memcpy(&values[0],(const unsigned char *)a+0,10);memcpy(&values[1],(const unsigned char *)a+10,10);memcpy(&values[2],(const unsigned char *)a+20,10);memcpy(&values[3],(const unsigned char *)a+30,10);memcpy(&values[4],(const unsigned char *)b+0,10);memcpy(&values[5],(const unsigned char *)b+10,10);memcpy(&values[6],(const unsigned char *)b+20,10);memcpy(&values[7],(const unsigned char *)b+30,10);return fp_piece_body_5(prefix(0,salt),prefix(1,salt),prefix(2,salt),prefix(3,salt),prefix(4,salt),prefix(5,salt),values[0],values[1],values[2],values[3],values[4],values[5],values[6],values[7],tail(salt),out);}
static const struct test_case cases[]={
{fp_piece_probe_0,fp_piece_direct_0,8},
{fp_piece_probe_1,fp_piece_direct_1,8},
{fp_piece_probe_2,fp_piece_direct_2,16},
{fp_piece_probe_3,fp_piece_direct_3,16},
{fp_piece_probe_4,fp_piece_direct_4,10},
{fp_piece_probe_5,fp_piece_direct_5,10},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
