#ifndef GRAPHCSR_H
#define GRAPHCSR_H

#include <linux/types.h>
#include "edgeList.h"
#include "vertex.h"
#include "graphConfig.h"

struct GraphCSR{

	__u32 num_edges;
	__u32 num_vertices;
	__u32 iteration;
	__u32 processed_nodes;
	#if WEIGHTED
	__u32 max_weight;
	#endif
	// __u32* vertex_count; // needed for counting sort
	int* parents;       // specify parent for each vertex
	
	struct Vertex* vertices;
	struct Edge* sorted_edges_array; // sorted edge array
	__u32* sorted_edge_array; // sorted edge array

	#if DIRECTED
		struct Vertex* inverse_vertices;
		struct Edge* inverse_sorted_edges_array; // sorted edge array
		__u32* inverse_sorted_edge_array; // sorted edge array
	#endif

};

void graphCSRReset(struct GraphCSR* graphCSR);
void graphCSRFree (struct GraphCSR* graphCSR);
void graphCSRFreeDoublePointer (struct GraphCSR** graphCSR);
void graphCSRPrint (struct GraphCSR* graphCSR);
struct GraphCSR* graphCSRAssignEdgeList (struct GraphCSR* graphCSR, struct EdgeList* edgeList, __u8 inverse);
void graphCSRPrintParentsArray(struct GraphCSR* graphCSR);
struct GraphCSR* graphCSRNew(__u32 V, __u32 E,  __u8 inverse);
struct GraphCSR* graphCSRPreProcessingStep (const char * fnameb, __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted);
void graphCSRPrintMessageWithtime(const char * msg, double time);
void graphCSRHardReset (struct GraphCSR* graphCSR);

#endif