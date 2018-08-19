#ifndef BITMAP_H
#define BITMAP_H

#include <linux/types.h>


#define ba_set(ptr, bit)   { (ptr)[(bit) >> 3] |= (__u8)(1 << ((bit) & 7)); }
#define ba_clear(ptr, bit) { (ptr)[(bit) >> 3] &= (__u8)(~(1 << ((bit) & 7))); }
#define ba_get(ptr, bit)   { ((ptr)[(bit) >> 3] & (__u8)(1 << ((bit) & 7)) ?  1 : 0 )}
#define ba_setbit(ptr, bit, value) { if (value) { ba_set((ptr), (bit)) } else { ba_clear((ptr), (bit)); } }

struct __attribute__((__packed__)) Bitmap
{
	__u32 size;
	__u8 *bitarray;

};

struct Bitmap* newBitmap( __u32 size);
void reset(struct Bitmap* bitmap);
void setBit(struct Bitmap* bitmap, __u32 pos);
void setBitRange(struct Bitmap* bitmap, __u32 start,__u32 end);
void setBitAtomic(struct Bitmap* bitmap, __u32 pos);
__u8 getBit(struct Bitmap* bitmap, __u32 pos);
void clearBit(struct Bitmap* bitmap, __u32 pos);
void clearBitmap(struct Bitmap* bitmap);
void freeBitmap( struct Bitmap* bitmap);
struct Bitmap*  orBitmap(struct Bitmap* bitmap1, struct Bitmap* bitmap2);

// int main()
// {
//     char mybits[(BITARRAY_BITS + 7) / 8];
//     memset(mybits, 0, sizeof(mybits));

//     ba_setbit(mybits, 33, 1);
//     if (!ba_get(33))
//         return 1;
//     return 0;
// };


#endif 