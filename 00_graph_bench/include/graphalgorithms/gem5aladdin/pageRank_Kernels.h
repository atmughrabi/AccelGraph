#ifndef PAGERANK_KERNELS_H
#define PAGERANK_KERNELS_H

#include <linux/types.h>
#include "cache.h"


// ********************************************************************************************
// ***************          CSR DataStructure                                    **************
// ********************************************************************************************

void pageRankPullGraphCSRKernelAladdin(float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
void pageRankPullGraphCSRKernelCache(struct DoubleTaggedCache * cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankPushGraphCSRKernelAladdin(float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
void pageRankPushGraphCSRKernelCache(struct DoubleTaggedCache * cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************


#endif