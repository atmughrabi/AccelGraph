#ifndef COUNTSORT_H
#define COUNTSORT_H

#include "edgelist.h"
#include "vertex.h"
#include "graph.h"

// A structure to represent an edge



struct Graph* countSortEdgesBySource (struct EdgeList* edgeList);
struct Graph* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList);


#endif