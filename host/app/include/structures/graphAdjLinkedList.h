#ifndef GRAPHADJLINKEDLIST_H
#define GRAPHADJLINKEDLIST_H

#include <linux/types.h>
#include "adjLinkedList.h"
#include "edgeList.h"

// A structure to represent a GraphAdjLinkedList. A GraphAdjLinkedList
// is an array of adjacency lists.
// Size of array will be V (number of vertices 
// in GraphAdjLinkedList)
struct  GraphAdjLinkedList
{
	__u32 num_vertices;
	__u32 num_edges;
	__u32 iteration;
	__u32 processed_nodes;
	
	int * parents;
	struct AdjLinkedList* vertices;
	
};


// A utility function that creates a GraphAdjLinkedList of V vertices
struct GraphAdjLinkedList* graphAdjLinkedListGraphNew(__u32 V);
struct GraphAdjLinkedList* graphAdjLinkedListEdgeListNew(struct EdgeList* edgeList);
void graphAdjLinkedListReset(struct GraphAdjLinkedList* graphAdjLinkedList);
void graphAdjLinkedListPrint(struct GraphAdjLinkedList* graphAdjLinkedList);
void graphAdjLinkedListFree(struct GraphAdjLinkedList* graphAdjLinkedList);
void adjLinkedListAddEdge(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge);
void adjLinkedListAddEdgeUndirected(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge);
void adjLinkedListAddEdgeDirected(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge);
void   graphAdjLinkedListPrintMessageWithtime(const char * msg, double time);
struct GraphAdjLinkedList* graphAdjLinkedListPreProcessingStep (const char * fnameb);

#endif


