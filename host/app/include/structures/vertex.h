#ifndef VERTEX_H
#define VERTEX_H

#define NO_OUTGOING_EDGES -1
#define NO_INCOMING_EDGES -1
#define NOT_VISITED -1

#include "graph.h"

struct __attribute__((__packed__)) Vertex {

	__u8 visited;
	__u32 out_degree;
	__u32 in_degree;
	int edges_idx;
};


struct Graph* mapVertices (struct Graph* graph);
struct Vertex* newVertexArray(__u32 num_vertices);
void freeVertexArray(struct Vertex* vertices);

#endif