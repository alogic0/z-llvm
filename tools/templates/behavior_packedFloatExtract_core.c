#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case{kernel run;uint32_t *global;unsigned literal;};
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE),observations=0;unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
 static const uint32_t payloads[]={0,0x80000000,1,0x007fffff,0x00800000,0x3f800000,0xbf800000,0x7f800000,0xff800000,0x7fc12345,0x7f812345,0xffffffff,0x3f000001,0xffcabcde};
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  const struct test_case *c=&cases[which];uint64_t words[6];for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x9182736455aaccdd)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));uint32_t raw[2]={payloads[seed%(sizeof payloads/sizeof payloads[0])],payloads[(seed*3+5)%(sizeof payloads/sizeof payloads[0])]},expected[2]={c->literal?0:raw[0],c->literal?0x3f800000:raw[1]};unsigned char *input=map+2*page-56,saved[56],out[64];memcpy(input,words,48);memcpy(input+48,raw,8);memcpy(saved,input,56);memset(out,0xa5,sizeof out);c->global[0]=0xdeadbeef;c->global[1]=0xaabbccdd;
  uint64_t checksum=(uint64_t)expected[0]|((uint64_t)expected[1]<<32),salt=words[5]^seed;for(unsigned i=0;i<6;i++)checksum=checksum*UINT64_C(1099511628211)^words[i];uint64_t answer=c->run(input,out+16,salt),tail[3];memcpy(tail,out+24,24);if(fault==1)out[16]^=1;if(fault==2)answer^=1;if(fault==3)out[48]^=1;
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"packed-float-extract case=%zu seed=%u observation=%zu fault=%u\n",which,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(checksum^salt));CHECK(memcmp(out+16,expected,8)==0);CHECK(tail[0]==checksum);CHECK(tail[1]==salt);CHECK(tail[2]==words[0]);CHECK(c->global[0]==expected[1]);CHECK(c->global[1]==expected[0]);unsigned pre=0,post=0;for(unsigned i=0;i<16;i++){pre|=out[i]^0xa5;post|=out[48+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,56)==0);
#undef CHECK
 }
 printf("packed-float-extract observations=%zu exact-eight-byte-storage=literal-lanes=all-payload-moves=global-roundtrip=live-aliases=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;
}
