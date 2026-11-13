#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
typedef uint64_t (*physical)(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,void *);
struct test_case{kernel probe;physical body;unsigned masks_first;};
static unsigned packed(const uint64_t *bits){return (bits[0]&1)|((bits[1]&1)<<1)|((bits[2]&1)<<2);}
static uint64_t model(const uint64_t *words,const uint64_t *bits){uint64_t result=packed(bits)|(packed(bits+3)<<3);for(unsigned i=0;i<6;i++)result=result*UINT64_C(1099511628211)^words[i];return result;}
static uint64_t provider(const uint64_t *words,const uint64_t *bits,void *out){unsigned char *p=out;p[26]=packed(bits);p[27]=packed(bits+3);return model(words,bits);}
static uint64_t direct(physical body,unsigned first,const uint64_t *w,const uint64_t *b,void *out){if(first)return body(b[0],b[1],b[2],b[3],b[4],b[5],w[0],w[1],w[2],w[3],w[4],w[5],out);return body(w[0],w[1],w[2],w[3],w[4],w[5],b[0],b[1],b[2],b[3],b[4],b[5],out);}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  uint64_t words[6],bits[6];for(unsigned i=0;i<6;i++){words[i]=UINT64_C(0x9182736455aaccdd)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));bits[i]=(words[(i+1)%6]&~UINT64_C(1))|((seed>>i)&1);}
  unsigned a=packed(bits),b=packed(bits+3);uint64_t expected=model(words,bits),salt=words[0]^words[5];unsigned char out[60],*input=map+2*page-50,saved[50];memcpy(input,words,48);input[48]=a|0xf8;input[49]=b|0xf8;memcpy(saved,input,50);memset(out,0xa5,sizeof out);uint64_t answer=direct(cases[which].body,cases[which].masks_first,words,bits,out+16);
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"mask3-input case=%zu seed=%u observation=%zu fault=%u\n",which,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==expected);CHECK((out[40]&7)==a);CHECK((out[41]&7)==b);unsigned unchanged=0,pre=0,post=0;for(unsigned i=16;i<40;i++)unchanged|=out[i]^0xa5;unchanged|=out[42]^0xa5;unchanged|=out[43]^0xa5;CHECK(unchanged==0);for(unsigned i=0;i<16;i++){pre|=out[i]^0xa5;post|=out[44+i]^0xa5;}CHECK(pre==0);CHECK(post==0);
  memset(out,0xa5,sizeof out);answer=cases[which].probe(input,out+16,salt);if(fault==1)out[16]^=1;if(fault==2)answer^=1;if(fault==3)out[44]^=1;uint64_t data[3];memcpy(data,out+16,24);CHECK(answer==(expected^salt));CHECK(data[0]==expected);CHECK(data[1]==expected);CHECK(data[2]==words[0]);CHECK((out[40]&7)==a);CHECK((out[41]&7)==b);CHECK((out[42]&7)==a);CHECK((out[43]&7)==b);pre=post=0;for(unsigned i=0;i<16;i++){pre|=out[i]^0xa5;post|=out[44+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,50)==0);
#undef CHECK
 }
 printf("mask3-input observations=%zu c-direct-entry=external-provider=dirty-carriers=packed-bits=live-aliases=stack-calls=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;
}
