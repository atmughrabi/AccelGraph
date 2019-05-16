#ifndef CACHE_H
#define CACHE_H

#include <linux/types.h>


// typedef __u64 ulong;
typedef unsigned char uchar;
typedef __u32 uint;
typedef __u32 bool;

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
    uchar top;
};

///cacheline helper functions
void initCacheLine(struct CacheLine *cacheLine);
ulong getTag(struct CacheLine *cacheLine);
uchar getTop(struct CacheLine *cacheLine);
void setTop(struct CacheLine *cacheLine, uchar top);
ulong getFlags(struct CacheLine *cacheLine);
ulong getSeq(struct CacheLine *cacheLine);
void setSeq(struct CacheLine *cacheLine, ulong Seq);
void setFlags(struct CacheLine *cacheLine, ulong flags);
void setTag(struct CacheLine *cacheLine, ulong a);
void invalidate(struct CacheLine *cacheLine);
bool isValid(struct CacheLine *cacheLine);


struct Cache
{

    ulong size, lineSize, assoc, sets, log2Sets, log2Blk, tagMask, numLines, evictions;
    ulong reads, readMisses, readsPrefetch, readMissesPrefetch, writes, writeMisses, writeBacks, readMissesTop, readsTopPrefetch, readMissesTopPrefetch, readsTop, writesTop, writeMissesTop, writeBacksTop, evictionsTop;

    struct CacheLine **cacheLines;

    ulong currentCycle;

    //counters for graph performance on the cache
    uint *verticesMiss;
    uint  numVertices;

};


ulong calcTag(struct Cache *cache, ulong addr);
ulong calcIndex(struct Cache *cache, ulong addr);
ulong calcAddr4Tag(struct Cache *cache, ulong tag);


ulong getRM(struct Cache *cache);
ulong getWM(struct Cache *cache);
ulong getReads(struct Cache *cache);
ulong getWrites(struct Cache *cache);
ulong getWB(struct Cache *cache);
ulong getEVC(struct Cache *cache);
ulong getRMTop(struct Cache *cache);
ulong getWMTop(struct Cache *cache);
ulong getReadsTop(struct Cache *cache);
ulong getWritesTop(struct Cache *cache);
ulong getWBTop(struct Cache *cache);
ulong getEVCTop(struct Cache *cache);
ulong getRMPrefetch(struct Cache *cache);
ulong getReadsPrefetch(struct Cache *cache);
ulong getRMTopPrefetch(struct Cache *cache);
ulong getReadsTopPrefetch(struct Cache *cache);
void writeBackTop(struct Cache *cache, ulong addr);
void writeBack(struct Cache *cache, ulong addr);


void initCache(struct Cache *cache, int s, int a, int b );
void Access(struct Cache *cache, ulong addr, uchar op, uchar top, uint node);
void Prefetch(struct Cache *cache, ulong addr, uchar op, uchar top, uint node);
__u32 checkPrefetch(struct Cache *cache, ulong addr,  uchar top);
struct CacheLine *findLine(struct Cache *cache, ulong addr, uchar top);
void updateLRU(struct Cache *cache, struct CacheLine *line);
struct CacheLine *getLRU(struct Cache *cache, ulong addr);
struct CacheLine *findLineToReplace(struct Cache *cache, ulong addr);
struct CacheLine *fillLine(struct Cache *cache, ulong addr, uchar top);
void printStats(struct Cache *cache);

#endif