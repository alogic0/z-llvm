#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef unsigned __int128 u128;
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
typedef uint64_t (*physical)(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,u128,void *);
struct test_case{kernel probe;physical body;unsigned bits;};
static u128 reverse(u128 raw,unsigned bits){u128 answer=0;for(unsigned i=0;i<bits;i++)answer=(answer<<1)|((raw>>i)&1);return answer;}
static int payload(const unsigned char *p,u128 expected,unsigned bits){u128 actual=0;memcpy(&actual,p,(bits+7)/8);return (actual&(((u128)1<<bits)-1))==expected;}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE),observations=0;unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<512;seed++){
  unsigned bits=cases[which].bits,extent=(bits+7)/8;uint64_t words[6];for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x9182736455aaccdd)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));u128 raw=(u128)words[0]|((u128)words[1]<<64);if(seed<128)raw=(u128)1<<seed;else if(seed<256)raw=~((u128)1<<(seed-128));u128 expected=reverse(raw,bits);uint64_t checksum=(uint64_t)expected^(uint64_t)(expected>>64),salt=words[5]^seed;for(unsigned i=0;i<6;i++)checksum=checksum*UINT64_C(1099511628211)^words[i];unsigned char *input=map+2*page-48-extent,saved[64],out[72];memcpy(input,words,48);memcpy(input+48,&raw,extent);memcpy(saved,input,48+extent);memset(out,0xa5,sizeof out);uint64_t answer=cases[which].body(words[0],words[1],words[2],words[3],words[4],words[5],raw,out+16);
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"odd-pair-bitreverse case=%zu bits=%u seed=%u observation=%zu fault=%u\n",which,bits,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==checksum);CHECK(payload(out+16,expected,bits));unsigned pre=0,post=0;for(unsigned i=0;i<16;i++)pre|=out[i]^0xa5;for(unsigned i=16+extent;i<sizeof out;i++)post|=out[i]^0xa5;CHECK(pre==0);CHECK(post==0);
  memset(out,0xa5,sizeof out);answer=cases[which].probe(input,out+16,salt);if(fault==1)out[16]^=1;if(fault==2)answer^=1;if(fault==3)out[16+extent+24]^=1;uint64_t tail[3];memcpy(tail,out+16+extent,24);CHECK(answer==(checksum^salt));CHECK(payload(out+16,expected,bits));CHECK(tail[0]==checksum);CHECK(tail[1]==salt);CHECK(tail[2]==words[0]);pre=post=0;for(unsigned i=0;i<16;i++){pre|=out[i]^0xa5;post|=out[16+extent+24+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,48+extent)==0);
#undef CHECK
 }
 printf("odd-pair-bitreverse observations=%zu independent-bit-loop=all-basis-bits=dirty-upper-bits=exact-tails=c-direct-entry=live-aliases=stack-calls=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;
}
