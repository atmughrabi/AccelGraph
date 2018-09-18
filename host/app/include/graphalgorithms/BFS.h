#ifndef BFS_H
#define BFS_H

#include "graphCSR.h"
#include "arrayQueue.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


void resetParentArray(int* parents, __u32 V);
void bfs(__u32 source, struct GraphCSR* graph);


void breadthFirstSearchGraphGrid(__u32 source, struct GraphGrid* graph);
void breadthFirstSearchStreamEdgesGraphGrid(struct GraphGrid* graph, struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue** localFrontierQueues);
void breadthFirstSearchPartitionGraphGrid(struct GraphGrid* graph,struct Partition* partition,struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue* localFrontierQueue);
void breadthFirstSearchSetActivePartitions(struct GraphGrid* graph, struct ArrayQueue* sharedFrontierQueue);


void breadthFirstSearchGraphCSR(__u32 source, struct GraphCSR* graph);
void breadthFirstSearchUsingBitmapsGraphCSR(__u32 source, struct GraphCSR* graph);
__u32 topDownStepGraphCSR(struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue,  struct ArrayQueue** localFrontierQueues);
__u32 topDownStepUsingBitmapsGraphCSR(struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue);
__u32 bottomUpStepGraphCSR(struct GraphCSR* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext);


void breadthFirstSearchGraphAdjArrayList(__u32 source, struct GraphAdjArrayList* graph);
__u32 bottomUpStepGraphAdjArrayList(struct GraphAdjArrayList* graph, struct ArrayQueue* sharedFrontierQueue);
__u32 topDownStepGraphAdjArrayList(struct GraphAdjArrayList* graph, struct ArrayQueue* sharedFrontierQueue);


void breadthFirstSearchGraphAdjLinkedList(__u32 source, struct GraphAdjLinkedList* graph);
__u32 bottomUpStepGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct ArrayQueue* sharedFrontierQueue);
__u32 topDownStepGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct ArrayQueue* sharedFrontierQueue);

#endif