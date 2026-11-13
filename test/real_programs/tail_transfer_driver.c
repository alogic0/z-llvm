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
extern uint64_t tail_transfer_probe_0(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_1(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_2(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_3(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_4(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_5(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_6(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_7(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_8(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_9(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_10(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_11(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_12(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_13(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_14(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_15(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_16(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_17(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_18(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_19(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_20(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_21(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_22(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_23(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_24(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_25(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_26(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_27(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_28(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_29(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_30(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_31(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_32(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_33(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_34(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_35(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_36(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_37(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_38(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_39(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_40(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_41(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_42(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_43(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_44(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_45(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_46(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_47(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_48(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_49(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_50(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_51(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_52(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_53(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_54(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_55(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_56(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_57(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_58(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_59(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_60(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_61(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_62(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_63(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_64(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_65(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_66(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_67(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_68(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_69(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_70(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_71(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_72(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_73(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_74(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_75(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_76(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_77(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_78(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_79(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_80(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_81(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_82(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_83(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_84(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_85(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_86(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_87(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_88(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_89(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_90(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_91(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_92(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_93(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_94(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_95(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_96(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_97(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_98(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_99(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_100(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_101(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_102(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_103(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_104(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_105(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_106(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_107(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_108(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_109(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_110(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_111(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_112(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_113(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_114(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_115(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_116(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_117(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_118(const void *,void *,uint64_t);
extern uint64_t tail_transfer_probe_119(const void *,void *,uint64_t);
static const struct test_case cases[]={
{tail_transfer_probe_0,8,8,0,1,0},
{tail_transfer_probe_1,8,8,0,1,0},
{tail_transfer_probe_2,8,8,0,1,0},
{tail_transfer_probe_3,8,8,0,1,0},
{tail_transfer_probe_4,8,8,1,1,0},
{tail_transfer_probe_5,8,8,1,1,0},
{tail_transfer_probe_6,8,8,1,1,0},
{tail_transfer_probe_7,8,8,1,1,0},
{tail_transfer_probe_8,8,8,2,1,0},
{tail_transfer_probe_9,8,8,2,1,0},
{tail_transfer_probe_10,8,8,2,1,0},
{tail_transfer_probe_11,8,8,2,1,0},
{tail_transfer_probe_12,8,8,0,0,0},
{tail_transfer_probe_13,8,8,0,0,0},
{tail_transfer_probe_14,8,8,0,0,0},
{tail_transfer_probe_15,8,8,0,0,0},
{tail_transfer_probe_16,8,8,1,0,0},
{tail_transfer_probe_17,8,8,1,0,0},
{tail_transfer_probe_18,8,8,1,0,0},
{tail_transfer_probe_19,8,8,1,0,0},
{tail_transfer_probe_20,8,8,2,0,0},
{tail_transfer_probe_21,8,8,2,0,0},
{tail_transfer_probe_22,8,8,2,0,0},
{tail_transfer_probe_23,8,8,2,0,0},
{tail_transfer_probe_24,16,16,0,1,0},
{tail_transfer_probe_25,16,16,0,1,0},
{tail_transfer_probe_26,16,16,0,1,0},
{tail_transfer_probe_27,16,16,0,1,0},
{tail_transfer_probe_28,16,16,1,1,0},
{tail_transfer_probe_29,16,16,1,1,0},
{tail_transfer_probe_30,16,16,1,1,0},
{tail_transfer_probe_31,16,16,1,1,0},
{tail_transfer_probe_32,16,16,2,1,0},
{tail_transfer_probe_33,16,16,2,1,0},
{tail_transfer_probe_34,16,16,2,1,0},
{tail_transfer_probe_35,16,16,2,1,0},
{tail_transfer_probe_36,16,16,0,0,0},
{tail_transfer_probe_37,16,16,0,0,0},
{tail_transfer_probe_38,16,16,0,0,0},
{tail_transfer_probe_39,16,16,0,0,0},
{tail_transfer_probe_40,16,16,1,0,0},
{tail_transfer_probe_41,16,16,1,0,0},
{tail_transfer_probe_42,16,16,1,0,0},
{tail_transfer_probe_43,16,16,1,0,0},
{tail_transfer_probe_44,16,16,2,0,0},
{tail_transfer_probe_45,16,16,2,0,0},
{tail_transfer_probe_46,16,16,2,0,0},
{tail_transfer_probe_47,16,16,2,0,0},
{tail_transfer_probe_48,32,32,0,0,0},
{tail_transfer_probe_49,32,32,0,0,0},
{tail_transfer_probe_50,32,32,0,0,0},
{tail_transfer_probe_51,32,32,0,0,0},
{tail_transfer_probe_52,32,32,1,0,0},
{tail_transfer_probe_53,32,32,1,0,0},
{tail_transfer_probe_54,32,32,1,0,0},
{tail_transfer_probe_55,32,32,1,0,0},
{tail_transfer_probe_56,32,32,2,0,0},
{tail_transfer_probe_57,32,32,2,0,0},
{tail_transfer_probe_58,32,32,2,0,0},
{tail_transfer_probe_59,32,32,2,0,0},
{tail_transfer_probe_60,64,64,0,0,0},
{tail_transfer_probe_61,64,64,0,0,0},
{tail_transfer_probe_62,64,64,0,0,0},
{tail_transfer_probe_63,64,64,0,0,1},
{tail_transfer_probe_64,64,64,1,0,0},
{tail_transfer_probe_65,64,64,1,0,0},
{tail_transfer_probe_66,64,64,1,0,0},
{tail_transfer_probe_67,64,64,1,0,0},
{tail_transfer_probe_68,64,64,2,0,0},
{tail_transfer_probe_69,64,64,2,0,0},
{tail_transfer_probe_70,64,64,2,0,0},
{tail_transfer_probe_71,64,64,2,0,0},
{tail_transfer_probe_72,8,16,0,1,0},
{tail_transfer_probe_73,8,16,0,1,0},
{tail_transfer_probe_74,8,16,0,1,0},
{tail_transfer_probe_75,8,16,0,1,0},
{tail_transfer_probe_76,8,16,1,1,0},
{tail_transfer_probe_77,8,16,1,1,0},
{tail_transfer_probe_78,8,16,1,1,0},
{tail_transfer_probe_79,8,16,1,1,0},
{tail_transfer_probe_80,8,16,2,1,0},
{tail_transfer_probe_81,8,16,2,1,0},
{tail_transfer_probe_82,8,16,2,1,0},
{tail_transfer_probe_83,8,16,2,1,0},
{tail_transfer_probe_84,8,16,0,0,0},
{tail_transfer_probe_85,8,16,0,0,0},
{tail_transfer_probe_86,8,16,0,0,0},
{tail_transfer_probe_87,8,16,0,0,0},
{tail_transfer_probe_88,8,16,1,0,0},
{tail_transfer_probe_89,8,16,1,0,0},
{tail_transfer_probe_90,8,16,1,0,0},
{tail_transfer_probe_91,8,16,1,0,0},
{tail_transfer_probe_92,8,16,2,0,0},
{tail_transfer_probe_93,8,16,2,0,0},
{tail_transfer_probe_94,8,16,2,0,0},
{tail_transfer_probe_95,8,16,2,0,0},
{tail_transfer_probe_96,16,8,0,1,0},
{tail_transfer_probe_97,16,8,0,1,0},
{tail_transfer_probe_98,16,8,0,1,0},
{tail_transfer_probe_99,16,8,0,1,0},
{tail_transfer_probe_100,16,8,1,1,0},
{tail_transfer_probe_101,16,8,1,1,0},
{tail_transfer_probe_102,16,8,1,1,0},
{tail_transfer_probe_103,16,8,1,1,0},
{tail_transfer_probe_104,16,8,2,1,0},
{tail_transfer_probe_105,16,8,2,1,0},
{tail_transfer_probe_106,16,8,2,1,0},
{tail_transfer_probe_107,16,8,2,1,0},
{tail_transfer_probe_108,16,8,0,0,0},
{tail_transfer_probe_109,16,8,0,0,0},
{tail_transfer_probe_110,16,8,0,0,0},
{tail_transfer_probe_111,16,8,0,0,0},
{tail_transfer_probe_112,16,8,1,0,0},
{tail_transfer_probe_113,16,8,1,0,0},
{tail_transfer_probe_114,16,8,1,0,0},
{tail_transfer_probe_115,16,8,1,0,0},
{tail_transfer_probe_116,16,8,2,0,0},
{tail_transfer_probe_117,16,8,2,0,0},
{tail_transfer_probe_118,16,8,2,0,0},
{tail_transfer_probe_119,16,8,2,0,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
