#ifndef FIXEDPOINT_H
#define FIXEDPOINT_H

#include <linux/types.h>

//0100 1010 1010 0010.1101 0101 0101 0011
//0000 0000 0000 0000.1111 1111 1111 1111

struct FixedPoint
{

	__u32 size; // 32 or 64 bits
	__u32 scale32;
	__u32 scale64;
	__u32 fractionMask32;
	__u64 fractionMask64;
	__u32 wholeMask32;
	__u64 wholeMask64;

};

#define WHOLEW 16
#define SCALEF 24 // 1/2^16
#define SCALED 32 // 1/2^32
#define EPSILON 1  // smallest possible increment or decrement you can perform
#define FRACTION_MASK_32 (0xFFFFFFFF >> (32-SCALEF))
#define FRACTION_MASK_64 (0xFFFFFFFFFFFFFFFF >> (64-SCALED))

#define WHOLE_MASK_32 (-1 ^ FRACTION_MASK_32)
#define WHOLE_MASK_64 (-1 ^ FRACTION_MASK_64)

#define FloatToFixed32(num)	(__u32)((num) * (float)((__u32)(1)<<SCALEF) + (float)(num >= 0 ? 0.5 : -0.5))
#define DoubleToFixed32(num)	(__u32)((num) * (double)((__u32)(1)<<SCALEF) + (double)(num >= 0 ? 0.5 : -0.5))

#define FloatToFixed64(num)	(__u64)((num) * (float)((__u64)(1)<<SCALED) + (float)(num >= 0 ? 0.5 : -0.5))
#define DoubleToFixed64(num)	(__u64)((num) * (double)((__u64)(1)<<SCALED) + (double)(num >= 0 ? 0.5 : -0.5))

#define Fixed32ToDouble(num)	((double)(num) / (double)((__u32)(1)<<SCALEF))
#define Fixed64ToDouble(num)	((double)(num) / (double)((__u64)(1)<<SCALED))

#define Fixed32ToFloat(num)	((float)(num) / (float)((__u32)(1)<<SCALEF))
#define Fixed64ToFloat(num)	((float)(num) / (float)((__u64)(1)<<SCALED))

#define UInt32ToFixed32(num)	((__u32) (num)<<SCALEF)
#define UInt64ToFixed32(num)	((__u64) (num)<<SCALEF)

#define UInt32ToFixed64(num)	((__u32) (num)<<SCALED)
#define UInt64ToFixed64(num)	((__u64) (num)<<SCALED)

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
 
void initFixedPoint(struct FixedPoint* fp, __u32 size,__u32 scale32,__u32 scale64);

__u32 floatToFixed32(struct FixedPoint* fp, float num);

__u32 doubleToFixed32(struct FixedPoint* fp, double num);

__u64 floatToFixed64(struct FixedPoint* fp, float num);

__u64 doubleToFixed64(struct FixedPoint* fp, double num);

float fixed32ToFloat(struct FixedPoint* fp, __u32 num);

float fixed32ToDouble(struct FixedPoint* fp, __u32 num);

float fixed64ToFloat(struct FixedPoint* fp, __u64 num);

double fixed64ToDouble(struct FixedPoint* fp, __u64 num);

__u32 uInt32ToFixed32(struct FixedPoint* fp, __u32 num);

__u32 uInt64ToFixed32(struct FixedPoint* fp, __u64 num);

__u64 uInt32ToFixed64(struct FixedPoint* fp, __u32 num);

__u64 uInt64ToFixed64(struct FixedPoint* fp, __u64 num);

__u32 int32ToFixed32(struct FixedPoint* fp, int num);

__u32 int64ToFixed32(struct FixedPoint* fp, long num);

__u64 int32ToFixed64(struct FixedPoint* fp, int num);

__u64 int64ToFixed64(struct FixedPoint* fp, long num);

__u32 fixed32ToUInt32(struct FixedPoint* fp, __u32 num);

__u64 fixed32ToUInt64(struct FixedPoint* fp, __u32 num);

__u32 fixed64ToUInt32(struct FixedPoint* fp, __u64 num);

__u64 fixed64ToUInt64(struct FixedPoint* fp, __u64 num);

int fixed32ToInt32(struct FixedPoint* fp, __u32 num);

long fixed32ToInt64(struct FixedPoint* fp, __u32 num);

int fixed64ToInt32(struct FixedPoint* fp, __u64 num);

long fixed64ToInt64(struct FixedPoint* fp, __u64 num);

__u32 fractionPart32(struct FixedPoint* fp, __u32 num);

__u32 wholePart32(struct FixedPoint* fp, __u32 num);

__u64 fractionPart64(struct FixedPoint* fp, __u64 num);

__u64 wholePart64(struct FixedPoint* fp, __u64 num);

__u64 mul32U(struct FixedPoint* fp, __u32 x,__u32 y);

__u32 mulFixed32V1(struct FixedPoint* fp, __u32 x,__u32 y);

__u32 mulFixed32V1ROUND(struct FixedPoint* fp, __u32 x,__u32 y);

__uint128_t mul64U(struct FixedPoint* fp, __u64 x,__u64 y);

__u64 mulFixed64V1(struct FixedPoint* fp, __u64 x,__u64 y);

__u64 mulFixed64V1ROUND(struct FixedPoint* fp, __u64 x,__u64 y);
 
__u32 divFixed32V1(struct FixedPoint* fp, __u32 x,__u32 y);

__u64 divFixed64V1(struct FixedPoint* fp, __u64 x,__u64 y);

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