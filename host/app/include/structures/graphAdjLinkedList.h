#ifndef GRAPHADJLINKEDLIST_H
#define GRAPHADJLINKEDLIST_H

#include <linux/types.h>
#include "adjLinkedList.h"
#include "edgeList.h"

// A structure to represent a GraphAdjLinkedList. A GraphAdjLinkedList
// is an array of adjacency lists.
// Size of array will be V (number of vertices 
// in GraphAdjLinkedList)
struct __attribute__((__packed__)) GraphAdjLinkedList
{
	__u32 num_vertices;
	__u32 num_edges;
	int * parents;
	struct AdjLinkedList* parent_array;
	
};


// A utility function that creates a GraphAdjLinkedList of V vertices
struct GraphAdjLinkedList* graphAdjLinkedListGraphNew(__u32 V);
struct GraphAdjLinkedList* graphAdjLinkedListEdgeListNew(struct EdgeList* edgeList);
void graphAdjLinkedListPrint(struct GraphAdjLinkedList* graphAdjLinkedList);
void graphAdjLinkedListFree(struct GraphAdjLinkedList* graphAdjLinkedList);
void adjLinkedListAddEdgeUndirected(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge);
void adjLinkedListAddEdgeDirected(struct GraphAdjLinkedList* graphAdjLinkedList, struct Edge * edge);
void   graphAdjLinkedListPrintMessageWithtime(const char * msg, double time);
struct GraphAdjLinkedList* graphAdjLinkedListPreProcessingStep (const char * fnameb);

#endif



