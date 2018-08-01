#ifndef RADIXSORT_H
#define RADIXSORT_H

#include "edgelist.h"
#include "vertex.h"
#include "graph.h"

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




struct Graph* radixSortCountSortEdgesBySource (struct Graph* graph,struct EdgeList* edgeList, int exp);
struct Graph* radixSortEdgesBySource (struct EdgeList* edgeList);
struct Graph* radixSortEdgesBySourceOptimized (struct EdgeList* edgeList);
struct Graph* radixSortEdgesBySourceAndDestination (struct EdgeList* edgeList);

#endif