#ifndef GRAPHADJARRAYLIST_H
#define GRAPHADJARRAYLIST_H

#include <linux/types.h>
#include "adjArrayList.h"
#include "edgeList.h"

// // A structure to represent an adjacency list
// struct __attribute__((__packed__)) AdjArrayList {

// 	__u8 visited;
// 	__u32 out_degree;
// 	struct Edge* outNodes;

// 	#if DIRECTED
// 		__u32 in_degree;
// 		struct Edge* inNodes;
// 	#endif

// };


// struct  __attribute__((__packed__)) Edge {

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
struct __attribute__((__packed__)) GraphAdjArrayList
{
	__u32 num_vertices;
	__u32 num_edges;
	struct AdjArrayList* parent_array;
	
};


// A utility function that creates a GraphAdjArrayList of V vertices
struct GraphAdjArrayList* graphAdjArrayListGraphNew(__u32 V);
struct GraphAdjArrayList* graphAdjArrayListEdgeListNew(struct EdgeList* edgeList);
void graphAdjArrayListPrint(struct GraphAdjArrayList* graphAdjArrayList);
void graphAdjArrayListFree(struct GraphAdjArrayList* graphAdjArrayList);
struct GraphAdjArrayList* graphAdjArrayListEdgeListProcessInOutDegree(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList);
struct GraphAdjArrayList* graphAdjArrayListEdgeAllocate(struct GraphAdjArrayList* graphAdjArrayList);
struct GraphAdjArrayList* graphAdjArrayListEdgePopulate(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList);

#endif