#ifndef ADJLINKEDLIST_H
#define ADJLINKEDLIST_H

#include <linux/types.h>

#include "edgeList.h"
#include "graphConfig.h"
#include "graphCSR.h"


// A structure to represent an adjacency list
struct __attribute__((__packed__)) AdjArrayList {

	__u8 visited;
	__u32 out_degree;
	struct Edge* outNodes;

	#if DIRECTED
		__u32 in_degree;
		struct Edge* inNodes;
	#endif

};

// // A structure to represent a GraphAdjLinkedList. A GraphAdjLinkedList
// // is an array of adjacency lists.
// // Size of array will be V (number of vertices 
// // in GraphAdjLinkedList)
// struct __attribute__((__packed__)) GraphAdjLinkedList
// {
// 	__u32 num_vertices;
// 	__u32 num_edges;
// 	struct AdjLinkedList* parent_array;
	
// };



// A utility function to create a new adjacency list node
struct AdjArrayListNode* newAdjLinkedList(__u32 src, __u32 dest, __u32 weight);


#endif