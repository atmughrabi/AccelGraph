#ifndef GRAPH_H
#define GRAPH_H

#include "edgelist.h"
#include "vertex.h"

struct Graph{

	__u32 num_edges;
	__u32 num_vertices;
	__u32* vertex_count; // needed for counting sort
	struct Vertex* vertices;
	struct Edge* sorted_edges_array; // sorted edge array


};



void graphFree(struct Graph* graph);
void graphPrint (struct Graph* graph);
struct Graph* graphNew(__u32 V, __u32 E);

#endif