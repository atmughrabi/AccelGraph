
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <math.h>

#include "myMalloc.h"
#include "cache.h"


void initCacheLine(struct CacheLine *cacheLine)
{
    cacheLine->tag = 0;
    cacheLine->Flags = 0;
    cacheLine->top = 0;
}
ulong getTag(struct CacheLine *cacheLine)
{
    return cacheLine->tag;
}

uchar getTop(struct CacheLine *cacheLine)
{
    return cacheLine->top;
}

void setTop(struct CacheLine *cacheLine, uchar top)
{
    cacheLine->top = top;
}

ulong getFlags(struct CacheLine *cacheLine)
{
    return cacheLine->Flags;
}
ulong getSeq(struct CacheLine *cacheLine)
{
    return cacheLine->seq;
}
void setSeq(struct CacheLine *cacheLine, ulong Seq)
{
    cacheLine->seq = Seq;
}
void setFlags(struct CacheLine *cacheLine, ulong flags)
{
    cacheLine->Flags = flags;
}
void setTag(struct CacheLine *cacheLine, ulong a)
{
    cacheLine->tag = a;
}
void invalidate(struct CacheLine *cacheLine)
{
    cacheLine->tag = 0;    //useful function
    cacheLine->Flags = INVALID;
    cacheLine->top = 0;
}
bool isValid(struct CacheLine *cacheLine)
{
    return ((cacheLine->Flags) != INVALID);
}


//cache helper functions

ulong calcTag(struct Cache *cache, ulong addr)
{
    return (addr >> (cache->log2Blk) );
}
ulong calcIndex(struct Cache *cache, ulong addr)
{
    return ((addr >> cache->log2Blk) & cache->tagMask);
}
ulong calcAddr4Tag(struct Cache *cache, ulong tag)
{
    return (tag << (cache->log2Blk));
}

ulong getRM(struct Cache *cache)
{
    return cache->readMisses;
}
ulong getWM(struct Cache *cache)
{
    return cache->writeMisses;
}
ulong getReads(struct Cache *cache)
{
    return cache->reads;
}
ulong getWrites(struct Cache *cache)
{
    return cache->writes;
}
ulong getWB(struct Cache *cache)
{
    return cache->writeBacks;
}
ulong getEVC(struct Cache *cache)
{
    return cache->evictions;
}

ulong getRMTop(struct Cache *cache)
{
    return cache->readMissesTop;
}
ulong getWMTop(struct Cache *cache)
{
    return cache->writeMissesTop;
}
ulong getReadsTop(struct Cache *cache)
{
    return cache->readsTop;
}
ulong getWritesTop(struct Cache *cache)
{
    return cache->writesTop;
}
ulong getWBTop(struct Cache *cache)
{
    return cache->writeBacksTop;
}
ulong getEVCTop(struct Cache *cache)
{
    return cache->evictionsTop;
}

ulong getRMPrefetch(struct Cache *cache)
{
    return cache->readMissesPrefetch;
}

ulong getReadsPrefetch(struct Cache *cache)
{
    return cache->readsPrefetch;
}
ulong getRMTopPrefetch(struct Cache *cache)
{
    return cache->readMissesTopPrefetch;
}
ulong getReadsTopPrefetch(struct Cache *cache)
{
    return cache->readsTopPrefetch;
}
void writeBackTop(struct Cache *cache, ulong addr)
{
    cache->writeBacksTop++;
}

void writeBack(struct Cache *cache, ulong addr)
{
    cache->writeBacks++;
}



void initCache(struct Cache *cache, int s, int a, int b )
{
    ulong i, j;
    cache->reads = cache->readMisses = cache->readsPrefetch = cache->readMissesPrefetch = cache->writes = cache->evictions = 0;
    cache->writeMisses = cache->writeBacks = cache->currentCycle = 0;

    cache->readsTop = cache->readMissesTop = cache->readsTopPrefetch = cache->readMissesTopPrefetch = cache->writesTop = 0;
    cache->writeMissesTop = cache->writeBacksTop = cache->evictionsTop = 0;

    cache->size       = (ulong)(s);
    cache->lineSize   = (ulong)(b);
    cache->assoc      = (ulong)(a);
    cache->sets       = (ulong)((s / b) / a);
    cache->numLines   = (ulong)(s / b);
    cache->log2Sets   = (ulong)(log2(cache->sets));
    cache->log2Blk    = (ulong)(log2(b));

    //*******************//
    //initialize your counters here//
    //*******************//

    cache->tagMask = 0;
    for(i = 0; i < cache->log2Sets; i++)
    {
        cache->tagMask <<= 1;
        cache->tagMask |= 1;
    }

    /**create a two dimentional cache, sized as cache[sets][assoc]**/

    cache->cacheLines = (struct CacheLine **) my_malloc(cache->sets * sizeof(struct CacheLine *));
    for(i = 0; i < cache->sets; i++)
    {
        cache->cacheLines[i] = (struct CacheLine *) my_malloc(cache->assoc * sizeof(struct CacheLine));
        for(j = 0; j < cache->assoc; j++)
        {
            invalidate(&(cache->cacheLines[i][j]));
        }
    }
}

/**you might add other parameters to Access()
since this function is an entry point
to the memory hierarchy (i.e. caches)**/
void Access(struct Cache *cache, ulong addr, uchar op, uchar top, uint node)
{
    cache->currentCycle++;/*per cache global counter to maintain LRU order
      among cache ways, updated on every cache access*/

    if(op == 'w')
    {
        cache->writes++;
        if(top == '1')
            cache->writesTop++;
    }
    else
    {
        cache->reads++;
        if(top == '1')
            cache->readsTop++;

    }

    struct CacheLine *line = findLine(cache, addr, top);
    if(line == NULL)/*miss*/
    {
        if(op == 'w')
        {
            cache->writeMisses++;
            if(top == '1')
                cache->writeMissesTop++;
        }
        else
        {
            cache->readMisses++;
            if(top == '1')
                cache->readMissesTop++;

            cache->verticesMiss[node]++;
        }

        struct CacheLine *newline = fillLine(cache, addr, top);
        if(op == 'w')
            setFlags(newline, DIRTY);

    }
    else
    {
        /**since it's a hit, update LRU and update dirty flag**/
        updateLRU(cache, line);
        if(op == 'w')
            setFlags(line, DIRTY);
    }
}

void Prefetch(struct Cache *cache, ulong addr, uchar op, uchar top, uint node)
{
    cache->currentCycle++;/*per cache global counter to maintain LRU order
      among cache ways, updated on every cache access*/

    cache->readsPrefetch++;
    if(top == '1')
        cache->readsTopPrefetch++;

    struct CacheLine *line = findLine(cache, addr, top);
    if(line == NULL)/*miss*/
    {

        cache->readMissesPrefetch++;
        if(top == '1')
            cache->readMissesTopPrefetch++;

        fillLine(cache, addr, top);
    }
    else
    {
        /**since it's a hit, update LRU and update dirty flag**/
        updateLRU(cache, line);
    }
}


/*look up line*/
struct CacheLine *findLine(struct Cache *cache, ulong addr, uchar top)
{
    ulong i, j, tag, pos;

    pos = cache->assoc;
    tag = calcTag(cache, addr);
    i   = calcIndex(cache, addr);

    for(j = 0; j < cache->assoc; j++)
        if(isValid((&cache->cacheLines[i][j])))
            if(getTag(&(cache->cacheLines[i][j])) == tag)
            {
                pos = j;
                break;
            }

    if(pos == cache->assoc)
        return NULL;
    else
    {
        if(top == '0')
            setTop(&(cache->cacheLines[i][pos]), top);

        return &(cache->cacheLines[i][pos]);
    }

}

/*upgrade LRU line to be MRU line*/
void updateLRU(struct Cache *cache, struct CacheLine *line)
{
    setSeq(line, cache->currentCycle);
}

/*return an invalid line as LRU, if any, otherwise return LRU line*/
struct CacheLine *getLRU(struct Cache *cache, ulong addr)
{
    ulong i, j, victim, min;

    victim = cache->assoc;
    min    = cache->currentCycle;
    i      = calcIndex(cache, addr);

    for(j = 0; j < cache->assoc; j++)
    {
        if(isValid(&(cache->cacheLines[i][j])) == 0) return &(cache->cacheLines[i][j]);
    }
    for(j = 0; j < cache->assoc; j++)
    {
        if(getSeq(&(cache->cacheLines[i][j])) <= min)
        {
            victim = j;
            min = getSeq(&(cache->cacheLines[i][j]));
        }
    }
    assert(victim != cache->assoc);

    cache->evictions++;
    if(getTop(&(cache->cacheLines[i][victim])) == '1')
        cache->evictionsTop++;

    return &(cache->cacheLines[i][victim]);
}

/*find a victim, move it to MRU position*/
struct CacheLine *findLineToReplace(struct Cache *cache, ulong addr)
{
    struct CacheLine  *victim = getLRU(cache, addr);
    updateLRU(cache, victim);

    return (victim);
}

/*allocate a new line*/
struct CacheLine *fillLine(struct Cache *cache, ulong addr, uchar top)
{
    ulong tag;

    struct CacheLine *victim = findLineToReplace(cache, addr);
    assert(victim != 0);
    if(getFlags(victim) == DIRTY)
    {
        writeBack(cache, addr);
        if(getTop(victim) == '1')
            writeBackTop(cache, addr);
    }

    tag = calcTag(cache, addr);
    setTag(victim, tag);
    setFlags(victim, VALID);
    setTop(victim, top);

    /**note that this cache line has been already
       upgraded to MRU in the previous function (findLineToReplace)**/

    return victim;
}

void printStats(struct Cache *cache)
{



    float missRate = (double)((getWM(cache) + getRM(cache)) * 100) / (cache->currentCycle); //calculate miss rate
    missRate = roundf(missRate * 100) / 100;                            //rounding miss rate

    float missRatePrefetch = (double)(( getRMPrefetch(cache)) * 100) / (getReadsPrefetch(cache)); //calculate miss rate
    missRatePrefetch = roundf(missRatePrefetch * 100) / 100;

    float missRateTop = (double)((getWMTop(cache) + getRMTop(cache)) * 100) / (cache->currentCycle); //calculate miss rate
    missRateTop = roundf(missRateTop * 100) / 100;                            //rounding miss rate

    float readRatioTop = (((double)getReadsTop(cache) / getReads(cache)) * 100.0);
    float readMissRatioTop = (((double)getRMTop(cache) / getRM(cache)) * 100.0);
    float writeRatioTop = (((double)getWritesTop(cache) / getWrites(cache)) * 100.0);
    float writeMissRatioTop = (((double)getWMTop(cache) / getWM(cache)) * 100.0);
    float missRateRatioTop = (((double)missRateTop / missRate) * 100.0);
    float evictionRatioTop = (((double)getEVCTop(cache) / getEVC(cache)) * 100.0);


    printf("============ Simulation results (Cache) ============\n");
    /****print out the rest of statistics here.****/
    /****follow the ouput file format**************/
    printf("01. number of reads:                          %lu\n", getReads(cache));
    printf("02. number of read misses:                    %lu\n", getRM(cache));
    printf("03. number of writes:                         %lu\n", getWrites(cache));
    printf("04. number of write misses:                   %lu\n", getWM(cache));
    printf("05. total miss rate:                          %.2f%%\n", missRate);
    printf("06. number of writebacks:                     %lu\n", getWB(cache));
    printf("06. number of evictions:                      %lu\n", getEVC(cache));

    printf("============ Simulation results (TOP out degree nodes) ============\n");
    printf("01. number of reads:                          %lu\n", getReadsTop(cache));
    printf("02. number of read misses:                    %lu\n", getRMTop(cache));
    printf("03. number of writes:                         %lu\n", getWritesTop(cache));
    printf("04. number of write misses:                   %lu\n", getWMTop(cache));
    printf("05. total miss rate:                          %.2f%%\n", missRateTop);
    printf("06. number of evictionsTop:                   %lu\n", getEVCTop(cache));

    printf("============ Simulation results (TOP out degree nodes RATIOS) ============\n");
    printf("01. ratio of reads:                          %.2f%%\n", readRatioTop);
    printf("02. ratio of read misses:                    %.2f%%\n", readMissRatioTop);
    printf("03. ratio of writes:                         %.2f%%\n", writeRatioTop);
    printf("04. ratio of write misses:                   %.2f%%\n", writeMissRatioTop);
    printf("05. ratio miss rate:                         %.2f%%\n", missRateRatioTop);
    printf("06. ratio of evictionsTop:                   %.2f%%\n", evictionRatioTop);

    printf("============ Prefetch Stats (Ideal DATA Prefetching) ============\n");
    printf("01. number of reads:                          %lu\n", getReadsPrefetch(cache));
    printf("02. number of read misses:                    %lu\n", getRMPrefetch(cache));
    printf("05. total miss rate:                          %.2f%%\n", missRatePrefetch);




    ulong  numVerticesMiss = 0;
    ulong  totalVerticesMiss = 0;
    // uint  maxVerticesMiss = 0;
    // uint  maxNode = 0;

    uint i;
    for(i = 0; i < cache->numVertices; i++)
    {
        if(cache->verticesMiss[i] > 100)
        {
            numVerticesMiss++;
            totalVerticesMiss += cache->verticesMiss[i];
        }
    }


    float MissNodesRatioReadMisses = (((double)numVerticesMiss / cache->numVertices) * 100.0);
    float ratioReadMissesMissNodes = (((double)totalVerticesMiss / getRM(cache)) * 100.0);

    printf("============ Graph Stats (Nodes cause highest miss stats) ============\n");
    printf("01. number of nodes:                          %lu\n", numVerticesMiss);
    printf("02. number of read misses:                    %lu\n", totalVerticesMiss);
    printf("03. ratio from total nodes :                  %.2f%%\n", MissNodesRatioReadMisses);
    printf("04. ratio from total read misses:             %.2f%%\n", ratioReadMissesMissNodes);



    // char *fname_txt = (char *) malloc((strlen(fname) + 20) * sizeof(char));
    // char *fname_topMisses = (char *) malloc((strlen(fname) + 20) * sizeof(char));


    // fname_txt = strcpy (fname_txt, fname);
    // fname_topMisses  = strcat (fname_txt, ".top");// out-degree

    // FILE *fptr;
    // fptr = fopen(fname_topMisses, "w");

    // for(i = 0; i < numVertices; i++)
    // {
    //     if(verticesMiss[i] > 100)
    //         fprintf(fptr, "%u %u\n", i, verticesMiss[i]);
    // }

    // fclose(fptr);


}