#ifndef DFS_H
#define DFS_H

#include "graphCSR.h"
#include "arrayQueue.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void depthFirstSearchGraphCSR(__u32 source, struct GraphCSR* graph);
__u32 topDownStepDFSGraphCSR(struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue,  struct ArrayQueue** localFrontierQueues);
__u32 bottomUpStepDFSGraphCSR(struct GraphCSR* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext);

// ********************************************************************************************
// ***************		CSR DataStructure/Bitmap Frontiers						 **************
// ********************************************************************************************
void depthFirstSearchUsingBitmapsGraphCSR(__u32 source, struct GraphCSR* graph);
__u32 topDownStepDFSUsingBitmapsGraphCSR(struct GraphCSR* graph, struct ArrayQueue* sharedFrontierQueue);

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************


void depthFirstSearchGraphGrid(__u32 source, struct GraphGrid* graph);
void depthFirstSearchStreamEdgesGraphGrid(struct GraphGrid* graph, struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue** localFrontierQueues);
void depthFirstSearchPartitionGraphGrid(struct GraphGrid* graph,struct Partition* partition,struct ArrayQueue* sharedFrontierQueue, struct ArrayQueue* localFrontierQueue);
void depthFirstSearchSetActivePartitions(struct GraphGrid* graph, struct ArrayQueue* sharedFrontierQueue);


// ********************************************************************************************
// ***************					GRID DataStructure/Bitmap Frontiers			 **************
// ********************************************************************************************

void depthFirstSearchGraphGridBitmap(__u32 source, struct GraphGrid* graph);
void depthFirstSearchStreamEdgesGraphGridBitmap(struct GraphGrid* graph,struct Bitmap* FrontierBitmapCurr, struct Bitmap* FrontierBitmapNext);
void depthFirstSearchPartitionGraphGridBitmap(struct GraphGrid* graph,struct Partition* partition, struct Bitmap* FrontierBitmapCurr, struct Bitmap* FrontierBitmapNext);
void depthFirstSearchSetActivePartitionsBitmap(struct GraphGrid* graph,struct Bitmap* FrontierBitmap);


// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

void depthFirstSearchGraphAdjArrayList(__u32 source, struct GraphAdjArrayList* graph);
__u32 bottomUpStepDFSGraphAdjArrayList(struct GraphAdjArrayList* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext);
__u32 topDownStepDFSGraphAdjArrayList(struct GraphAdjArrayList* graph, struct ArrayQueue* sharedFrontierQueue,  struct ArrayQueue** localFrontierQueues);


// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************


void depthFirstSearchGraphAdjLinkedList(__u32 source, struct GraphAdjLinkedList* graph);
__u32 bottomUpStepDFSGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct Bitmap* bitmapCurr, struct Bitmap* bitmapNext);
__u32 topDownStepDFSGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct ArrayQueue* sharedFrontierQueue,  struct ArrayQueue** localFrontierQueues);

#endif