#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case{kernel run;unsigned lanes;};
static const uint64_t constants[]={0,1,UINT64_MAX,UINT64_C(0x8000000000000000),UINT64_C(4294967295),UINT64_C(0x123456789abcdef0)};
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE),observations=0;unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  unsigned n=cases[which].lanes,used=48+n*8,extent=n*24;unsigned char *input=map+2*page-used,saved[560],out[1600];uint64_t words[6],expected[64],literal[64];
  for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x9182736455aaccdd)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));memcpy(input,words,48);
  for(unsigned i=0;i<n;i++){expected[i]=words[i%6]^(i*UINT64_C(0xfedcba9876543211));if(seed<6)expected[i]=constants[(i+seed)%6];literal[i]=constants[i%6];}memcpy(input+48,expected,n*8);memcpy(saved,input,used);
  uint64_t checksum=0,salt=words[5]^seed;for(unsigned i=0;i<6;i++)checksum=checksum*UINT64_C(1099511628211)^words[i];memset(out,0xa5,sizeof out);uint64_t answer=cases[which].run(input,out+16,salt),tail[3];memcpy(tail,out+16+extent,24);
  if(fault==1)out[16]^=1;if(fault==2)answer^=1;if(fault==3)out[16+extent+24]^=1;
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"pointer-constants case=%zu n=%u seed=%u observation=%zu fault=%u\n",which,n,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(checksum^salt));CHECK(memcmp(out+16,expected,n*8)==0);CHECK(memcmp(out+16+n*8,literal,n*8)==0);CHECK(memcmp(out+16+n*16,literal,n*8)==0);for(unsigned i=0;i<3;i++)CHECK(tail[i]==(i==0?checksum:i==1?salt:words[0]));unsigned pre=0,post=0;for(unsigned i=0;i<16;i++){pre|=out[i]^0xa5;post|=out[16+extent+24+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,used)==0);
#undef CHECK
 }
 printf("pointer-constants observations=%zu exact-pointer-bits=literal-vectors=inserted-lanes=live-aliases=stack-calls=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;
}
