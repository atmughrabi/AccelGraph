#ifndef EDGELIST_H
#define EDGELIST_H
#include <linux/types.h>
// A structure to represent an edge
struct Edge {

	int dest;
	int src;
	int weight;

};


struct EdgeList {

	int num_edges;
	struct Edge* edges_array;
	// struct Edge* edges_sorted;

};

void edgeListPrint(struct EdgeList* edgeList);

struct EdgeList* readEdgeListstxt(const char * fname);

struct EdgeList* readEdgeListsbin(const char * fname);

struct EdgeList* newEdgeList( int size);

#endif