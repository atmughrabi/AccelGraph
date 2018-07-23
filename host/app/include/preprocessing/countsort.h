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

struct GraphCountSorted* countSortEdgesBySource (struct EdgeList* edgeList);
struct GraphCountSorted* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList);


#endif