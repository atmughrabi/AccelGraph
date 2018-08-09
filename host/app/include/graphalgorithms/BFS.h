#ifndef BFS_H
#define BFS_H

#include "graphCSR.h"
#include "arrayQueue.h"

void bfs(__u32 source, struct GraphCSR* graph);
void breadthFirstSearch(__u32 source, struct GraphCSR* graph);
void topDownStep_original(struct GraphCSR* graph, struct ArrayQueue* frontier);

__u32 topDownStep(struct GraphCSR* graph, struct ArrayQueue* frontier);
__u32 bottomUpStep(struct GraphCSR* graph, struct ArrayQueue* frontier);

#endif