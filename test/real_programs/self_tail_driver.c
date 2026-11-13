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
extern uint64_t self_tail_probe_0(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_1(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_2(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_3(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_4(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_5(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_6(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_7(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_8(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_9(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_10(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_11(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_12(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_13(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_14(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_15(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_16(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_17(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_18(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_19(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_20(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_21(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_22(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_23(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_24(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_25(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_26(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_27(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_28(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_29(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_30(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_31(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_32(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_33(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_34(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_35(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_36(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_37(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_38(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_39(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_40(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_41(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_42(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_43(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_44(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_45(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_46(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_47(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_48(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_49(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_50(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_51(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_52(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_53(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_54(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_55(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_56(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_57(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_58(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_59(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_60(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_61(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_62(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_63(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_64(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_65(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_66(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_67(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_68(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_69(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_70(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_71(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_72(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_73(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_74(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_75(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_76(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_77(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_78(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_79(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_80(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_81(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_82(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_83(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_84(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_85(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_86(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_87(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_88(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_89(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_90(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_91(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_92(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_93(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_94(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_95(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_96(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_97(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_98(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_99(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_100(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_101(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_102(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_103(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_104(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_105(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_106(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_107(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_108(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_109(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_110(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_111(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_112(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_113(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_114(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_115(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_116(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_117(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_118(const void *,void *,uint64_t);
extern uint64_t self_tail_probe_119(const void *,void *,uint64_t);
static const struct test_case cases[]={
{self_tail_probe_0,8,2,0,0},
{self_tail_probe_1,8,2,0,0},
{self_tail_probe_2,8,5,0,0},
{self_tail_probe_3,8,5,0,0},
{self_tail_probe_4,8,8,0,0},
{self_tail_probe_5,8,8,0,0},
{self_tail_probe_6,8,16,0,0},
{self_tail_probe_7,8,16,0,0},
{self_tail_probe_8,8,62,0,0},
{self_tail_probe_9,8,62,0,0},
{self_tail_probe_10,16,2,0,0},
{self_tail_probe_11,16,2,0,0},
{self_tail_probe_12,16,5,0,0},
{self_tail_probe_13,16,5,0,0},
{self_tail_probe_14,16,8,0,0},
{self_tail_probe_15,16,8,0,0},
{self_tail_probe_16,16,16,0,0},
{self_tail_probe_17,16,16,0,0},
{self_tail_probe_18,16,62,0,0},
{self_tail_probe_19,16,62,0,0},
{self_tail_probe_20,32,2,0,0},
{self_tail_probe_21,32,2,0,0},
{self_tail_probe_22,32,5,0,0},
{self_tail_probe_23,32,5,0,0},
{self_tail_probe_24,32,8,0,0},
{self_tail_probe_25,32,8,0,0},
{self_tail_probe_26,32,16,0,0},
{self_tail_probe_27,32,16,0,0},
{self_tail_probe_28,32,62,0,0},
{self_tail_probe_29,32,62,0,0},
{self_tail_probe_30,64,2,0,0},
{self_tail_probe_31,64,2,0,0},
{self_tail_probe_32,64,5,0,0},
{self_tail_probe_33,64,5,0,0},
{self_tail_probe_34,64,8,0,0},
{self_tail_probe_35,64,8,0,0},
{self_tail_probe_36,64,16,0,0},
{self_tail_probe_37,64,16,0,0},
{self_tail_probe_38,64,62,0,0},
{self_tail_probe_39,64,62,1,0},
{self_tail_probe_40,8,2,0,1},
{self_tail_probe_41,8,2,0,1},
{self_tail_probe_42,8,5,0,1},
{self_tail_probe_43,8,5,0,1},
{self_tail_probe_44,8,8,0,1},
{self_tail_probe_45,8,8,0,1},
{self_tail_probe_46,8,16,0,1},
{self_tail_probe_47,8,16,0,1},
{self_tail_probe_48,8,62,0,1},
{self_tail_probe_49,8,62,0,1},
{self_tail_probe_50,16,2,0,1},
{self_tail_probe_51,16,2,0,1},
{self_tail_probe_52,16,5,0,1},
{self_tail_probe_53,16,5,0,1},
{self_tail_probe_54,16,8,0,1},
{self_tail_probe_55,16,8,0,1},
{self_tail_probe_56,16,16,0,1},
{self_tail_probe_57,16,16,0,1},
{self_tail_probe_58,16,62,0,1},
{self_tail_probe_59,16,62,0,1},
{self_tail_probe_60,32,2,0,1},
{self_tail_probe_61,32,2,0,1},
{self_tail_probe_62,32,5,0,1},
{self_tail_probe_63,32,5,0,1},
{self_tail_probe_64,32,8,0,1},
{self_tail_probe_65,32,8,0,1},
{self_tail_probe_66,32,16,0,1},
{self_tail_probe_67,32,16,0,1},
{self_tail_probe_68,32,62,0,1},
{self_tail_probe_69,32,62,0,1},
{self_tail_probe_70,64,2,0,1},
{self_tail_probe_71,64,2,0,1},
{self_tail_probe_72,64,5,0,1},
{self_tail_probe_73,64,5,0,1},
{self_tail_probe_74,64,8,0,1},
{self_tail_probe_75,64,8,0,1},
{self_tail_probe_76,64,16,0,1},
{self_tail_probe_77,64,16,0,1},
{self_tail_probe_78,64,62,0,1},
{self_tail_probe_79,64,62,0,1},
{self_tail_probe_80,8,2,0,2},
{self_tail_probe_81,8,2,0,2},
{self_tail_probe_82,8,5,0,2},
{self_tail_probe_83,8,5,0,2},
{self_tail_probe_84,8,8,0,2},
{self_tail_probe_85,8,8,0,2},
{self_tail_probe_86,8,16,0,2},
{self_tail_probe_87,8,16,0,2},
{self_tail_probe_88,8,62,0,2},
{self_tail_probe_89,8,62,0,2},
{self_tail_probe_90,16,2,0,2},
{self_tail_probe_91,16,2,0,2},
{self_tail_probe_92,16,5,0,2},
{self_tail_probe_93,16,5,0,2},
{self_tail_probe_94,16,8,0,2},
{self_tail_probe_95,16,8,0,2},
{self_tail_probe_96,16,16,0,2},
{self_tail_probe_97,16,16,0,2},
{self_tail_probe_98,16,62,0,2},
{self_tail_probe_99,16,62,0,2},
{self_tail_probe_100,32,2,0,2},
{self_tail_probe_101,32,2,0,2},
{self_tail_probe_102,32,5,0,2},
{self_tail_probe_103,32,5,0,2},
{self_tail_probe_104,32,8,0,2},
{self_tail_probe_105,32,8,0,2},
{self_tail_probe_106,32,16,0,2},
{self_tail_probe_107,32,16,0,2},
{self_tail_probe_108,32,62,0,2},
{self_tail_probe_109,32,62,0,2},
{self_tail_probe_110,64,2,0,2},
{self_tail_probe_111,64,2,0,2},
{self_tail_probe_112,64,5,0,2},
{self_tail_probe_113,64,5,0,2},
{self_tail_probe_114,64,8,0,2},
{self_tail_probe_115,64,8,0,2},
{self_tail_probe_116,64,16,0,2},
{self_tail_probe_117,64,16,0,2},
{self_tail_probe_118,64,62,0,2},
{self_tail_probe_119,64,62,0,2},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
