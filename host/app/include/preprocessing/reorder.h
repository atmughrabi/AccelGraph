#ifndef REORDER_H
#define REORDER_H

#include <linux/types.h>


#define Damp 0.85f

struct EdgeList* reorderGraphList(struct GraphCSR* graph);
float* pageRankPullReOrderGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void radixSortCountSortEdgesByRanks (__u32** pageRanksFP, __u32** pageRanksFPTemp, __u32** labels, __u32** labelsTemp,__u32 radix, __u32 buckets, __u32* buckets_count, __u32 num_vertices);
__u32* radixSortEdgesByPageRank (float* pageRanks, __u32* labels, __u32 num_vertices);
struct EdgeList* relabelEdgeList(struct GraphCSR* graph, __u32* labels);
struct EdgeList* reorderPageRankGraphProcess(struct GraphCSR* graph, __u32 sort, struct EdgeList* edgeList);

#endif