#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
extern float fp_frame_polynomial_64_32(double);
extern double fp_frame_polynomial_32_64(float);
extern double fp_frame_two_inputs(double,double);
extern double fp_frame_dead_input(double);
static uint32_t bits32(float x) { uint32_t b; memcpy(&b,&x,4); return b; }
static uint64_t bits64(double x) { uint64_t b; memcpy(&b,&x,8); return b; }
static float float32(uint32_t b) { float x; memcpy(&x,&b,4); return x; }
static double float64(uint64_t b) { double x; memcpy(&x,&b,8); return x; }
int main(int argc,char **argv) {
    unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
    size_t observations=0;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"fp-frame-preservation fault=%u observation=%zu\n",fault,observations); return 1; } } while(0)
    const double special[]={0.,-0.,1.,-1.,INFINITY,-INFINITY,NAN,0x1p-149};
    for(unsigned seed=0;seed<73;seed++) {
        const double x=seed<65 ? ((double)seed-32.)/8. : special[seed-65];
        const double y=((double)(seed*13%31)-15.)/4.;
        double square=x*x;
        float expected32=(float)((x+square*square)+square);
        float actual32=fp_frame_polynomial_64_32(x);
        if(fault==1) actual32=float32(bits32(actual32)^1);
        CHECK(isnan(expected32) ? isnan(actual32) : bits32(actual32)==bits32(expected32));
        float low=(float)x;
        float low_square=low*low;
        float low_first=low+low_square*low_square;
        double expected64=(double)(low_first+low_square);
        double actual64=fp_frame_polynomial_32_64(low);
        if(fault==2) actual64=float64(bits64(actual64)^1);
        CHECK(isnan(expected64) ? isnan(actual64) : bits64(actual64)==bits64(expected64));
        expected64=square+(x+y);
        actual64=fp_frame_two_inputs(x,y);
        if(fault==3) actual64=float64(bits64(actual64)^1);
        CHECK(isnan(expected64) ? isnan(actual64) : bits64(actual64)==bits64(expected64));
        actual64=fp_frame_dead_input(x);
        CHECK(isnan(square) ? isnan(actual64) : bits64(actual64)==bits64(square));
    }
    printf("fp-frame-preservation observations=%zu live-inputs=cross-width=preserved\n",observations);
    return 0;
}
