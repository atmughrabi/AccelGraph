#ifndef GRAPHADJARRAYLIST_H
#define GRAPHADJARRAYLIST_H

#include <linux/types.h>
#include "adjArrayList.h"
#include "edgeList.h"

// // A structure to represent an adjacency list
// struct  AdjArrayList {

// 	__u8 visited;
// 	__u32 out_degree;
// 	struct Edge* outNodes;

// 	#if DIRECTED
// 		__u32 in_degree;
// 		struct Edge* inNodes;
// 	#endif

// };


// struct   Edge {

// 	__u32 dest;
// 	__u32 src;
// 	#ifdef WEIGHTED
// 	__u32 weight;
// 	#endif

// };



// A structure to represent a GraphAdjArrayList. A GraphAdjArrayList
// is an array of adjacency lists.
// Size of array will be V (number of vertices 
// in GraphAdjArrayList)
struct  GraphAdjArrayList
{
	__u32 num_vertices;
	__u32 num_edges;
	__u32 iteration;
	__u32 processed_nodes;
	int* parents;
	struct AdjArrayList* vertices;

	
};


// A utility function that creates a GraphAdjArrayList of V vertices
void graphAdjArrayListPrintMessageWithtime(const char * msg, double time);
void graphAdjArrayListReset(struct GraphAdjArrayList* graphAdjArrayList);
struct GraphAdjArrayList* graphAdjArrayListGraphNew(__u32 V);
struct GraphAdjArrayList* graphAdjArrayListEdgeListNew(struct EdgeList* edgeList);
struct GraphAdjArrayList* graphAdjArrayListEdgeListNewWithInverse(struct EdgeList* edgeList, struct EdgeList* inverseEdgeList);
void graphAdjArrayListPrint(struct GraphAdjArrayList* graphAdjArrayList);
void graphAdjArrayListFree(struct GraphAdjArrayList* graphAdjArrayList);
struct GraphAdjArrayList* graphAdjArrayListEdgeListProcessInOutDegree(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList);
struct GraphAdjArrayList* graphAdjArrayListEdgeListProcessOutDegree(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList);
struct GraphAdjArrayList* graphAdjArrayListEdgeListProcessInDegree(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* inverseEdgeList);
struct GraphAdjArrayList* graphAdjArrayListEdgeAllocate(struct GraphAdjArrayList* graphAdjArrayList);
struct GraphAdjArrayList* graphAdjArrayListEdgePopulate(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList);
struct GraphAdjArrayList* graphAdjArrayListEdgePopulateOutNodes(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList);
struct GraphAdjArrayList* graphAdjArrayListEdgePopulateInNodes(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* inverseEdgeList);
struct GraphAdjArrayList* graphAdjArrayListPreProcessingStep (const char * fnameb, __u32 sort,  __u32 lmode);
#endif