#ifndef ADJLIST_H
#define ADJLIST_H


// A structure to represent an adjacency list node
struct AdjListNode {

	int dest;
	struct AdjListNode* next;

};

// A structure to represent an adjacency list
struct AdjList {

	int neighbours;
	struct AdjListNode* head;

};

// A structure to represent a graph. A graph
// is an array of adjacency lists.
// Size of array will be V (number of vertices 
// in graph)
struct Graph
{
	int V;
	struct AdjList* array;
	
};


// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(int dest);
// A utility function that creates a graph of V vertices
struct Graph* adjlist_createGraph(int V);
// Adds an edge to an undirected graph
void adjlist_addEdge_undirected(struct Graph* graph, int src, int dest);
// Adds an edge to a directed graph
void adjlist_addEdge_directed(struct Graph* graph, int src, int dest);
// A utility function to print the adjacency list 
// representation of graph
void adjlist_printGraph(struct Graph* graph);


#endif