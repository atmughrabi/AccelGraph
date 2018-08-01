#ifndef ADJLIST_H
#define ADJLIST_H

#include "edgelist.h"
#include "graphconfig.h"

// A structure to represent an adjacency list node
struct __attribute__((__packed__)) AdjListNode {

	__u32 dest;
	__u32 src;

	#ifdef WEIGHTED
	__u32 weight;
	#endif

	struct AdjListNode* next;

};

// A structure to represent an adjacency list
struct AdjList {

	__u8 visited;
	__u32 out_degree;
	__u32 in_degree;
	struct AdjListNode* head;

};

// A structure to represent a GraphAdjList. A GraphAdjList
// is an array of adjacency lists.
// Size of array will be V (number of vertices 
// in GraphAdjList)
struct GraphAdjList
{
	__u32 V;
	__u32 num_edges;
	struct AdjList* parent_array;
	
};


// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(__u32 src, __u32 dest, __u32 weight);
// A utility function that creates a GraphAdjList of V vertices
struct GraphAdjList* adjListCreateGraphAdjList(__u32 V);

struct GraphAdjList* adjListCreateGraphAdjListEdgeList(struct EdgeList* edgeList);
// Adds an edge to an undirected GraphAdjList
void adjListAddEdgeUndirected(struct GraphAdjList* GraphAdjList, __u32 src, __u32 dest, __u32 weight);
// Adds an edge to a directed GraphAdjList
void adjListAddEdgeDirected(struct GraphAdjList* GraphAdjList, __u32 src, __u32 dest, __u32 weight);
// A utility function to print the adjacency list 
// representation of GraphAdjList
void adjListPrintGraphAdjList(struct GraphAdjList* GraphAdjList);

void adjListFreeGraphAdjList(struct GraphAdjList* GraphAdjList);


#endif