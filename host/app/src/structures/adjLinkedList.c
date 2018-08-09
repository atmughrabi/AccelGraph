#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "adjLinkedList.h"
#include "myMalloc.h"
#include "graphConfig.h"

// A utility function to create a new adjacency list node
struct AdjLinkedListNode* newAdjLinkedListNode(__u32 src, __u32 dest, __u32 weight){

	// struct AdjLinkedListNode* newNode = (struct AdjLinkedListNode*) aligned_alloc(CACHELINE_BYTES, sizeof(struct AdjLinkedListNode));
    #if ALIGNED
        struct AdjLinkedListNode* newNode = (struct AdjLinkedListNode*) my_aligned_alloc(sizeof(struct AdjLinkedListNode));
    #else
        struct AdjLinkedListNode* newNode = (struct AdjLinkedListNode*) my_malloc(sizeof(struct AdjLinkedListNode));
    #endif

	newNode->dest = dest;
    // newNode->src = src;
    #if WEIGHTED
     newNode->weight = weight;
    #endif
     
	newNode->next = NULL;

	return newNode;

}
