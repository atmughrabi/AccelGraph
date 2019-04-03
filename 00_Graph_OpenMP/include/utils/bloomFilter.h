#ifndef BLOOMFILTER_H
#define BLOOMFILTER_H


#include <linux/types.h>
#include "bitmap.h"

struct BloomFilter {
   	struct Bitmap* bloom;
   __u32 size;
};



struct BloomFilter * newBloomFilter(__u32 size);
void freeBloomFilter( struct BloomFilter * bloomFilter);
void clearBloomFilter( struct BloomFilter * bloomFilter);
void addToBloomFilter(struct BloomFilter * bloomFilter, __u32 item);
__u32 findInBloomFilter(struct BloomFilter * bloomFilter, __u32 item);


#endif