#include <stdio.h>
#include <stdlib.h>

#include <linux/types.h>
#include "bloomFilter.h"
#include "bitmap.h"
#include "hash.h"
#include "myMalloc.h"

struct BloomFilter *newBloomFilter(__u32 size, __u32 k)
{



    struct BloomFilter *bloomFilter = (struct BloomFilter *) my_malloc( sizeof(struct BloomFilter));


    bloomFilter->bloom = newBitmap(size);
    bloomFilter->size = ((size + kBitsPerWord - 1) / kBitsPerWord) * kBitsPerWord;
    bloomFilter->k = k;
    bloomFilter->partition = bloomFilter->size / bloomFilter->k;

    return bloomFilter;


}
void freeBloomFilter( struct BloomFilter *bloomFilter)
{

    if(bloomFilter)
    {
        freeBitmap(bloomFilter->bloom);
        free(bloomFilter);
    }


}
void clearBloomFilter( struct BloomFilter *bloomFilter)
{

    clearBitmap(bloomFilter->bloom);

}


void addToBloomFilter(struct BloomFilter *bloomFilter, __u32 item)
{


    __u64 z = magicHash64((__u64)item);
    __u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;

    for (i = 0; i < bloomFilter->k; ++i)
    {
        __u64 k = (h1 + i * h2) % bloomFilter->partition; // bit to set
        __u64 j = k + (i * bloomFilter->partition);       // in parition 'i'
        setBit(bloomFilter->bloom, (__u32)j);
    }

    // bloomFilter->size++;

}
__u32 findInBloomFilter(struct BloomFilter *bloomFilter, __u32 item)
{


    // MitzenmacherKirsch optimization
    __u64 z = magicHash64((__u64)item);
    __u64 h1 = z & 0xffffffff;
    __u64 h2 = z >> 32;
    __u64 i;

    for (i = 0; i < bloomFilter->k; ++i)
    {
        __u64 k = (h1 + i * h2) % bloomFilter->partition; // bit to set
        __u64 j = k + (i * bloomFilter->partition);       // in parition 'i'
        if(!getBit(bloomFilter->bloom, (__u32)j))
            return 0;

    }




    return 1;


}

