#ifndef BLOOMSTREAM_H
#define BLOOMSTREAM_H


#include <linux/types.h>
#include "bitmap.h"

struct BloomStream{
   	struct Bitmap* bloom;
   	struct Bitmap* bloomPrime;
   	struct Bitmap* bloomHistory;
   	struct Bitmap* lowestCounter;

   __u32 *counter;
   __u32 *counterHistory;
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
};


struct BloomStream * newBloomStream(__u32 size, __u32 k);
void freeBloomStream( struct BloomStream * bloomStream);
void clearBloomStream( struct BloomStream * bloomStream);
void addToBloomStream(struct BloomStream * bloomStream, __u64 item);
__u32 findInBloomStream(struct BloomStream * bloomStream, __u64 item);
void aggregateBloomFilterToHistory(struct BloomStream * bloomStream);



#endif