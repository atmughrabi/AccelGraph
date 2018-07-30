#ifndef RADIXSORT_H
#define RADIXSORT_H

#include "edgelist.h"
#include "vertex.h"

// A structure to represent an edge
// struct Edge {

// 	int dest;
// 	int src;
// 	int weight;

// };


// struct EdgeList {

// 	int num_edges;
	// int num_vertices;
	// struct Edge* edges_array;

// };

struct GraphRadixSorted{

	__u32 num_edges;
	__u32 num_vertices;
	__u32* vertex_count; // needed for counting sort
	struct Vertex* vertices;
	struct Edge* sorted_edges_array; // sorted edge array


};


void radixSortedGraphPrint(struct GraphRadixSorted* graph);
struct GraphRadixSorted* radixSortCountSortEdgesBySource (struct GraphRadixSorted* graph,struct EdgeList* edgeList, int exp);
struct GraphRadixSorted* radixSortMapVertices (struct GraphRadixSorted* graph);
struct GraphRadixSorted* radixSortedCreateGraph(__u32 V, __u32 E);
void radixSortedFreeGraph (struct GraphRadixSorted* graph);
struct GraphRadixSorted* radixSortEdgesBySource (struct EdgeList* edgeList);
struct GraphRadixSorted* radixSortEdgesBySourceOptimized (struct EdgeList* edgeList);
struct GraphRadixSorted* radixSortEdgesBySourceAndDestination (struct EdgeList* edgeList);


#endif