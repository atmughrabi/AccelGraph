#ifndef BFS_H
#define BFS_H

#include "graphCSR.h"
#include "arrayQueue.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

void bfs(__u32 source, struct GraphCSR* graph);


void breadthFirstSearchGraphGrid(__u32 source, struct GraphGrid* graph);
void breadthFirstSearchStreamEdgesGraphGrid(struct GraphGrid* graph, struct ArrayQueue* frontier);
void breadthFirstSearchPartitionGraphGrid(struct GraphGrid* graph,struct Partition* partition,struct ArrayQueue* frontier);
void breadthFirstSearchSetActivePartitions(struct GraphGrid* graph, struct ArrayQueue* frontier);


void breadthFirstSearchGraphCSR(__u32 source, struct GraphCSR* graph);
__u32 topDownStepGraphCSR(struct GraphCSR* graph, struct ArrayQueue* frontier);
__u32 bottomUpStepGraphCSR(struct GraphCSR* graph, struct ArrayQueue* frontier);


void breadthFirstSearchGraphAdjArrayList(__u32 source, struct GraphAdjArrayList* graph);
__u32 bottomUpStepGraphAdjArrayList(struct GraphAdjArrayList* graph, struct ArrayQueue* frontier);
__u32 topDownStepGraphAdjArrayList(struct GraphAdjArrayList* graph, struct ArrayQueue* frontier);


void breadthFirstSearchGraphAdjLinkedList(__u32 source, struct GraphAdjLinkedList* graph);
__u32 bottomUpStepGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct ArrayQueue* frontier);
__u32 topDownStepGraphAdjLinkedList(struct GraphAdjLinkedList* graph, struct ArrayQueue* frontier);

#endif