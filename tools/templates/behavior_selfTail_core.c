#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case {kernel run;unsigned bits,slots,deep,return_kind;};
struct invocation {kernel run;const void *input;void *output;uint64_t count,result;};
static void *worker(void *raw){struct invocation *job=raw;job->result=job->run(job->input,job->output,job->count);return 0;}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *mapping=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(mapping==MAP_FAILED||mprotect(mapping+page,page,PROT_READ|PROT_WRITE))return 2;
    pthread_attr_t attributes;if(pthread_attr_init(&attributes)||pthread_attr_setstacksize(&attributes,65536))return 2;
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<10;seed++){
        const struct test_case *item=&cases[which];uint64_t saved[62],state[62],next[62];size_t bytes=item->slots*8;
        uint64_t mask=item->bits==64?UINT64_MAX:(UINT64_C(1)<<item->bits)-1;
        for(unsigned i=0;i<item->slots;i++)saved[i]=((uint64_t)(i+7)*UINT64_C(0x9182736455aaccdd))^((uint64_t)(seed+5)*UINT64_C(0x123456789abcdef1));
        if(seed==0)memset(saved,0,bytes);if(seed==1)memset(saved,255,bytes);if(seed==2)for(unsigned i=0;i<item->slots;i++)saved[i]=UINT64_C(1)<<((i*13)%64);
        for(unsigned i=0;i<item->slots;i++)state[i]=saved[i]&mask;
        const uint64_t counts[]={0,1,2,3,7,17,64,257,4097,item->deep?1000001:65537};uint64_t iterations=counts[seed];
        for(uint64_t n=iterations;n>0;n--){for(unsigned i=0;i<item->slots;i++)next[i]=(n&1)?(state[(i+1)%item->slots]+(i+1)*17u)&mask:(state[(i+item->slots-1)%item->slots]^((i+1)*31u))&mask;memcpy(state,next,bytes);}
        uint64_t expected=0;for(unsigned i=0;i<item->slots;i++)expected=(expected*UINT64_C(1099511628211))^state[i];
        unsigned char *input=mapping+2*page-bytes;memcpy(input,saved,bytes);
        struct {uint64_t pre,data[3],post;} output;memset(&output,0xa5,sizeof output);
        struct invocation job={item->run,input,output.data,iterations,0};pthread_t thread;
        if(pthread_create(&thread,&attributes,worker,&job)||pthread_join(thread,0))return 2;
        if(fault==1)output.data[0]^=1;if(fault==2)job.result^=1;if(fault==3)output.post^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"self-tail case=%zu bits=%u slots=%u seed=%u observation=%zu fault=%u\n",which,item->bits,item->slots,seed,observations,fault);return 1;}}while(0)
        CHECK(job.result==(item->return_kind==2?(uint64_t)(uintptr_t)output.data:expected&mask));CHECK(output.data[0]==expected);CHECK(output.data[1]==state[0]);CHECK(output.data[2]==state[item->slots-1]);
        CHECK(output.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(output.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,saved,bytes)==0);
#undef CHECK
    }
    if(pthread_attr_destroy(&attributes)||munmap(mapping,page*3))return 2;
    printf("self-tail observations=%zu iterative-oracle=argument-cycles=one-million-steps=worker-stack-65536=guard-pages=preserved\n",observations);return 0;
}
