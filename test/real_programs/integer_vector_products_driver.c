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
extern uint64_t integer_vector_product_8_1_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_1_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_2_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_2_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_3_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_3_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_4_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_4_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_8_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_8_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_16_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_16_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_64_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_8_64_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_1_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_1_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_2_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_2_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_3_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_3_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_4_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_4_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_8_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_8_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_16_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_16_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_64_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_16_64_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_1_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_1_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_2_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_2_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_3_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_3_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_4_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_4_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_8_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_8_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_16_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_16_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_64_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_24_64_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_1_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_1_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_2_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_2_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_3_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_3_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_4_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_4_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_8_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_8_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_16_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_16_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_64_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_32_64_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_1_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_1_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_2_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_2_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_3_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_3_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_4_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_4_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_8_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_8_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_16_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_16_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_64_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_48_64_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_1_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_1_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_2_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_2_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_3_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_3_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_4_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_4_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_8_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_8_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_16_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_16_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_64_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_64_64_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_1_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_1_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_2_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_2_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_3_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_3_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_4_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_4_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_8_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_8_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_16_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_16_1(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_64_0(void *,const void *,uint64_t);
extern uint64_t integer_vector_product_128_64_1(void *,const void *,uint64_t);
static const struct test_case cases[]={
{integer_vector_product_8_1_0,8,1},
{integer_vector_product_8_1_1,8,1},
{integer_vector_product_8_2_0,8,2},
{integer_vector_product_8_2_1,8,2},
{integer_vector_product_8_3_0,8,3},
{integer_vector_product_8_3_1,8,3},
{integer_vector_product_8_4_0,8,4},
{integer_vector_product_8_4_1,8,4},
{integer_vector_product_8_8_0,8,8},
{integer_vector_product_8_8_1,8,8},
{integer_vector_product_8_16_0,8,16},
{integer_vector_product_8_16_1,8,16},
{integer_vector_product_8_64_0,8,64},
{integer_vector_product_8_64_1,8,64},
{integer_vector_product_16_1_0,16,1},
{integer_vector_product_16_1_1,16,1},
{integer_vector_product_16_2_0,16,2},
{integer_vector_product_16_2_1,16,2},
{integer_vector_product_16_3_0,16,3},
{integer_vector_product_16_3_1,16,3},
{integer_vector_product_16_4_0,16,4},
{integer_vector_product_16_4_1,16,4},
{integer_vector_product_16_8_0,16,8},
{integer_vector_product_16_8_1,16,8},
{integer_vector_product_16_16_0,16,16},
{integer_vector_product_16_16_1,16,16},
{integer_vector_product_16_64_0,16,64},
{integer_vector_product_16_64_1,16,64},
{integer_vector_product_24_1_0,24,1},
{integer_vector_product_24_1_1,24,1},
{integer_vector_product_24_2_0,24,2},
{integer_vector_product_24_2_1,24,2},
{integer_vector_product_24_3_0,24,3},
{integer_vector_product_24_3_1,24,3},
{integer_vector_product_24_4_0,24,4},
{integer_vector_product_24_4_1,24,4},
{integer_vector_product_24_8_0,24,8},
{integer_vector_product_24_8_1,24,8},
{integer_vector_product_24_16_0,24,16},
{integer_vector_product_24_16_1,24,16},
{integer_vector_product_24_64_0,24,64},
{integer_vector_product_24_64_1,24,64},
{integer_vector_product_32_1_0,32,1},
{integer_vector_product_32_1_1,32,1},
{integer_vector_product_32_2_0,32,2},
{integer_vector_product_32_2_1,32,2},
{integer_vector_product_32_3_0,32,3},
{integer_vector_product_32_3_1,32,3},
{integer_vector_product_32_4_0,32,4},
{integer_vector_product_32_4_1,32,4},
{integer_vector_product_32_8_0,32,8},
{integer_vector_product_32_8_1,32,8},
{integer_vector_product_32_16_0,32,16},
{integer_vector_product_32_16_1,32,16},
{integer_vector_product_32_64_0,32,64},
{integer_vector_product_32_64_1,32,64},
{integer_vector_product_48_1_0,48,1},
{integer_vector_product_48_1_1,48,1},
{integer_vector_product_48_2_0,48,2},
{integer_vector_product_48_2_1,48,2},
{integer_vector_product_48_3_0,48,3},
{integer_vector_product_48_3_1,48,3},
{integer_vector_product_48_4_0,48,4},
{integer_vector_product_48_4_1,48,4},
{integer_vector_product_48_8_0,48,8},
{integer_vector_product_48_8_1,48,8},
{integer_vector_product_48_16_0,48,16},
{integer_vector_product_48_16_1,48,16},
{integer_vector_product_48_64_0,48,64},
{integer_vector_product_48_64_1,48,64},
{integer_vector_product_64_1_0,64,1},
{integer_vector_product_64_1_1,64,1},
{integer_vector_product_64_2_0,64,2},
{integer_vector_product_64_2_1,64,2},
{integer_vector_product_64_3_0,64,3},
{integer_vector_product_64_3_1,64,3},
{integer_vector_product_64_4_0,64,4},
{integer_vector_product_64_4_1,64,4},
{integer_vector_product_64_8_0,64,8},
{integer_vector_product_64_8_1,64,8},
{integer_vector_product_64_16_0,64,16},
{integer_vector_product_64_16_1,64,16},
{integer_vector_product_64_64_0,64,64},
{integer_vector_product_64_64_1,64,64},
{integer_vector_product_128_1_0,128,1},
{integer_vector_product_128_1_1,128,1},
{integer_vector_product_128_2_0,128,2},
{integer_vector_product_128_2_1,128,2},
{integer_vector_product_128_3_0,128,3},
{integer_vector_product_128_3_1,128,3},
{integer_vector_product_128_4_0,128,4},
{integer_vector_product_128_4_1,128,4},
{integer_vector_product_128_8_0,128,8},
{integer_vector_product_128_8_1,128,8},
{integer_vector_product_128_16_0,128,16},
{integer_vector_product_128_16_1,128,16},
{integer_vector_product_128_64_0,128,64},
{integer_vector_product_128_64_1,128,64},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
