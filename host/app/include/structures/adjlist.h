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

// A structure to represent a graph. A graph
// is an array of adjacency lists.
// Size of array will be V (number of vertices 
// in graph)
struct Graph
{
	__u32 V;
	__u32 num_edges;
	struct AdjList* parent_array;
	
};


// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(__u32 src, __u32 dest, __u32 weight);
// A utility function that creates a graph of V vertices
struct Graph* adjListCreateGraph(__u32 V);

struct Graph* adjListCreateGraphEdgeList(struct EdgeList* edgeList);
// Adds an edge to an undirected graph
void adjListAddEdgeUndirected(struct Graph* graph, __u32 src, __u32 dest, __u32 weight);
// Adds an edge to a directed graph
void adjListAddEdgeDirected(struct Graph* graph, __u32 src, __u32 dest, __u32 weight);
// A utility function to print the adjacency list 
// representation of graph
void adjListPrintGraph(struct Graph* graph);

void adjListFreeGraph(struct Graph* graph);


#endif