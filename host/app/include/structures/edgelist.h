#ifndef EDGELIST_H
#define EDGELIST_H
#include <linux/types.h>

// A structure to represent an edge
struct Edge {

	__u32 dest;
	__u32 src;
	__u32 weight;

};


struct EdgeList {

	__u32 num_edges;
	__u32 num_vertices;
	struct Edge* edges_array;
	// struct Edge* edges_sorted;

};


struct EdgeListAttributes {

	__u8 WEIGHTED;
	__u8 DIRECTED;

};

__u32 maxTwoIntegers(__u32 num1, __u32 num2);

void edgeListPrint(struct EdgeList* edgeList);

struct Edge* newEdgeArray(__u32 num_edges);

struct EdgeList* readEdgeListstxt(const char * fname,  struct EdgeListAttributes* attr);

struct EdgeList* readEdgeListsbin(const char * fname,  struct EdgeListAttributes* attr);

struct EdgeList* newEdgeList(__u32 num_edges);

#endif