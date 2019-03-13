#ifndef QUANTIZATION_H
#define QUANTIZATION_H

#include <linux/types.h>

// typedef uint8_t  __u8;

struct quant_params
{
    float scale;
    __u8 zero;    //zero point or  zero-offset
};

/* struct to be used to extract min and max values of ranks
to be used in quantization scale calculations*/
struct MinMax
{
    float min,max;
};

//ranges for unisigned 8bit quantization
#define RANGE_MAX (__u8)255
#define RANGE_MIN (__u8)0

#define ABS(num) ((num<0)?(-num):(num))
#define ROUND(num) ((num)>=0?(int)((num)+0.5):(int)((num)-0.5))

//to keep the number in the range 0 - 255
#define CLAMP(num,min,max) (num < min ? min : (num > max ? max : num))

//quantization parameters
#define GetZeroPoint(max,scale) (__u8)CLAMP((RANGE_MAX - ROUND(max/scale)), RANGE_MIN, RANGE_MAX)
#define GetScale(min,max) (float)(min == max ? 1.0 : ABS((max - min))/RANGE_MAX;)

//quantize
#define quantize(num,scale,zero) (__u8)(CLAMP(ROUND(num/scale) + zero, RANGE_MIN, RANGE_MAX))

/* function to find min and max values simultanuously amongst the ranks (array)
 it has an O(N) complexity*/
// struct MinMax getMinMax(float ranks[], int size)
// {
//     struct MinMax x;
    
//     if (size == 1)
//     {
//         x.max = ranks[0];
//         x.min = ranks[0];
//         return x;
//     }
    
//     if (ranks[0] > ranks[1])
//     {
//         x.max = ranks[0];
//         x.min = ranks[1];
//     }
//     else
//     {
//         x.max = ranks[1];
//         x.min = ranks[0];
//     }

//     for (int i = 2; i < size; i++)
//     {
//         if (ranks[i] > x.max)
//             x.max = ranks[i];
//         else if (ranks[i] < x.min)
//             x.min = ranks[i];
//     }
//     return x;
// }


/* In a form of a function: It receives an array of values (ranks) and extract
the appropraite quantization parameters (scale and zero-offset)
inputs:    ranks array, size of array */
/*
 struct quant_params get_quant_params(float ranks[], int size)
{
    struct quant_params q;
    struct MinMax x;
    
    // 1. Find min and max values
    x = getMinMax(ranks, size);
    
    // 2. Find the scale value
    if (x.min != x.max)
        q.scale = ABS((x.max - x.min))/RANGE_MAX;
    else
        q.scale = 1.0;
        
    // 3. Find the zero-offset value
    q.zero = CLAMP(RANGE_MAX - ROUND(x.max/q.scale), RANGE_MIN, RANGE_MAX);
        
    return q;
}
*/

#endif /* QUANTIZATION_H */
