#ifndef PAGERANK_KERNELS_H
#define PAGERANK_KERNELS_H

#include <linux/types.h>
#include "cache.h"


// ********************************************************************************************
// ***************          CSR DataStructure                                    **************
// ********************************************************************************************

void pageRankPullGraphCSRKernelAladdin(float *riDividedOnDiClause_pull_csr, float *pageRanksNext_pull_csr, __u32 *out_degree_pull_csr, __u32 *edges_idx_pull_csr, __u32 *sorted_edges_array_pull_csr, __u32 num_vertices);
void pageRankPullGraphCSRKernelCache(struct DoubleTaggedCache * cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankPushGraphCSRKernelAladdin(float *riDividedOnDiClause_push_csr, float *pageRanksNext_push_csr, __u32 *out_degree_push_csr, __u32 *edges_idx_push_csr, __u32 *sorted_edges_array_push_csr, __u32 num_vertices);
void pageRankPushGraphCSRKernelCache(struct DoubleTaggedCache * cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************


#endif