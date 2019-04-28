#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "adjLinkedList.h"
#include "myMalloc.h"
#include "graphConfig.h"

// A utility function to create a new adjacency list node
struct AdjLinkedListNode *newAdjLinkedListOutNode(__u32 dest)
{

    struct AdjLinkedListNode *newNode = (struct AdjLinkedListNode *) my_malloc(sizeof(struct AdjLinkedListNode));


    newNode->dest = dest;
#if WEIGHTED
    newNode->weight = 0;
#endif

    newNode->next = NULL;

    return newNode;

}


struct AdjLinkedListNode *newAdjLinkedListInNode( __u32 src)
{

    struct AdjLinkedListNode *newNode = (struct AdjLinkedListNode *) my_malloc(sizeof(struct AdjLinkedListNode));


    newNode->dest = src;
#if WEIGHTED
    newNode->weight = 0;
#endif

    newNode->next = NULL;

    return newNode;

}