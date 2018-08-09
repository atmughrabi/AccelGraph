#ifndef RADIXSORT_H
#define RADIXSORT_H
#include <linux/types.h>
#include "edgeList.h"



struct EdgeList* radixSortCountSortEdgesBySource (struct Edge* sorted_edges_array, struct EdgeList* edgeList, int exp, __u32* vertex_count);
struct EdgeList* radixSortEdgesBySource (struct EdgeList* edgeList);
struct EdgeList* radixSortEdgesBySourceAndDestination (struct EdgeList* edgeList);
struct EdgeList* radixSortEdgesBySourceOptimized (struct EdgeList* edgeList);

#endif