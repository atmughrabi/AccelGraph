#ifndef SSSP_H
#define SSSP_H

#include <linux/types.h>
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"
#include "edgeList.h"

struct SSSPStats{
	__u32* Distances;
	__u32* parents;
	__u32  processed_nodes;
	__u32 num_vertices;
	double time_total;
};

// ********************************************************************************************
// ***************					Auxiliary functions  	  					 **************
// ********************************************************************************************
__u32 SSSPAtomicMin(__u32 *dist , __u32 new);
__u32 SSSPCompareDistanceArrays(struct SSSPStats* stats1, struct SSSPStats* stats2);
int SSSPAtomicRelax(struct Edge* edge, struct SSSPStats* stats, struct Bitmap* bitmapNext);
int SSSPRelax(struct Edge* edge, struct SSSPStats* stats, struct Bitmap* bitmapNext);
void durstenfeldShuffle(__u32* vertices, __u32 size);

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

void SSSPGraphGrid(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphGrid* graph, __u32 delta);
struct SSSPStats* SSSPPullRowGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph, __u32 delta);
struct SSSPStats* SSSPPushColumnGraphGrid(__u32 source,  __u32 iterations, struct GraphGrid* graph, __u32 delta);



// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void SSSPGraphCSR(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph, __u32 delta);

struct SSSPStats* SSSPDataDrivenPullGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph, __u32 delta);
struct SSSPStats* SSSPDataDrivenPushGraphCSR(__u32 source,  __u32 iterations, struct GraphCSR* graph, __u32 delta);
void SSSPSpiltGraphCSR(struct GraphCSR* graph, struct GraphCSR* graphPlus, struct GraphCSR* graphMinus, __u32 delta);

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

void SSSPGraphAdjArrayList(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList* graph, __u32 delta);

struct SSSPStats* SSSPDataDrivenPullGraphAdjArrayList(__u32 source,  __u32 iterations, struct GraphAdjArrayList* graph ,__u32 delta);
struct SSSPStats* SSSPDataDrivenPushGraphAdjArrayList(__u32 source,  __u32 iterations, struct GraphAdjArrayList* graph, __u32 delta);

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************

void SSSPGraphAdjLinkedList(__u32 source,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList* graph, __u32 delta);

struct SSSPStats* SSSPPullGraphAdjLinkedList(__u32 source,  __u32 iterations, struct GraphAdjLinkedList* graph,__u32 delta);
struct SSSPStats* SSSPPushGraphAdjLinkedList(__u32 source,  __u32 iterations, struct GraphAdjLinkedList* graph,__u32 delta);


#endif