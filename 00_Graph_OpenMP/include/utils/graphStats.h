#ifndef GRAPHSTATS_H
#define GRAPHSTATS_H

#include <linux/types.h>
#include "graphCSR.h"

void collectStats( __u32 binSize, const char * fnameb,  __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted, __u32 inout_degree);
void countHistogram(struct GraphCSR* graphStats, __u32* histogram, __u32 binSize, __u32 inout_degree);
void printHistogram(const char * fname_stats, __u32* histogram, __u32 binSize, __u32 histSize);
void printSparseMatrixList(const char * fname_stats, struct EdgeList* newEdgeList, __u32 binSize);

#endif 

