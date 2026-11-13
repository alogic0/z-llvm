#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,uint64_t);
struct test_case {kernel run;unsigned bits,lanes;};
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *maps[2];
 for(unsigned i=0;i<2;i++){maps[i]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(maps[i]==MAP_FAILED||mprotect(maps[i]+page,page,PROT_READ|PROT_WRITE))return 2;}
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  unsigned bits=cases[which].bits,bytes=bits/8,lanes=cases[which].lanes;size_t size=lanes*bytes;
  unsigned char *input=maps[0]+2*page-size,*out=maps[1]+2*page-bytes-8,saved[1024],guard[8];memset(guard,0xa5,8);memset(out-8,0xa5,bytes+16);
  __uint128_t mask=~(__uint128_t)0>>(128-bits),expected=1;
  for(unsigned lane=0;lane<lanes;lane++){__uint128_t value=seed==0?0:seed==1?mask:((((__uint128_t)seed*UINT64_C(0x9182736455aaccdd))<<64)^((__uint128_t)lane*UINT64_C(0x123456789abcdef1))^seed)&mask;if(seed==2)value=3;expected=(expected*value)&mask;memcpy(input+lane*bytes,&value,bytes);}
  memcpy(saved,input,size);uint64_t salt=seed*UINT64_C(0x9182736455aaccdd),answer=cases[which].run(out,input,salt);if(fault==1)out[0]^=1;if(fault==2)answer^=1;if(fault==3)out[bytes]^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"vector-product bits=%u lanes=%u seed=%u observation=%zu fault=%u\n",bits,lanes,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(salt^90));CHECK(memcmp(out,&expected,bytes)==0);CHECK(memcmp(out-8,guard,8)==0);CHECK(memcmp(out+bytes,guard,8)==0);CHECK(memcmp(input,saved,size)==0);
#undef CHECK
 }
 for(unsigned i=0;i<2;i++)if(munmap(maps[i],page*3))return 2;
 printf("integer-vector-products observations=%zu seven-widths=modular-c-model=one-to-sixty-four-lanes=exact-stores=guard-pages=preserved\n",observations);return 0;
}
