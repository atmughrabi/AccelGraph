#ifndef BFS_H
#define BFS_H

#include "graphCSR.h"
#include "arrayQueue.h"
#include "graphGrid.h"


void bfs(__u32 source, struct GraphCSR* graph);

void breadthFirstSearchGraphCSR(__u32 source, struct GraphCSR* graph);
__u32 topDownStepGraphCSR(struct GraphCSR* graph, struct ArrayQueue* frontier);
__u32 bottomUpStepGraphCSR(struct GraphCSR* graph, struct ArrayQueue* frontier);


void breadthFirstSearchGraphGrid(__u32 source, struct GraphGrid* graph);
void breadthFirstSearchStreamEdgesGraphGrid(struct GraphGrid* graph, struct ArrayQueue* frontier);
void breadthFirstSearchPartitionGraphGrid(struct GraphGrid* graph,struct Partition* partition,struct ArrayQueue* frontier);
void breadthFirstSearchSetActivePartitions(struct GraphGrid* graph, struct ArrayQueue* frontier);

#endif