#ifndef RADIXSORT_H
#define RADIXSORT_H

#include "edgeList.h"
#include "vertex.h"
#include "graphCSR.h"

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




struct GraphCSR* radixSortCountSortEdgesBySource (struct GraphCSR* graph, struct EdgeList* edgeList, int exp);
struct GraphCSR* radixSortEdgesBySource (struct GraphCSR* graph, struct EdgeList* edgeList);
struct GraphCSR* radixSortEdgesBySourceOptimized (struct GraphCSR* graph, struct EdgeList* edgeList, __u8 inverse);
struct GraphCSR* radixSortEdgesBySourceAndDestination (struct GraphCSR* graph, struct EdgeList* edgeList, __u8 inverse);

#endif