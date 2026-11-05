#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
#include <string.h>
#include <signal.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

__attribute__((noinline)) void storage_clobber(void *slot, void *guard) {
    __asm__ volatile("" :: "r"(slot),"r"(guard) : "memory");
    __asm__ volatile("mov $0x55, %%rax\n\tmov $0x66, %%rcx\n\tmov $0x77, %%rdx\n\t"
                     "mov $0x88, %%rsi\n\tmov $0x99, %%rdi\n\tmov $0xaa, %%r8\n\t"
                     "mov $0xbb, %%r9\n\tmov $0xcc, %%r10\n\tmov $0xdd, %%r11"
                     ::: "rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","cc","memory");
}
uint64_t storage_probe_sink(const uint8_t *p) { return (uint64_t)p[0]+p[32767]; }
extern uint64_t storage_probe(void);
extern uint64_t storage_bytes1(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_bytes2(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_bytes3(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_bytes5(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_bytes257(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_page(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_pages(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_limit(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_slot16(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_slot32(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_packed(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_padded(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_word16(uint64_t,uint64_t,uint64_t*);
extern uint64_t storage_word32(uint64_t,uint64_t,uint64_t*);
struct Test { const char *name; uint64_t (*run)(uint64_t,uint64_t,uint64_t*); unsigned size, bits; };
static const struct Test cases[]={
    {"storage_bytes1", storage_bytes1, 1, 0},
    {"storage_bytes2", storage_bytes2, 2, 0},
    {"storage_bytes3", storage_bytes3, 3, 0},
    {"storage_bytes5", storage_bytes5, 5, 0},
    {"storage_bytes257", storage_bytes257, 257, 0},
    {"storage_page", storage_page, 4096, 0},
    {"storage_pages", storage_pages, 8193, 0},
    {"storage_limit", storage_limit, 65536, 0},
    {"storage_slot16", storage_slot16, 2, 0},
    {"storage_slot32", storage_slot32, 4, 0},
    {"storage_packed", storage_packed, 13, 0},
    {"storage_padded", storage_padded, 32, 0},
    {"storage_word16", storage_word16, 0, 16},
    {"storage_word32", storage_word32, 0, 32},
};
extern uint64_t storage_on_stack(void *, uint64_t (*)(void));
__asm__(".text\n.type storage_on_stack,@function\nstorage_on_stack:\n"
        "push %r12\nmov %rsp,%r12\nmov %rdi,%rsp\ncall *%rsi\nmov %r12,%rsp\npop %r12\nret\n"
        ".size storage_on_stack,.-storage_on_stack\n");
__attribute__((noinline)) static uint64_t small_frame(void) { __asm__ volatile("" ::: "memory"); return 124; }
static int child_check(void *top, uint64_t (*run)(void), int signal_expected) {
    pid_t child=fork();
    if(child<0) return 1;
    if(child==0) {
        const struct rlimit limit={0,0};
        if(setrlimit(RLIMIT_CORE,&limit)) _exit(3);
        _exit(storage_on_stack(top,run)==124?0:2);
    }
    int status=0;
    if(waitpid(child,&status,0)!=child) return 1;
    return signal_expected ? !(WIFSIGNALED(status)&&WTERMSIG(status)==SIGSEGV)
                           : !(WIFEXITED(status)&&WEXITSTATUS(status)==0);
}
static int probe_checks(void) {
    long page=sysconf(_SC_PAGESIZE);
    if(page!=4096) return 2;
    size_t length=32*(size_t)page;
    uint8_t *memory=mmap(NULL,length,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(memory==MAP_FAILED) return 2;
    void *top=memory+length-16;
    int failed=child_check(top,storage_probe,0);
    if(mprotect(memory+length-2*page,(size_t)page,PROT_NONE)) failed=1;
    failed|=child_check(top,small_frame,0);
    failed|=child_check(top,storage_probe,1);
    if(munmap(memory,length)) failed=1;
    if(failed) { fputs("bounded-storage stack probe did not stop at the guard page\n",stderr); return 1; }
    puts("bounded-storage guard_checks=3 accessible=small-frame=guard-fault=verified");
    return 0;
}
int main(int argc,char **argv) {
    if(argc==2&&strcmp(argv[1],"--guard-probe")==0) return probe_checks();
    if(argc!=1) return 2;
    const uint64_t values[]={0,1,UINT64_C(0x7f),UINT64_C(0x8000),UINT64_C(0x7fffffff),UINT64_C(0x80000000),UINT64_C(0x8000000000000000),UINT64_MAX};
    unsigned observations=0;
    for(unsigned t=0;t<sizeof cases/sizeof cases[0];t++)
      for(unsigned i=0;i<8;i++) for(unsigned j=0;j<8;j++) {
        const struct Test *c=&cases[t];uint64_t a=values[i],b=values[j];
        uint64_t out[]={UINT64_C(0xa5a5a5a5a5a5a5a5),UINT64_C(0xdeadbeef),UINT64_C(0xa5a5a5a5a5a5a5a5)};
        uint64_t expected=c->bits?(a&((UINT64_C(1)<<c->bits)-1)):((c->size==1?b:a)&255)+(b&255);
        uint64_t live=c->run(a,b,&out[1]);
        if(live!=(a^b)||out[1]!=expected||out[0]!=UINT64_C(0xa5a5a5a5a5a5a5a5)||out[2]!=out[0]) {
            fprintf(stderr,"%s a=%" PRIx64 " b=%" PRIx64 " result=%" PRIx64 " expected=%" PRIx64 " live=%" PRIx64 "\n",c->name,a,b,out[1],expected,live);return 1;
        }
        observations++;
      }
    for(unsigned i=0;i<64;i++) { if(storage_probe()!=124) return 1; observations++; }
    if(observations!=960) return 2;
    puts("bounded-storage observations=960 bytes=words=padding=pages=calls=live=guards=preserved");return 0;
}
