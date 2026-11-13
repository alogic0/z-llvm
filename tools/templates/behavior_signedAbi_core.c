#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
extern uint32_t signed_physical_observer(const void *,const uint64_t *);
__asm__(".text\n.type signed_physical_observer,@function\nsigned_physical_observer:\n"
        "pushq %rbp\nmovq %rsp,%rbp\nsubq $464,%rsp\nmovq %rdi,%r11\nmovq %rsi,%r10\nxorl %eax,%eax\n"
        "1:\nmovq 48(%r10,%rax,8),%rdx\nmovq %rdx,(%rsp,%rax,8)\nincq %rax\ncmpq $58,%rax\njne 1b\n"
        "movq 0(%r10),%rdi\nmovq 8(%r10),%rsi\nmovq 16(%r10),%rdx\nmovq 24(%r10),%rcx\nmovq 32(%r10),%r8\nmovq 40(%r10),%r9\ncall *%r11\nleave\nret\n"
        ".size signed_physical_observer,.-signed_physical_observer\n.section .note.GNU-stack,\"\",@progbits\n.previous\n");
struct test_case {const void *entry;kernel probe;unsigned bits,slots,literals;};
static uint32_t expected_words[62];
static unsigned provider_bad;
static uint32_t extend(uint64_t word,unsigned bits,unsigned sign){uint32_t mask=(1u<<bits)-1,value=(uint32_t)word&mask;return sign&&(value&(1u<<(bits-1)))?value|~mask:value;}
static uint32_t reduce(const uint32_t *words,unsigned bits,unsigned count,uint64_t live){uint32_t result=(uint32_t)live;for(unsigned i=0;i<count;i++)result=(result^extend(words[i],bits,i%3==0))*37u+i*17u;return result;}
static uint32_t provider(const uint32_t *words,unsigned bits,unsigned count,void *output,uint64_t live){
    uint32_t mask=(1u<<bits)-1;for(unsigned i=0;i<count;i++){
        if(i%3==2){if((words[i]&mask)!=(expected_words[i]&mask))provider_bad=1;}
        else if(words[i]!=expected_words[i])provider_bad=1;
    }
    uint32_t result=reduce(words,bits,count,live);uint64_t out[2]={result,live};memcpy(output,out,sizeof out);return extend(result,bits,1);
}
static uint64_t random_word(uint64_t *state){*state^=*state<<13;*state^=*state>>7;*state^=*state<<17;return *state;}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE);uint64_t state=UINT64_C(0x213799abacbdcedf);size_t observations=0;
    unsigned char *mapping=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(mapping==MAP_FAILED||mprotect(mapping+page,page,PROT_READ|PROT_WRITE))return 2;
    uint64_t *input=(uint64_t *)(mapping+2*page-512);
    for(size_t k=0;k<count;k++)for(unsigned seed=0;seed<512;seed++){
        const struct test_case *test=&cases[k];uint64_t args[64]={0},saved[64],live=random_word(&state);uint32_t words[62],probe_words[62];
        struct {uint64_t before,value,live,after;} out={UINT64_C(0xabcdef0123456789),0,0,UINT64_C(0x123456789abcdef0)};
        uint32_t mask=(1u<<test->bits)-1;
        for(unsigned i=0;i<64;i++)input[i]=random_word(&state);
        for(unsigned i=0;i<test->slots;i++){
            uint64_t raw=seed<256?(uint64_t)(seed+i*17u):input[i];uint32_t logical=(uint32_t)raw&mask;
            words[i]=extend(logical,test->bits,i%3==0);
            uint32_t physical=i%3==2?(uint32_t)raw:words[i];args[i]=(random_word(&state)&UINT64_C(0xffffffff00000000))|physical;
            input[i]=(random_word(&state)&UINT64_C(0xffffffff00000000))|(uint32_t)raw;
            uint32_t outgoing=test->literals&&i%4==0?(i%3==0?mask-1:mask):logical;
            probe_words[i]=extend(outgoing,test->bits,i%3==0);expected_words[i]=probe_words[i];
        }
        memcpy(saved,input,sizeof saved);args[test->slots]=(uintptr_t)&out.value;args[test->slots+1]=live;
        uint32_t expected=reduce(words,test->bits,test->slots,live),returned=signed_physical_observer(test->entry,args);
        if(fault==1)returned^=1;
        if((returned&mask)!=(expected&mask)||out.value!=expected||out.live!=live||out.before!=UINT64_C(0xabcdef0123456789)||out.after!=UINT64_C(0x123456789abcdef0)||memcmp(input,saved,sizeof saved)){fprintf(stderr,"signed-abi entry case=%zu seed=%u bits=%u slots=%u expected-low=%08x got=%08x fault=%u\n",k,seed,test->bits,test->slots,expected&mask,returned,fault);return 1;}
        observations+=4;provider_bad=0;out.value=out.live=0;
        uint64_t actual=test->probe(input,&out.value,live);uint32_t result=reduce(probe_words,test->bits,test->slots,live);int64_t signed_result=(int32_t)extend(result,test->bits,1);
        if(fault==2)out.live^=1;if(fault==3)input[0]^=1;
        if(actual!=((uint64_t)signed_result^live)||out.value!=result||out.live!=live||provider_bad||out.before!=UINT64_C(0xabcdef0123456789)||out.after!=UINT64_C(0x123456789abcdef0)||memcmp(input,saved,sizeof saved)){fprintf(stderr,"signed-abi outgoing case=%zu seed=%u bits=%u slots=%u provider_bad=%u fault=%u\n",k,seed,test->bits,test->slots,provider_bad,fault);return 1;}
        observations+=4;
    }
    if(munmap(mapping,page*3))return 2;
    printf("signed-abi observations=%zu c-physical-carriers=defined-return-payloads=ccc-fastcc=signed-zero-extension=register-stack-64-arguments=exact-stores=guard-pages=preserved\n",observations);return 0;
}
