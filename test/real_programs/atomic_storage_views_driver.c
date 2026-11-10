#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
typedef unsigned __int128 u128;
typedef uint64_t (*function_t)(uint64_t,uint64_t,uint64_t,uint64_t*);
extern uint64_t atomic_storage_8(uint64_t,uint64_t,uint64_t,uint64_t*);
extern uint64_t atomic_storage_16(uint64_t,uint64_t,uint64_t,uint64_t*);
extern uint64_t atomic_storage_32(uint64_t,uint64_t,uint64_t,uint64_t*);
extern uint64_t atomic_storage_64(uint64_t,uint64_t,uint64_t,uint64_t*);
extern uint64_t atomic_storage_pointer(uint64_t,uint64_t,uint64_t,uint64_t*);
static const uint64_t key = UINT64_C(0xfeedface12345678);
__attribute__((noinline)) uint64_t frontier_views_clobber(uint64_t input) {
    uint64_t result = input ^ key;
    __asm__ volatile(
        "movabs $0x1111111133333333, %%rcx\n\t"
        "movabs $0x2222222244444444, %%rdx\n\t"
        "movabs $0x3333333355555555, %%rdi\n\t"
        "movabs $0x4444444466666666, %%rsi\n\t"
        "movabs $0x5555555577777777, %%r8\n\t"
        "movabs $0x6666666688888888, %%r9\n\t"
        "movabs $0x7777777799999999, %%r10\n\t"
        "movabs $0x88888888aaaaaaaa, %%r11\n\t"
        : "+a"(result) : : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "memory", "cc");
    return result;
}

static const function_t functions[]={atomic_storage_8,atomic_storage_16,atomic_storage_32,atomic_storage_64,atomic_storage_pointer};
extern uint64_t frontier_views_global[3];
static const unsigned widths[]={8,16,32,64,64};

static unsigned observations, inject_fault;
static int check(unsigned which,uint64_t a,uint64_t b,uint64_t salt) {
 uint64_t box[8]={key,0,0,0,0,key^1,key^2,key^3}; uint64_t *out=box+1;
 const unsigned bits=widths[which]; const uint64_t mask=bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1;
 const uint64_t before=a^key;
 frontier_views_global[0]=key;frontier_views_global[1]=before;frontier_views_global[2]=~key;
 const uint64_t low=a&mask,high=which==4 ? (salt&1 ? b:a) : (a+b)&mask,third=before&mask,check=which==4 ? key^(salt&1) : key;
 const uint64_t expected_memory=(before&~mask)|high;
 const uint64_t expected_return=low^high^third^a^check;
 uint64_t actual=functions[which](a,b,salt,out);
 if(inject_fault==1) actual^=1;
 if(inject_fault==2) out[1]^=1;
 if(inject_fault==3)frontier_views_global[1]^=1;
 if(inject_fault==4)box[0]^=1;
 if(inject_fault==5)frontier_views_global[2]^=1;
 if(actual!=expected_return || out[0]!=low || out[1]!=high || out[2]!=third || out[3]!=check || box[0]!=key || box[5]!=(key^1) || box[6]!=(key^2) || box[7]!=(key^3) || frontier_views_global[0]!=key || frontier_views_global[1]!=expected_memory || frontier_views_global[2]!=~key) {
  fprintf(stderr,"frontier mismatch function=%u a=%llx b=%llx salt=%llx fault=%u\n",which,(unsigned long long)a,(unsigned long long)b,(unsigned long long)salt,inject_fault);return 1;
 }
 ++observations;return 0;
}
int main(int argc,char **argv) {
 if(argc==2) inject_fault=(unsigned)strtoul(argv[1],0,10);
 if(argc>2 || inject_fault>5)return 2;
 const uint64_t v[]={0,1,2,0x7fffffff,0x80000000,0x8000000000000000ULL,UINT64_MAX-1,UINT64_MAX};
 const uint64_t s[]={0,1,2,3,14,15,0x123456789abcdef0ULL,UINT64_MAX};
 for(unsigned f=0;f<5;f++)for(unsigned i=0;i<8;i++)for(unsigned j=0;j<8;j++)for(unsigned k=0;k<8;k++)if(check(f,v[i],v[j],s[k]))return 1;
 printf("atomic-storage-views observations=%u ordering=volatile=width=pointer=clobbers=guards=preserved\n",observations);return observations!=2560;
}
