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
	int num_vertices;
	struct Edge* edges_array;
	// struct Edge* edges_sorted;

};

int maxTwoIntegers(int num1, int num2);

void edgeListPrint(struct EdgeList* edgeList);

struct Edge* newEdgeArray(int num_edges);

struct EdgeList* readEdgeListstxt(const char * fname);

struct EdgeList* readEdgeListsbin(const char * fname);

struct EdgeList* newEdgeList(int num_edges);

#endif