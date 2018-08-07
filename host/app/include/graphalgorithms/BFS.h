#ifndef BFS_H
#define BFS_H


#include "graph.h"
#include "arrayqueue.h"

void bfs(__u32 start_vertex_idx, struct Graph* graph);
void breadthFirstSearch(__u32 start_vertex_idx, struct Graph* graph);
void topDownStep(struct Graph* graph, struct ArrayQueue* frontier);
void topDownStep_original(struct Graph* graph, struct ArrayQueue* frontier);
void bottomUpStep(struct Graph* graph, struct ArrayQueue* frontier);

#endif