#ifndef CONNECTEDCOMPONENTS_H
#define CONNECTEDCOMPONENTS_H

#include <linux/types.h>

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************

#ifndef HASHSIZE
#define HASHSIZE (1 << 16) // hash table size 256
#endif 
#define JUDYERROR_SAMPLE 1 

struct CCStats
{	
	__u32 alone;
    __u32 neighbor_rounds;
    __u32 iterations;
    __u32 num_vertices;
    __u32 *components;
    __u32 *counts;
    __u32 *labels;
    double time_total;
};

struct CCStats *newCCStatsGraphCSR(struct GraphCSR *graph);
struct CCStats *newCCStatsGraphGrid(struct GraphGrid *graph);
struct CCStats *newCCStatsGraphAdjArrayList(struct GraphAdjArrayList *graph);
struct CCStats *newCCStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph);
void printCCStats(struct CCStats *stats);
void freeCCStats(struct CCStats *stats);


void printComponents(struct CCStats *stats);
// ********************************************************************************************
// ***************				Afforest Helper Functions						 **************
// ********************************************************************************************

void addSample(__u32 id);
void linkNodes(__u32 u, __u32 v, __u32 *components);
void compressNodes(__u32 num_vertices, __u32 *components);
__u32 sampleFrequentNode(__u32 num_vertices, __u32 num_samples, __u32 *components);

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

struct CCStats *connectedComponentsGraphCSR(__u32 iterations, __u32 pushpull, struct GraphCSR *graph);
struct CCStats *connectedComponentsAfforestGraphCSR(__u32 iterations, struct GraphCSR *graph);
struct CCStats *connectedComponentsShiloachVishkinGraphCSR(__u32 iterations, struct GraphCSR *graph);



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