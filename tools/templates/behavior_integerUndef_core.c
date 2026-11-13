#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case{kernel run;unsigned kind,bits,to;};
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE),observations=0;
 unsigned char *im=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0),*om=mmap(0,page*4,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(im==MAP_FAILED||om==MAP_FAILED||mprotect(im+page,page,PROT_READ|PROT_WRITE)||mprotect(om+page,page*2,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  const struct test_case *c=&cases[which];unsigned extent=((c->kind==2?c->bits:c->to)+7)/8;if(extent+64>page*2)return 2;uint64_t words[6];for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x9182736455aaccdd)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));unsigned char *input=im+2*page-48,*out=om+3*page-16-32-extent,saved[48];memcpy(input,words,48);memcpy(saved,input,48);memset(out-16,0xa5,extent+64);
  uint64_t checksum=words[4],salt=words[5]^seed;for(unsigned i=0;i<6;i++)checksum=checksum*UINT64_C(1099511628211)^words[i];uint64_t answer=c->run(input,out,salt);if(fault==1){if(c->kind==2)out[0]^=1;else{uint64_t invalid=UINT64_C(1)<<(c->kind==1?c->bits-1:c->bits);memcpy(out,&invalid,extent);}}if(fault==2)answer^=1;if(fault==3)out[extent+32]^=1;
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"integer-undef case=%zu kind=%u bits=%u to=%u seed=%u observation=%zu fault=%u\n",which,c->kind,c->bits,c->to,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(checksum^salt));if(c->kind==2){uint64_t first,last;memcpy(&first,out,8);memcpy(&last,out+extent-8,8);CHECK(first==words[0]);CHECK(last==words[1]);}else{uint64_t value=0;memcpy(&value,out,extent);if(c->kind==1){int64_t signed_value;if(c->to==64)memcpy(&signed_value,&value,8);else{signed_value=(int64_t)value;if(value&(UINT64_C(1)<<(c->to-1)))signed_value-=INT64_C(1)<<c->to;}CHECK(signed_value>=-(INT64_C(1)<<(c->bits-1))&&signed_value<=(INT64_C(1)<<(c->bits-1))-1);}else CHECK(value<=((UINT64_C(1)<<c->bits)-1));}
  uint64_t marker,tail[3];memcpy(&marker,out+extent,8);memcpy(tail,out+extent+8,24);CHECK(marker==words[4]);CHECK(tail[0]==checksum);CHECK(tail[1]==salt);CHECK(tail[2]==words[0]);unsigned pre=0,post=0;for(unsigned i=0;i<16;i++){pre|=out[(int)i-16]^0xa5;post|=out[extent+32+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,48)==0);
#undef CHECK
 }
 printf("integer-undef observations=%zu refinement-domains=defined-endpoints=guard-pages=live-aliases=client-request-marker=preserved\n",observations);if(munmap(im,page*3)||munmap(om,page*4))return 2;return 0;
}
