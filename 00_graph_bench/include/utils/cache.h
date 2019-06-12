#ifndef CACHE_H
#define CACHE_H

#include <linux/types.h>

#define BLOCKSIZE 128
#define L1_SIZE 262144
#define L1_ASSOC 8

// typedef __u64 ulong;
typedef unsigned char uchar;
typedef __u32 uint;


enum
{
    INVALID = 0,
    VALID,
    DIRTY,
};

struct CacheLine
{
    ulong tag;
    ulong Flags;   // 0:invalid, 1:valid, 2:dirty
    ulong seq;
};

struct Cache
{

    ulong size, lineSize, assoc, sets, log2Sets, log2Blk, tagMask, numLines, evictions;
    ulong reads, readMisses, readsPrefetch, readMissesPrefetch, writes, writeMisses, writeBacks;

    struct CacheLine **cacheLines;

    ulong currentCycle;
    ulong currentCycle_cache;
    ulong currentCycle_preftcher;
    //counters for graph performance on the cache
    uint *verticesMiss;
    uint *verticesHit;
    uint  numVertices;

};


struct DoubleTaggedCache
{
    struct Cache *cache;
    struct Cache *doubleTag;
};

///cacheline helper functions
void initCacheLine(struct CacheLine *cacheLine);
ulong getTag(struct CacheLine *cacheLine);
ulong getFlags(struct CacheLine *cacheLine);
ulong getSeq(struct CacheLine *cacheLine);
void setSeq(struct CacheLine *cacheLine, ulong Seq);
void setFlags(struct CacheLine *cacheLine, ulong flags);
void setTag(struct CacheLine *cacheLine, ulong a);
void invalidate(struct CacheLine *cacheLine);
__u32 isValid(struct CacheLine *cacheLine);


ulong calcTag(struct Cache *cache, ulong addr);
ulong calcIndex(struct Cache *cache, ulong addr);
ulong calcAddr4Tag(struct Cache *cache, ulong tag);


ulong getRM(struct Cache *cache);
ulong getWM(struct Cache *cache);
ulong getReads(struct Cache *cache);
ulong getWrites(struct Cache *cache);
ulong getWB(struct Cache *cache);
ulong getEVC(struct Cache *cache);
ulong getRMPrefetch(struct Cache *cache);
ulong getReadsPrefetch(struct Cache *cache);
void writeBack(struct Cache *cache, ulong addr);

void initCache(struct Cache *cache, int s, int a, int b );
void Access(struct Cache *cache, ulong addr, uchar op, uint node);
void Prefetch(struct Cache *cache, ulong addr, uchar op, uint node);
__u32 checkPrefetch(struct Cache *cache, ulong addr);
struct CacheLine *findLine(struct Cache *cache, ulong addr);
void updateLRU(struct Cache *cache, struct CacheLine *line);
struct CacheLine *getLRU(struct Cache *cache, ulong addr);
struct CacheLine *findLineToReplace(struct Cache *cache, ulong addr);
struct CacheLine *fillLine(struct Cache *cache, ulong addr);
void printStats(struct Cache *cache);

struct Cache *newCache( __u32 l1_size, __u32 l1_assoc, __u32 blocksize, __u32 num_vertices);
void freeCache(struct Cache *cache);


struct DoubleTaggedCache *newDoubleTaggedCache(__u32 l1_size, __u32 l1_assoc, __u32 blocksize, __u32 num_vertices);
void freeDoubleTaggedCache(struct DoubleTaggedCache *cache);

#endif