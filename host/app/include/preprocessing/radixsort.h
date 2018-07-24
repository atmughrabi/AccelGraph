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

	int num_edges;
	int num_vertices;
	int* vertex_count; // needed for counting sort
	struct Vertex* vertices;
	struct Edge* sorted_edges_array; // sorted edge array


};


void RadixSortedGraphPrint(struct GraphRadixSorted* graph);
struct GraphRadixSorted* CountSortedgesBySource (struct GraphRadixSorted* graph,struct EdgeList* edgeList, int exp);
struct GraphRadixSorted* radixSortMapVertices (struct GraphRadixSorted* graph);
struct GraphRadixSorted* GraphRadixSortedCreateGraph(int V, int E);
struct GraphRadixSorted* RadixSortedgesBySource (struct EdgeList* edgeList);
struct GraphRadixSorted* RadixSortedgesBySourceAndDestination (struct EdgeList* edgeList);


#endif