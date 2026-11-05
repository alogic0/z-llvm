#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
__asm__(".text\n.globl address_clobber\n.type address_clobber,@function\naddress_clobber:\n"
        "mov %rsp,%rax\nand $15,%eax\ncmp $8,%eax\njne 1f\n"
        "mov $85,%rax\nmov $102,%rcx\nmov $119,%rdx\nmov $136,%rsi\nmov $153,%rdi\n"
        "mov $170,%r8\nmov $187,%r9\nmov $204,%r10\nmov $221,%r11\nret\n1: ud2\n"
        ".size address_clobber,.-address_clobber\n");
__attribute__((noinline)) void *address_identity(void *p) {
    __asm__ volatile("" :: "r"(p) : "rcx","rdx","rsi","r8","r9","r10","r11","memory");return p;
}
extern uint64_t address_phi(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_large_phi(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_select(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_loop(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_dynamic(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_scalar(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_pair(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_cast(uint64_t,uint64_t,uint64_t*);
extern uint64_t address_called(uint64_t,uint64_t,uint64_t*);
struct Test { const char *name; uint64_t (*run)(uint64_t,uint64_t,uint64_t*); unsigned kind; };
static const struct Test cases[]={
    {"address_phi", address_phi, 0},
    {"address_large_phi", address_large_phi, 0},
    {"address_select", address_select, 0},
    {"address_loop", address_loop, 1},
    {"address_dynamic", address_dynamic, 2},
    {"address_scalar", address_scalar, 3},
    {"address_pair", address_pair, 4},
    {"address_cast", address_cast, 3},
    {"address_called", address_called, 3},
};
int main(void) {
    const uint64_t values[]={0,1,7,8,UINT64_C(0x7fffffff),UINT64_C(0x80000000),UINT64_C(0x8000000000000000),UINT64_MAX};
    unsigned observations=0;
    for(unsigned t=0;t<sizeof cases/sizeof cases[0];t++)
      for(unsigned i=0;i<8;i++) for(unsigned j=0;j<8;j++) {
        const struct Test *c=&cases[t];uint64_t a=values[i],b=values[j];
        uint64_t out[]={UINT64_C(0xa5a5a5a5a5a5a5a5),UINT64_C(0xdeadbeef),UINT64_C(0xa5a5a5a5a5a5a5a5)};
        uint64_t expected=c->kind==0?((b&1)?a:b):c->kind==1?b+3:c->kind==2?a+(b&7):c->kind==4?a+b:a;
        uint64_t live=c->run(a,b,&out[1]);
        if(live!=(a^b)||out[1]!=expected||out[0]!=UINT64_C(0xa5a5a5a5a5a5a5a5)||out[2]!=out[0]) {
            fprintf(stderr,"%s a=%" PRIx64 " b=%" PRIx64 " result=%" PRIx64 " expected=%" PRIx64 " live=%" PRIx64 "\n",c->name,a,b,out[1],expected,live);return 1;
        }
        observations++;
      }
    if(observations!=576) return 2;
    puts("stack-addresses observations=576 phi=select=loop=dynamic=cast=stored=calls=live=guards=preserved");return 0;
}
