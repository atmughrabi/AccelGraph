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
	// __u32* vertex_count; // needed for counting sort
	int* parents;       // specify parent for each vertex
	
	struct Vertex* vertices;
	struct Edge* sorted_edges_array; // sorted edge array

	#if DIRECTED
		struct Vertex* inverse_vertices;
		struct Edge* inverse_sorted_edges_array; // sorted edge array
	#endif

};

void graphCSRFree(struct GraphCSR* graphCSR);
void graphCSRPrint (struct GraphCSR* graphCSR);
struct GraphCSR* graphCSRAssignEdgeList (struct GraphCSR* graphCSR, struct EdgeList* edgeList, __u8 inverse);
void graphCSRPrintParentsArray(struct GraphCSR* graphCSR);
struct GraphCSR* graphCSRNew(__u32 V, __u32 E,  __u8 inverse);
struct GraphCSR* graphCSRPreProcessingStep (const char * fnameb);
void graphCSRPrintMessageWithtime(const char * msg, double time);

#endif