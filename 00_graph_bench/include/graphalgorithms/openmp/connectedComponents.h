#ifndef CONNECTEDCOMPONENTS_H
#define CONNECTEDCOMPONENTS_H

#include <linux/types.h>
#include "uthash.h"
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************
struct SampleCounts{
    __u32 id;            /* we'll use this field as the key */
    __u32 count;
    UT_hash_handle hh; /* makes this structure hashable */
};

struct CCStats
{

    __u32 iterations;
    __u32 num_vertices;
    __u32 *components;
    double time_total;
};

struct CCStats *newCCStatsGraphCSR(struct GraphCSR *graph);
struct CCStats *newCCStatsGraphGrid(struct GraphGrid *graph);
struct CCStats *newCCStatsGraphAdjArrayList(struct GraphAdjArrayList *graph);
struct CCStats *newCCStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph);

void freeCCStats(struct CCStats *stats);

// ********************************************************************************************
// ***************				Afforest Helper Functions						 **************
// ********************************************************************************************
int sortByCount( struct SampleCounts *sample1, struct SampleCounts *sample2);
void addSample(__u32 id, struct SampleCounts *sampleCounts);
void linkNodes(__u32 u, __u32 v, __u32 *components);
void compressNodes(__u32 num_vertices, __u32 *components);
__u32 sampleFrequentNode(__u32 num_vertices, __u32 num_samples, __u32 *components);



// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************




// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************




// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************





// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************


#endif