// By mohannad Ibrahim
#ifndef QUANTIZATION_H
#define QUANTIZATION_H

#include <stdint.h>

#define QUANT_SCALE 32


#if QUANT_SCALE == 8

    struct quant_params
    {
        float scale;
        uint8_t zero;  //zero point or  zero-offset
        float min, max; //range
    };

    /* function to find min and max values simultanuously amongst the ranks (array)
     it has an O(N) complexity*/
    void getMinMax(struct quant_params * q_params, float * ranks, uint32_t size);

    //ranges for unisigned 8_bit quantization
    #define RANGE_MAX (uint8_t)255
    #define RANGE_MIN (uint8_t)0

    #define ABS(num) ((num<0)?(-num):(num))
    #define ROUND(num) (uint32_t)((num)>=0?((num)+0.5):((num)-0.5))

    //to keep the number in the range 0 - 255
    #define CLAMP(num,min,max) (num < min ? min : (num > max ? max : num))

    //quantization parameters
    #define GetScale(min,max) (float)(min == max ? 1.0 : ABS((max - min))/RANGE_MAX)
    #define GetZeroPoint(max,scale) (uint8_t)CLAMP((RANGE_MAX - ROUND(max/scale)), RANGE_MIN, RANGE_MAX)

    //quantize
    #define quantize(num,scale,zero) (uint8_t)(CLAMP(ROUND(num/scale) + zero, RANGE_MIN, RANGE_MAX))
    #define dequantize_f(num,scale,zero) (float)(scale*(CLAMP(num, RANGE_MIN, RANGE_MAX)))
    #define dequantize_d(num,scale,zero) (double)(scale*(CLAMP(num, RANGE_MIN, RANGE_MAX)))


#elif QUANT_SCALE == 16
struct quant_params
{
    float scale;
    uint16_t zero;  //zero point or  zero-offset
    float min, max; //range
};

/* function to find min and max values simultanuously amongst the ranks (array)
 it has an O(N) complexity*/
void getMinMax(struct quant_params * q_params, float * ranks, uint32_t size);

    //ranges for unisigned 16-bit quantization
    #define RANGE_MAX (uint16_t)65535
    #define RANGE_MIN (uint16_t)0

    #define ABS(num) ((num<0)?(-num):(num))
    #define ROUND(num) (uint32_t)((num)>=0?((num)+0.5):((num)-0.5))

    //to keep the number in the range 0 - 255
    #define CLAMP(num,min,max) (num < min ? min : (num > max ? max : num))

    //quantization parameters
    #define GetScale(min,max) (float)(min == max ? 1.0 : ABS((max - min))/65535)
    #define GetZeroPoint(max,scale) (uint16_t)CLAMP(RANGE_MAX - ROUND(max/scale), RANGE_MIN, RANGE_MAX)

    //quantize
    #define quantize(num,scale,zero) (uint16_t)(CLAMP(ROUND(num/scale) + zero, RANGE_MIN, RANGE_MAX))
    #define dequantize_f(num,scale,zero) (float)(scale*(CLAMP(num, RANGE_MIN, RANGE_MAX)))
    #define dequantize_d(num,scale,zero) (double)(scale*(CLAMP(num, RANGE_MIN, RANGE_MAX)))

#else /* QUANTIZATION == 32 */
    struct quant_params
    {
        double scale;
        uint32_t zero;  //zero point or  zero-offset
        float min, max; //range
    };

    /* function to find min and max values simultanuously amongst the ranks (array)
     it has an O(N) complexity*/
    void getMinMax(struct quant_params * q_params, float * ranks, uint32_t size);

    //ranges for unisigned 32-bit quantization
    #define RANGE_MAX (uint32_t)4294967295
    #define RANGE_MIN (uint32_t)0

    #define ABS(num) ((num<0)?(-num):(num))
    #define ROUND(num) (uint32_t)((num)>=0?((num)+0.5):((num)-0.5))

    //to keep the number in the range 0 - 255
    #define CLAMP(num,min,max) (num < min ? min : (num > max ? max : num))

    //quantization parameters
    #define GetScale(min,max) (double)(min == max ? 1.0 : ABS((max - min))/RANGE_MAX)
    #define GetZeroPoint(max,scale) (uint32_t)CLAMP((RANGE_MAX - ROUND(max/scale)), RANGE_MIN, RANGE_MAX)

    //quantize
    #define quantize(num,scale,zero) (uint32_t)(CLAMP(ROUND(num/scale) + zero, RANGE_MIN, RANGE_MAX))
    #define dequantize_f(num,scale,zero) (float)(scale*(CLAMP(num, RANGE_MIN, RANGE_MAX)))
    #define dequantize_d(num,scale,zero) (double)(scale*(CLAMP(num, RANGE_MIN, RANGE_MAX)))

#endif /* QUANT_SCALE */

#endif /* QUANTIZATION_H */