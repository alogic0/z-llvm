#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
extern uint64_t lifetime_sequential(uint64_t);
extern uint64_t lifetime_branches(uint64_t);
static unsigned fault;
static size_t observations;
static int failed;
void lifetime_fill(unsigned char *p,uint64_t seed) {
 for(unsigned i=0;i<8192;i++) p[i]=(unsigned char)(i*13+(i>>3)+seed*7);
}
uint64_t lifetime_check(const unsigned char *p,uint64_t seed) {
 uint64_t bad=0;
 for(unsigned i=0;i<8192;i++) bad|=p[i]^(unsigned char)(i*13+(i>>3)+seed*7);
 return bad;
}
#define CHECK(c) do { ++observations; if(!(c)) { failed=1; fprintf(stderr,"stack-lifetimes fault=%u observation=%zu\n",fault,observations); return NULL; } } while(0)
static void *worker(void *unused) {
 (void)unused;
 for(unsigned i=0;i<32;i++) for(unsigned route=0;route<2;route++) {
  struct { uint64_t pre[2],result,post[2]; } out;
  memset(&out,0xa5,sizeof(out));
  out.result=route ? lifetime_branches(i*17) : lifetime_sequential(i*17);
  if(fault==1) out.result^=1;
  if(fault==2) out.pre[0]^=1;
  if(fault==3) out.post[1]^=1;
  CHECK(out.result==0);
  CHECK(out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0]);
  CHECK(out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]);
 }
 return NULL;
}
int main(int argc,char **argv) {
 fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
 pthread_attr_t attr;
 pthread_t thread;
 if(pthread_attr_init(&attr)||pthread_attr_setstacksize(&attr,65536)||
    pthread_create(&thread,&attr,worker,NULL)||pthread_join(thread,NULL)) return 2;
 pthread_attr_destroy(&attr);
 if(failed) return 1;
 printf("stack-lifetimes observations=%zu stack=65536 full-objects=branches=loops=guards=preserved\n",observations);
 return 0;
}
