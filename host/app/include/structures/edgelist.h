#ifndef EDGELIST_H
#define EDGELIST_H

#include <linux/types.h>
#include "graphconfig.h"
// A structure to represent an edge
struct  __attribute__((__packed__)) Edge {

	__u32 dest;
	__u32 src;
	#ifdef WEIGHTED
	__u32 weight;
	#endif

};


struct EdgeList {

	__u32 num_edges;
	__u32 num_vertices;
	struct Edge* edges_array;
	// struct Edge* edges_sorted;

};


// struct EdgeListAttributes {

// 	__u8 WEIGHTED;
// 	__u8 DIRECTED;

// };

__u32 maxTwoIntegers(__u32 num1, __u32 num2);

void edgeListPrint(struct EdgeList* edgeList);
void freeEdgeList( struct EdgeList* edgeList);
void freeEdgeArray(struct Edge* edges_array);

struct Edge* newEdgeArray(__u32 num_edges);
void readEdgeListstxt(const char * fname);
struct EdgeList* readEdgeListsbin(const char * fname, __u8 inverse);
struct EdgeList* newEdgeList(__u32 num_edges);

#endif