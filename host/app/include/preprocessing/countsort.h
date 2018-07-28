#ifndef COUNTSORT_H
#define COUNTSORT_H

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

struct GraphCountSorted{

	__u32 num_edges;
	__u32 num_vertices;
	__u32* vertex_count; // needed for counting sort
	struct Vertex* vertices;
	struct Edge* sorted_edges_array; // sorted edge array


};


void CountSortedGraphPrint(struct GraphCountSorted* graph);

struct GraphCountSorted* countSortMapVertices (struct GraphCountSorted* graph);
struct GraphCountSorted* GraphCountSortedCreateGraph(__u32 V, __u32 E);
struct GraphCountSorted* countSortEdgesBySource (struct EdgeList* edgeList);
struct GraphCountSorted* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList);


#endif