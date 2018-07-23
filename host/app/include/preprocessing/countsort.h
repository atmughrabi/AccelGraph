#ifndef COUNTSORT_H
#define COUNTSORT_H

#include "edgelist.h"

// A structure to represent an edge
// struct Edge {

// 	int dest;
// 	int src;
// 	int weight;

// };


// struct EdgeList {

// 	int num_edges;
// 	struct Edge* edges_array;
// 	// struct Edge* edges_sorted;

// };

struct GraphCountSorted{

	int num_edges;
	int num_vertices;
	int* vertex_count; // needed for counting sort
	struct Edge* sorted_edges_array; // sorted edge array


}

struct GraphCountSorted* countSortEdgesBySource (struct EdgeList* edgeList);
struct GraphCountSorted* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList);


#endif