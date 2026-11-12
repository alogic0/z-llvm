#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

extern uint64_t spill_waves(uint64_t *, uint64_t);
enum { WAVES=512, SEEDS=8 };
struct context {
 uint64_t seed,expected,result;
 struct { uint64_t pre[2],value,post[2]; } out;
 size_t calls,observations;
 unsigned failed;
};
static _Thread_local struct context *active;
#define CHECK(ctx,condition) do { ++(ctx)->observations; if(!(condition)) (ctx)->failed=1; } while(0)

uint64_t spill_observe(uint64_t a,uint64_t b,uint64_t c,uint64_t d,
 uint64_t e,uint64_t f,uint64_t g,uint64_t h,uint64_t wave,uint64_t seed) {
 struct context *ctx=active;
 uint64_t index=ctx->calls++,values[8]={a,b,c,d,e,f,g,h};
 CHECK(ctx,wave==index);
 CHECK(ctx,seed==ctx->seed);
 CHECK(ctx,ctx->out.value==ctx->expected);
 for(unsigned lane=0;lane<8;lane++) CHECK(ctx,values[lane]==seed+17+index*29+lane*131);
 uint64_t ticket=seed^(index*UINT64_C(0xd6e8feb86659fd93));
 ticket=(ticket<<7)|(ticket>>57);
 for(unsigned lane=0;lane<16;lane++) ctx->expected+=(seed+17+index*29+lane*131)^ticket;
 return ticket;
}
static void *worker(void *argument) {
 struct context *ctx=argument;
 active=ctx;
 ctx->result=spill_waves(&ctx->out.value,ctx->seed);
 return NULL;
}
int main(int argc,char **argv) {
 const unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
 size_t observations=0;
 for(unsigned seed=0;seed<SEEDS;seed++) {
  struct context ctx;
  memset(&ctx,0,sizeof(ctx));
  memset(&ctx.out,0xa5,sizeof(ctx.out));
  ctx.seed=seed*UINT64_C(0x9e3779b97f4a7c15);
  ctx.expected=ctx.seed^23;
  pthread_attr_t attr;
  pthread_t thread;
  if(pthread_attr_init(&attr)!=0 || pthread_attr_setstacksize(&attr,65536)!=0) return 1;
  if(pthread_create(&thread,&attr,worker,&ctx)!=0) return 1;
  pthread_attr_destroy(&attr);
  if(pthread_join(thread,NULL)!=0) return 1;
  if(fault==1) ctx.result^=1;
  if(fault==2) ctx.out.pre[0]^=1;
  if(fault==3) ctx.out.post[1]^=1;
  CHECK(&ctx,ctx.calls==WAVES);
  CHECK(&ctx,ctx.result==ctx.expected);
  CHECK(&ctx,ctx.out.value==ctx.expected);
  CHECK(&ctx,ctx.out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&ctx.out.pre[1]==ctx.out.pre[0]);
  CHECK(&ctx,ctx.out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&ctx.out.post[1]==ctx.out.post[0]);
  if(ctx.failed) { fprintf(stderr,"stack-spill-homes seed=%u fault=%u observations=%zu\n",seed,fault,ctx.observations); return 1; }
  observations+=ctx.observations;
 }
 printf("stack-spill-homes observations=%zu stack=65536 waves=512 live=16 calls=guards=preserved\n",observations);
 return 0;
}
