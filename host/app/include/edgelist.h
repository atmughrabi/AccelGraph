#ifndef EDGELIST_H
#define EDGELIST_H
#include <linux/types.h>
// A structure to represent an edge
struct Edge {

	__u32 dest;
	__u32 src;
	int weight;

};


struct EdgeList {

	__u32 num_edges;
	struct Edge* edges_array;
	// struct Edge* edges_sorted;

};

void edgelist_print(struct EdgeList* edgeList);

struct EdgeList* read_edgelists(const char * fname);

#endif