#ifndef COUNTSORT_H
#define COUNTSORT_H

#include "edgeList.h"
#include "vertex.h"
#include "graphCSR.h"

// A structure to represent an edge



struct GraphCSR* countSortEdgesBySource (struct EdgeList* edgeList);
struct GraphCSR* countSortEdgesBySourceAndDestination (struct EdgeList* edgeList);


#endif