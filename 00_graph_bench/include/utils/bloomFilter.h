#ifndef BLOOMFILTER_H
#define BLOOMFILTER_H


#include <linux/types.h>
#include "bitmap.h"

struct BloomFilter
{
    struct Bitmap *bloom;
    __u32 size; // size of bloom filter
    __u32 partition; // partition m/k as a prime number
    __u32 k; // number of hash function
};



struct BloomFilter *newBloomFilter(__u32 size, __u32 k);
void freeBloomFilter( struct BloomFilter *bloomFilter);
void clearBloomFilter( struct BloomFilter *bloomFilter);
void addToBloomFilter(struct BloomFilter *bloomFilter, __u32 item);
__u32 findInBloomFilter(struct BloomFilter *bloomFilter, __u32 item);


#endif