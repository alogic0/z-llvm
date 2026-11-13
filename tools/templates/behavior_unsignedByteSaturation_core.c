#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case { kernel run; unsigned bits,lanes,subtract,literal; };
static void put_bits(unsigned char *p,unsigned offset,unsigned count,uint64_t value){for(unsigned i=0;i<count;i++){unsigned bit=offset+i;p[bit/8]=(p[bit/8]&~(1u<<(bit%8)))|(((value>>i)&1u)<<(bit%8));}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  const struct test_case *c=&cases[which];unsigned extent=(c->bits*c->lanes+7)/8,used=48+extent*2;unsigned char *input=map+2*page-used,saved[112],expected[32]={0};
  uint64_t mask=(UINT64_C(1)<<c->bits)-1,words[6];for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x9123456789abcdef)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));
  memcpy(input,words,48);memset(input+48,0xa5,extent*2);
  for(unsigned lane=0;lane<c->lanes;lane++){
   uint64_t edge[]={0,1,mask,mask-1,mask/2,mask/2+1,mask/2+2,2};unsigned k=(seed+lane)%8;
   uint64_t a=seed<32?edge[k]:(words[lane%6]&mask),b=seed<32?edge[(seed/8+lane*3)%8]:((words[(lane+1)%6]>>1)&mask);
   put_bits(input+48,lane*c->bits,c->bits,a);put_bits(input+48+extent,lane*c->bits,c->bits,b);
   if(c->literal==1)a=mask;if(c->literal==2)b=mask;
   __uint128_t mathematical=c->subtract?(a>=b?(__uint128_t)a-b:0):(__uint128_t)a+b;
   uint64_t value=mathematical>mask?mask:(uint64_t)mathematical;put_bits(expected,lane*c->bits,c->bits,value);
  }
  memcpy(saved,input,used);uint64_t salt=UINT64_C(0x9182736455aaccdd)^seed,checksum=0;for(unsigned i=0;i<6;i++)checksum=checksum*UINT64_C(1099511628211)^words[i];
  unsigned char output[88];memset(output,0xa5,sizeof output);uint64_t answer=c->run(input,output+16,salt),tail[3];memcpy(tail,output+16+extent,24);
  if(fault==1)output[16]^=1;if(fault==2)answer^=1;if(fault==3)output[16+extent+24]^=1;
  unsigned tail_bits=(c->bits*c->lanes)%8;if(tail_bits)output[16+extent-1]&=(1u<<tail_bits)-1;
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"unsigned-odd-saturation case=%zu bits=%u lanes=%u seed=%u observation=%zu fault=%u\n",which,c->bits,c->lanes,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(checksum^salt));CHECK(memcmp(output+16,expected,extent)==0);CHECK(tail[0]==checksum);CHECK(tail[1]==salt);CHECK(tail[2]==words[0]);
  unsigned pre=0,post=0;for(unsigned i=0;i<16;i++){pre|=output[i]^0xa5;post|=output[16+extent+24+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,used)==0);
#undef CHECK
 }
 printf("unsigned-odd-saturation observations=%zu integer-clamp-model=packed-vectors=literal-modes=live-aliases=stack-calls=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;
}
