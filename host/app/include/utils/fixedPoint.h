#ifndef FIXEDPOINT_H
#define FIXEDPOINT_H

#include <linux/types.h>

//0100 1010 1010 0010.1101 0101 0101 0011
//0000 0000 0000 0000.1111 1111 1111 1111

struct FixedPoint
{

	__u32 size; // 32 or 64 bits
	__u32 scaleFloat;
	__u64 scaleDouble;
	__u32 fractionMask32;
	__u64 fractionMask64;
	__u32 wholeMask32;
	__u64 wholeMask64;

};

#define WHOLEW 16
#define SCALEF (32-WHOLEW) // 1/2^16
#define SCALED (64-WHOLEW) // 1/2^32
#define EPSILON 1  // smallest possible increment or decrement you can perform
#define FRACTION_MASK_32 (0xFFFF_FFFF >> (32-SCALEF))
#define FRACTION_MASK_64 (0xFFFF_FFFF_FFFF_FFFF >> (64-SCALED))

#define WHOLE_MASK_32 (-1 ^ FRACTION_MASK_32)
#define WHOLE_MASK_64 (-1 ^ FRACTION_MASK_64)

#define FloatToFixed(num)	((num) * (float)((__u32)(1)<<SCALEF))
#define DoubleToFixed(num)	((num) * (double)((__u64)(1)<<SCALED))

#define FixedToDouble32(num)	((double)(num) / (double)((__u32)(1)<<SCALEF))
#define FixedToDouble64(num)	((double)(num) / (double)((__u64)(1)<<SCALED))

#define FixedToFloat32(num)	((float)(num) / (float)((__u32)(1)<<SCALEF))
#define FixedToFloat64(num)	((float)(num) / (float)((__u64)(1)<<SCALED))

#define UInt32ToFixed(num)	((__u32) (num)<<SCALEF)
#define UInt64ToFixed(num)	((__u64) (num)<<SCALED)

#define Int32ToFixed(num)	( (num)<<SCALEF)
#define Int64ToFixed(num)	( (num)<<SCALED)

#define FixedToUInt32(num)	((__u32) (num)>>SCALEF)
#define FixedToUInt64(num)	((__u64) (num)>>SCALED)

#define FixedToInt32(num)	( (num)>>SCALEF)
#define FixedToInt64(num)	( (num)>>SCALED)

#define FractionPart32(num)	( (num) & FRACTION_MASK_32)
#define WholePart32(num)	( (num) & WHOLE_MASK_32)

#define FractionPart64(num)	( (num) & FRACTION_MASK_64)
#define WholePart64(num)	( (num) & WHOLE_MASK_64)

#define MUL32U(x,y)          ((__u64)((__u64)(x)*(__u64)(y)))
#define MULFixed32V1(x,y) (MUL32U(x,y)>>SCALEF) // slow
#define MULFixed32V1ROUND(x,y) (MUL32U(x,y)  + (MUL32U(x,y) & (1<<(SCALEF-1))<<1)) // slow

#define MUL64U(x,y)          ((__uint128_t)((__uint128_t)(x)*(__uint128_t)(y)))
#define MULFixed64V1(x,y) (MUL64U(x,y)>>SCALED) // slow
#define MULFixed64V1ROUND(x,y) (MUL64U(x,y)  + (MUL64U(x,y) & (1<<(SCALED-1))<<1)) // slow
 

#define DIVFixed32V1(x,y) (((__u64)(x) << SCALEF)/(__u64)(y)) // slow
#define DIVFixed64V1(x,y) (((__uint128_t)(x) << SCALED)/(__uint128_t)(y))
 
void initFixedPoint(struct FixedPoint* fp);

__u32 floatToFixed32(float num);	//((num) * (float)((__u32)(1)<<SCALEF))
__u32 doubleToFixed32(double num);	//((num) * (double)((__u32)(1)<<SCALEF))

__u64 floatToFixed64(float num);	//((num) * (float)((__u32)(1)<<SCALEF))
__u64 doubleToFixed64(double num);	//((num) * (double)((__u64)(1)<<SCALED))

double fixed32ToDouble32(__u32 num);	//((double)(num) / (double)((__u32)(1)<<SCALEF))
double fixed32ToDouble64(__u32 num);	//((double)(num) / (double)((__u64)(1)<<SCALED))

float fixed32ToFloat(__u32 num);	//((float)(num) / (float)((__u32)(1)<<SCALEF))
float fixed32ToDouble(__u32 num);	//((float)(num) / (float)((__u64)(1)<<SCALED))

float fixed64ToFloat(__u64 num);	//((float)(num) / (float)((__u32)(1)<<SCALEF))
double fixed64ToDouble(__u64 num);	//((float)(num) / (float)((__u64)(1)<<SCALED))

__u32 uInt32ToFixed32(__u32 num);	//((__u32) (num)<<SCALEF)
__u32 uInt64ToFixed32(__u64 num);	//((__u64) (num)<<SCALED)

__u64 int32ToFixed64(int num);	//( (num)<<SCALEF)
__u64 int64ToFixed64(long num);	//( (num)<<SCALED)

__u64 int32ToFixed64(int num);	//( (num)<<SCALEF)
__u64 int64ToFixed64(long num);	//( (num)<<SCALED)

__u32 fixed32ToUInt32(__u32 num);	//((__u32) (num)>>SCALEF)
__u64 fixed32ToUInt64(__u32 num);	//((__u64) (num)>>SCALED)

__u32 fixed64ToUInt32(__u64 num);	//((__u32) (num)>>SCALEF)
__u64 fixed64ToUInt64(__u64 num);	//((__u64) (num)>>SCALED)

int fixed32ToInt32(__u32 num);  	//( (num)>>SCALEF)
long fixed32ToInt64(__u32 num);	//( (num)>>SCALED)

int fixed64ToInt32(__u64 num);  	//( (num)>>SCALEF)
long fixed64ToInt64(__u64 num);	//( (num)>>SCALED)

__u32 fractionPart32(__u32 num);	//( (num) & FRACTION_MASK_32)
__u32 wholePart32(__u32 num);	//( (num) & WHOLE_MASK_32)

__u64 fractionPart64(__u64 num);	//( (num) & FRACTION_MASK_64)
__u64 wholePart64(__u64 num);	//( (num) & WHOLE_MASK_64)

__u64 mul32U(__u32 x,__u32 y);          //((__u64)((__u64)(x)*(__u64)(y)))
__u32 mulFixed32V1(__u32 x,__u32 y); //(MUL32U(x,y)>>SCALEF) // slow
__u32 mulFixed32V1ROUND(__u32 x,__u32 y); //(MUL32U(x,y)  + (MUL32U(x,y) & (1<<(SCALEF-1))<<1)) // slow

__uint128_t mul64U(__u64 x,__u64 y);          //((__uint128_t)((__uint128_t)(x)*(__uint128_t)(y)))
__u64 mulFixed64V1(__u64 x,__u64 y); //(MUL64U(x,y)>>SCALED) // slow
__u64 mulFixed64V1ROUND(__u64 x,__u64 y); //(MUL64U(x,y)  + (MUL64U(x,y) & (1<<(SCALED-1))<<1)) // slow
 

__u32 divFixed32V1(__u32 x,__u32 y); //(((__u64)(x) << SCALEF)/(__u64)(y)) // slow
__u64 divFixed64V1(__u64 x,__u64 y); //(((__uint128_t)(x) << SCALED)/(__uint128_t)(y))



// Adding two fixed points 
/*
sum = FloatToFixed(f1) + FloatToFixed(f2)
*/


// subtracting two fixed points 
/*
sub = FloatToFixed(f1) - FloatToFixed(f2)
*/

//shifting trticks work
/*
num = FloatToFixed(f1)
num <<= 1 multiplies by 2
num >>= 1 divides by 2
*/



#endif