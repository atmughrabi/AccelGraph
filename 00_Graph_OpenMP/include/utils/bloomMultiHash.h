#ifndef BLOOMMULTIHASH_H
#define BLOOMMULTIHASH_H


#include <linux/types.h>
#include "bitmap.h"

struct BloomMultiHash
{

    __u32 *counter;
    __u32 size; // size of bloom filter
    __u32 partition; // partition m/k as a prime number
    __u32 k; // number of hash function


    //pass these variables after find in bloomfilter
    __u32 membership;
    __u32 temperature;


    //pass these variables after find in bloomfilter
    __u32 threashold;
    __u32 decayPeriod;
    __u32 numIO;

    double bpe;
    double error;
};


struct BloomMultiHash *newBloomMultiHash(__u32 size, __u32 k, double error);
void freeBloomMultiHash( struct BloomMultiHash *bloomMultiHash);
void addToBloomMultiHash(struct BloomMultiHash *bloomMultiHash, __u32 item);
__u32 findInBloomMultiHash(struct BloomMultiHash *bloomMultiHash, __u32 item);




#endif