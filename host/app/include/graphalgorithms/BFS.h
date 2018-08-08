#ifndef BFS_H
#define BFS_H


#include "graph.h"
#include "arrayqueue.h"

void bfs(__u32 source, struct Graph* graph);
void breadthFirstSearch(__u32 source, struct Graph* graph);
void topDownStep_original(struct Graph* graph, struct ArrayQueue* frontier);

__u32 topDownStep(struct Graph* graph, struct ArrayQueue* frontier);
__u32 bottomUpStep(struct Graph* graph, struct ArrayQueue* frontier);

#endif