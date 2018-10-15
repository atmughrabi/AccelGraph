#ifndef FIXEDPOINT_H
#define FIXEDPOINT_H

#include <linux/types.h>

//0100 1010 1010 0010.1101 0101 0101 0011
//0000 0000 0000 0000.1111 1111 1111 1111

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
 

__u32 floatToFixed(float num); 
__u64 foubleToFixed(double num);
double fixedToDouble(__u64 num);
float  fixedToFloat(__u32 num);

__u32 uInt32ToFixed(__u32 num);	
__u64 uInt64ToFixed(__u64 num);	
int int32ToFixed(int num);	
long int64ToFixed(long num);

__u64 fixeToUInt64(__u64 num);	
__u32 fixeToUInt32(__u32 num);	
int fixeToInt32(int num);	
long fixeToInt64(long num);



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