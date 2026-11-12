#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern uint64_t medium_spill(uint64_t *,uint64_t,uint64_t);
static uint64_t observe(const uint64_t *v,uint64_t wave,uint64_t seed) {
    uint64_t sum=seed^wave;
    for(unsigned i=0;i<8;i++) sum=(sum+(v[i]^(UINT64_C(0x9e3779b97f4a7c15)*(i+1))))*UINT64_C(0x100000001b3);
    return sum;
}
uint64_t medium_observe(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h,uint64_t wave,uint64_t seed) {
    const uint64_t values[]={a,b,c,d,e,f,g,h};return observe(values,wave,seed);
}
static uint64_t expected(uint64_t seed,unsigned depth) {
    uint64_t total=0;
    for(unsigned level=0;level<=depth;level++,seed+=17) {
        uint64_t acc=seed^23;
        for(unsigned wave=0;wave<48;wave++) {
            uint64_t values[16];for(unsigned lane=0;lane<16;lane++) values[lane]=seed+17+wave*29+lane*131;
            uint64_t c=observe(values,wave,seed);
            for(unsigned lane=0;lane<16;lane++) acc+=values[lane]^c;
        }
        total+=acc;
    }
    return total;
}
struct Task {unsigned fault,leaf_only;size_t observations;int result;};
static void *worker(void *argument) {
    struct Task *task=argument;
    for(unsigned seed=0;seed<8;seed++) for(unsigned stage=0;stage<(task->leaf_only ? 1u:2u);stage++) {
        unsigned depth=stage ? 3:0;
        uint64_t input=seed*UINT64_C(0x9e3779b97f4a7c15),want=expected(input,depth);
        struct {uint64_t pre[2],value,post[2];} out;memset(&out,0xa5,sizeof(out));
        uint64_t got=medium_spill(&out.value,input,depth);
        if(task->fault==1) got^=1;if(task->fault==2) out.pre[0]^=1;if(task->fault==3) out.post[1]^=1;
        unsigned checks[]={got==want,out.value==want,out.pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.pre[1]==out.pre[0],out.post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&out.post[1]==out.post[0]};
        for(unsigned i=0;i<4;i++) {task->observations++;if(!checks[i]) {fprintf(stderr,"medium-stack-frames seed=%u depth=%u fault=%u observations=%zu\n",seed,depth,task->fault,task->observations);task->result=1;return NULL;}}
    }
    return NULL;
}
int main(int argc,char **argv) {
    struct Task task={.fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10):0,.leaf_only=argc>2&&strcmp(argv[2],"leaf")==0};
    pthread_attr_t attributes;pthread_t thread;
    if(pthread_attr_init(&attributes)||pthread_attr_setstacksize(&attributes,131072)||pthread_create(&thread,&attributes,worker,&task)||pthread_join(thread,NULL)) return 2;
    pthread_attr_destroy(&attributes);
    if(task.result) return task.result;
    printf("medium-stack-frames observations=%zu recursion=3 stack=131072 wave-live=16 guards=preserved\n",task.observations);
    return 0;
}
