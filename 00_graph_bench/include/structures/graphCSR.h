#ifndef GRAPHCSR_H
#define GRAPHCSR_H

#include <linux/types.h>
#include "edgeList.h"
#include "vertex.h"
#include "graphConfig.h"

struct GraphCSR
{

    __u32 num_edges;
    __u32 num_vertices;

#if WEIGHTED
    __u32 max_weight;
#endif
 
    struct Vertex *vertices;
    struct EdgeList *sorted_edges_array; // sorted edge array

#if DIRECTED
    struct Vertex *inverse_vertices;
    struct EdgeList *inverse_sorted_edges_array; // sorted edge array
#endif
};

void graphCSRFree (struct GraphCSR *graphCSR);
void graphCSRPrint (struct GraphCSR *graphCSR);
struct GraphCSR *graphCSRAssignEdgeList (struct GraphCSR *graphCSR, struct EdgeList *edgeList, __u8 inverse);
struct GraphCSR *graphCSRNew(__u32 V, __u32 E,  __u8 inverse);
struct GraphCSR *graphCSRPreProcessingStep (const char *fnameb, __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted);
void graphCSRPrintMessageWithtime(const char *msg, double time);
struct GraphCSR *readFromBinFileGraphCSR (const char *fname);
void writeToBinFileGraphCSR (const char *fname, struct GraphCSR *graph);

#endif