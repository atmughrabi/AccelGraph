#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "adjLinkedList.h"
#include "myMalloc.h"
#include "graphConfig.h"

// A utility function to create a new adjacency list node
struct AdjLinkedListNode* newAdjLinkedListOutNode(struct Edge * edge){

	// struct AdjLinkedListNode* newNode = (struct AdjLinkedListNode*) aligned_alloc(CACHELINE_BYTES, sizeof(struct AdjLinkedListNode));
    struct AdjLinkedListNode* newNode = (struct AdjLinkedListNode*) my_malloc(sizeof(struct AdjLinkedListNode));
    

	newNode->dest = edge->dest;
    // newNode->src = src;
    #if WEIGHTED
     newNode->weight = edge->weight;
    #endif
     
	newNode->next = NULL;

	return newNode;

}


struct AdjLinkedListNode* newAdjLinkedListInNode(struct Edge * edge){

    // struct AdjLinkedListNode* newNode = (struct AdjLinkedListNode*) aligned_alloc(CACHELINE_BYTES, sizeof(struct AdjLinkedListNode));
    struct AdjLinkedListNode* newNode = (struct AdjLinkedListNode*) my_malloc(sizeof(struct AdjLinkedListNode));
    

    newNode->dest = edge->src;
    // newNode->src = src;
    #if WEIGHTED
     newNode->weight = edge->weight;
    #endif
     
    newNode->next = NULL;

    return newNode;

}