#ifndef ADJLIST_H
#define ADJLIST_H


// A structure to represent an adjacency list node
struct AdjListNode {

	int dest;
	int src;
	int weight;
	struct AdjListNode* next;

};

// A structure to represent an adjacency list
struct AdjList {

	char visited;
	int out_degree;
	int in_degree;
	struct AdjListNode* head;

};

// A structure to represent a graph. A graph
// is an array of adjacency lists.
// Size of array will be V (number of vertices 
// in graph)
struct Graph
{
	int V;
	struct AdjList* parent_array;
	
};


// A utility function to create a new adjacency list node
struct AdjListNode* newAdjListNode(int src, int dest, int weight);
// A utility function that creates a graph of V vertices
struct Graph* adjListCreateGraph(int V);
// Adds an edge to an undirected graph
void adjListAddEdgeUndirected(struct Graph* graph, int src, int dest, int weight);
// Adds an edge to a directed graph
void adjListAddEdgeDirected(struct Graph* graph, int src, int dest, int weight);
// A utility function to print the adjacency list 
// representation of graph
void adjListPrintGraph(struct Graph* graph);


#endif