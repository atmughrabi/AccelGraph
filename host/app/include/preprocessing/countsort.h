#ifndef COUNTSORT_H
#define COUNTSORT_H

#include "edgeList.h"
#include "vertex.h"
#include "graphCSR.h"

// A structure to represent an edge



struct EdgeList* countSortEdgesBySource (struct EdgeList* edgeList);
struct EdgeList* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList);


#endif