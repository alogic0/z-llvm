#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case { kernel run; unsigned kind,position,declared,bits; uint64_t raw; };
static uint32_t reverse32(uint32_t x) {
    uint32_t r=0; for(unsigned i=0;i<32;i++){r=(r<<1)|(x&1);x>>=1;} return r;
}
static uint64_t checksum(const uint64_t *words,uint64_t initial,unsigned position,unsigned declared) {
    for(unsigned i=0;i<6;i++) initial=(initial*UINT64_C(1099511628211))^
        ((declared&&i==position)?(uint32_t)words[i]:words[i]);
    return initial;
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++) {
        const struct test_case *item=&cases[which];
        uint64_t words[6]; for(unsigned i=0;i<6;i++)words[i]=
            ((uint64_t)seed*UINT64_C(0x9182736455aaccdd))^((uint64_t)i*UINT64_C(0x123456789abcdef1));
        if(seed==1)memset(words,255,sizeof words);
        if(seed==2)for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x8000000080000000)^(UINT64_C(1)<<i);
        unsigned char *input=map+2*page-sizeof words;memcpy(input,words,sizeof words);
        uint64_t salt=UINT64_C(0x9182736455aaccdd)^seed;
        struct {uint64_t pre,data[3],post;} output;memset(&output,0xa5,sizeof output);
        uint64_t answer=item->run(input,output.data,salt),expected[3],returned;
        uint64_t value=item->kind==0||item->kind==3?item->raw:item->kind==1?(uint32_t)((uint32_t)words[item->position]+(item->declared?13:(uint32_t)words[(item->position+1)%6])):words[item->position];
        expected[0]=checksum(words,value,0,0);expected[1]=salt;expected[2]=words[0];returned=expected[0]^salt;
        if(fault==1)output.data[0]^=1;if(fault==2)answer^=1;if(fault==3)output.post^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"scalar-followup case=%zu kind=%u seed=%u observation=%zu fault=%u\n",which,item->kind,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==returned);for(unsigned i=0;i<3;i++)CHECK(output.data[i]==expected[i]);
        CHECK(output.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(output.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,words,sizeof words)==0);
#undef CHECK
    }
    printf("bounded-inline-assembly observations=%zu exact-asm-effects=live-aliases=opaque-memory-ordering=stack-calls=guard-pages=preserved\n",observations);
    return munmap(map,page*3)!=0;
}
