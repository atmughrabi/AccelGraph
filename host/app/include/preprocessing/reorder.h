#ifndef REORDER_H
#define REORDER_H

#include <linux/types.h>


struct EdgeList* reorderGraphList(struct GraphCSR* graph);
float* pageRankPullReOrderGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

#endif