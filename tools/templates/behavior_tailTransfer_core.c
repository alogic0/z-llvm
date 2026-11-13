#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case {kernel run;unsigned a_bits,b_bits,return_kind,signed_return,deep;};
__attribute__((noinline)) uint64_t tail_transfer_clobber(const volatile uint64_t *local,uint64_t a,uint64_t b,uint64_t count,uint64_t tag,uint64_t p,uint64_t q,uint64_t r,uint64_t s,uint64_t t){
    __asm__ volatile("" ::: "rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","memory");
    return *local^(a*3)^(b*5)^count^tag^(p+q+r+s+t);
}
static uint64_t mask(unsigned bits){return bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1;}
static uint64_t random_word(uint64_t *state){*state^=*state<<13;*state^=*state>>7;*state^=*state<<17;return *state;}
static void model(const struct test_case *test,const uint64_t *input,uint64_t count,uint64_t out[4]){
    uint64_t a=input[0]&mask(test->a_bits),b=input[1]&mask(test->b_bits);unsigned tag=1;
    while(count){
        uint64_t probe=(count+tag*17)^(a*3)^(b*5)^count^tag^25;
        uint64_t next_a=tag==1?a+17+probe:b^probe,next_b=tag==1?b^a:a+31;
        a=next_a&mask(test->a_bits);b=next_b&mask(test->b_bits);tag=3-tag;count--;
    }
    out[0]=a;out[1]=b;out[2]=(a*UINT64_C(1099511628211))^b;out[3]=tag;
}
struct workload {const struct test_case *cases;size_t count;unsigned fault;};
static void *worker(void *opaque){
    struct workload *work=opaque;size_t page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *mapping=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(mapping==MAP_FAILED)return (void *)2;uint64_t *input=(uint64_t *)(mapping+2*page-64);uint64_t state=UINT64_C(0x89abc012340567ef);size_t observations=0;
    const uint64_t counts[]={0,1,2,3,7,31,257,4097,8191,65537};
    for(size_t k=0;k<work->count;k++)for(unsigned seed=0;seed<10;seed++){
        const struct test_case *test=&work->cases[k];uint64_t saved[8],expected[4],out[6]={UINT64_C(0xa55a11223344eeff),0,0,0,0,UINT64_C(0x778899001122a55a)};
        if(mprotect(mapping+page,page,PROT_READ|PROT_WRITE))return (void *)2;
        for(unsigned i=0;i<8;i++)input[i]=random_word(&state);memcpy(saved,input,sizeof saved);
        if(mprotect(mapping+page,page,PROT_READ))return (void *)2;
        uint64_t count=test->deep&&seed==9?UINT64_C(1000001):counts[seed];model(test,saved,count,expected);
        uint64_t result=test->run(input,&out[1],count),answer=expected[2];
        if(test->return_kind==0){uint64_t m=mask(test->a_bits);answer&=m;if(test->signed_return&&(answer&((m>>1)+1)))answer|=~m;}
        else if(test->return_kind==2)answer=(uintptr_t)&out[1];
        if(work->fault==1)result^=1;if(work->fault==2)out[2]^=1;if(work->fault==3)out[5]^=1;
        if(result!=answer||memcmp(out+1,expected,sizeof expected)||memcmp(input,saved,sizeof saved)||out[0]!=UINT64_C(0xa55a11223344eeff)||out[5]!=UINT64_C(0x778899001122a55a)){
            fprintf(stderr,"tail-transfer case=%zu seed=%u count=%llu widths=%u/%u return=%u fault=%u\n",k,seed,(unsigned long long)count,test->a_bits,test->b_bits,test->return_kind,work->fault);return (void *)1;
        }
        observations+=8;
    }
    if(munmap(mapping,page*3))return (void *)2;
    printf("tail-transfer observations=%zu direct-indirect=ccc-fastcc=extended-carriers=argument-cycles=ordinary-stack-calls=one-million-transfers=worker-stack-65536=readonly-guards=preserved\n",observations);return 0;
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    struct workload work={cases,count,argc>1?(unsigned)strtoul(argv[1],0,10):0};pthread_attr_t attr;pthread_t thread;void *result=0;
    if(pthread_attr_init(&attr)||pthread_attr_setstacksize(&attr,65536)||pthread_create(&thread,&attr,worker,&work)||pthread_attr_destroy(&attr)||pthread_join(thread,&result))return 2;
    return (int)(uintptr_t)result;
}
