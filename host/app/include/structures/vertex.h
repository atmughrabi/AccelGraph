#ifndef VERTEX_H
#define VERTEX_H

#define NO_OUTGOING_EDGES -1
#define NO_INCOMING_EDGES -1
#define NOT_VISITED -1


struct Vertex {

	// int visited;
	// int vertex_id;
	int edges_idx;
	// int out_degree;
	// int in_degree;

};


struct Vertex* newVertexArray(__u32 num_vertices);
void freeVertexArray(struct Vertex* vertices);

#endif