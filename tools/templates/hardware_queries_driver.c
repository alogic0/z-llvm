#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sched.h>
extern u128 query_checked(query_fn,uint32_t,uint32_t,uint8_t*,u128,uint64_t*);
/* The wrapper owns the sentinel and records the caller stack across each call. */
__asm__(".text\n.type query_checked,@function\nquery_checked:\n"
        "pushq %rbx\npushq %r12\npushq %r13\n"
        "movq 32(%rsp),%r12\nmovq %rsp,%r13\n"
        "movabsq $0x9e3779b97f4a7c15,%rbx\n"
        "movq %rdi,%rax\nmovl %esi,%edi\nmovl %edx,%esi\n"
        "movq %rcx,%rdx\nmovq %r8,%rcx\nmovq %r9,%r8\ncall *%rax\n"
        "movq $0,(%r12)\nmovabsq $0x9e3779b97f4a7c15,%r11\n"
        "cmpq %r11,%rbx\njne 1f\ncmpq %r13,%rsp\nje 2f\n"
        "1: movq $1,(%r12)\n2: movq %r13,%rsp\n"
        "popq %r13\npopq %r12\npopq %rbx\nret\n"
        ".size query_checked,.-query_checked\n");
static uint64_t random_word(void){static uint64_t state=UINT64_C(0xe142857389abcdef);state^=state<<13;state^=state>>7;state^=state<<17;return state;}
static u128 cpuid(uint32_t leaf,uint32_t sub){uint32_t a,b,c,d;__asm__ volatile("cpuid":"=a"(a),"=b"(b),"=c"(c),"=d"(d):"a"(leaf),"c"(sub));return (u128)a|((u128)b<<32)|((u128)c<<64)|((u128)d<<96);}
static uint32_t xcr0(void){if(!((uint32_t)(cpuid(1,0)>>64)&UINT32_C(0x08000000)))return 0;uint32_t a,d;__asm__ volatile("xgetbv":"=a"(a),"=d"(d):"c"(0));return a;}
static int mismatch(unsigned which,unsigned row,unsigned fault,const char *stage){fprintf(stderr,"hardware-queries mismatch case=%u row=%u fault=%u stage=%s\n",which,row,fault,stage);return 1;}
int main(int argc,char **argv){unsigned fault=argc==2?(unsigned)strtoul(argv[1],0,10):0,observations=0;if(argc>2||fault>3)return 2;
    cpu_set_t allowed,one;if(sched_getaffinity(0,sizeof allowed,&allowed))return 2;unsigned cpu;for(cpu=0;cpu<CPU_SETSIZE&&!CPU_ISSET(cpu,&allowed);++cpu){}if(cpu==CPU_SETSIZE)return 2;CPU_ZERO(&one);CPU_SET(cpu,&one);if(sched_setaffinity(0,sizeof one,&one))return 2;
    static const uint32_t leaves[]={0,1,7,UINT32_C(0x80000000),UINT32_C(0x80000001)};
    for(unsigned which=0;which<sizeof cases/sizeof cases[0];++which)for(unsigned row=0;row<8192;++row){uint32_t leaf=leaves[row%5],sub=0;u128 live=row==0?0:row==1?~(u128)0:row==2?(u128)1<<127:((u128)random_word()<<64)|random_word(),expected;uint8_t out[24];uint64_t preserved=~UINT64_C(0);memset(out,0xa7,sizeof out);
        if(cases[which].kind==4){leaf=7;sub=row%4;expected=cpuid(leaf,sub);if((uint32_t)expected==0)expected^=(u128)1<<127;}
        else if(cases[which].kind==3)expected=xcr0();else expected=cpuid(cases[which].kind==1?0:cases[which].kind==2?7:leaf,sub);
        u128 actual=query_checked(cases[which].function,leaf,sub,out+1,live,&preserved);if(fault==1)actual^=1;if(fault==2)out[1]^=1;if(fault==3)out[17]^=1;u128 stored;memcpy(&stored,out+1,16);if(actual!=(expected^live)||stored!=expected)return mismatch(which,row,fault,"outputs-live");if(preserved)return mismatch(which,row,fault,"rbx-stack");if(out[0]!=0xa7)return mismatch(which,row,fault,"prefix");for(unsigned i=17;i<sizeof out;++i)if(out[i]!=0xa7)return mismatch(which,row,fault,"suffix");++observations;
    }puts("hardware-queries observations=40960 cpuid=xcr0=live=rbx=stack=guards=preserved");return observations==40960?0:2;
}
