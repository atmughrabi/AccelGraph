#ifndef GRAPHADJARRAYLIST_H
#define GRAPHADJARRAYLIST_H

#include <linux/types.h>
#include "adjArrayList.h"
#include "edgeList.h"


// A structure to represent a GraphAdjArrayList. A GraphAdjArrayList
// is an array of adjacency lists.
// Size of array will be V (number of vertices
// in GraphAdjArrayList)
struct  GraphAdjArrayList
{
    __u32 num_vertices;
    __u32 num_edges;

#if WEIGHTED
    __u32 max_weight;
#endif

    int *parents;
    __u32 iteration;
    __u32 processed_nodes;

    struct AdjArrayList *vertices;

};


// A utility function that creates a GraphAdjArrayList of V vertices
void graphAdjArrayListPrintMessageWithtime(const char *msg, double time);
void graphAdjArrayListReset(struct GraphAdjArrayList *graphAdjArrayList);
struct GraphAdjArrayList *graphAdjArrayListGraphNew(__u32 V);
struct GraphAdjArrayList *graphAdjArrayListEdgeListNew(struct EdgeList *edgeList);
struct GraphAdjArrayList *graphAdjArrayListEdgeListNewWithInverse(struct EdgeList *edgeList, struct EdgeList *inverseEdgeList);
void graphAdjArrayListPrint(struct GraphAdjArrayList *graphAdjArrayList);
void graphAdjArrayListFree(struct GraphAdjArrayList *graphAdjArrayList);
struct GraphAdjArrayList *graphAdjArrayListEdgeListProcessInOutDegree(struct GraphAdjArrayList *graphAdjArrayList, struct EdgeList *edgeList);
struct GraphAdjArrayList *graphAdjArrayListEdgeListProcessOutDegree(struct GraphAdjArrayList *graphAdjArrayList, struct EdgeList *edgeList);
struct GraphAdjArrayList *graphAdjArrayListEdgeListProcessInDegree(struct GraphAdjArrayList *graphAdjArrayList, struct EdgeList *inverseEdgeList);
struct GraphAdjArrayList *graphAdjArrayListEdgeAllocate(struct GraphAdjArrayList *graphAdjArrayList);
struct GraphAdjArrayList *graphAdjArrayListEdgePopulate(struct GraphAdjArrayList *graphAdjArrayList, struct EdgeList *edgeList);
struct GraphAdjArrayList *graphAdjArrayListEdgePopulateOutNodes(struct GraphAdjArrayList *graphAdjArrayList, struct EdgeList *edgeList);
struct GraphAdjArrayList *graphAdjArrayListEdgePopulateInNodes(struct GraphAdjArrayList *graphAdjArrayList, struct EdgeList *inverseEdgeList);
struct GraphAdjArrayList *graphAdjArrayListPreProcessingStep (const char *fnameb, __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted);
#endif