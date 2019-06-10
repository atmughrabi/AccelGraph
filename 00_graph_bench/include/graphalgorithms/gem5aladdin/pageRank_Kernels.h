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
void pageRankPullFixedPointGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_pull_csr_fp, __u64 *pageRanksNext_pull_csr_fp, __u32 *out_degree_pull_csr_fp, __u32 *edges_idx_pull_csr_fp, __u32 *sorted_edges_array_pull_csr_fp, __u32 num_vertices);
void pageRankPullFixedPointGraphCSRKernelCache(struct DoubleTaggedCache * cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankDataDrivenPullGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_push_csr_fp, __u64 *pageRanksNext_push_csr_fp, __u32 *out_degree_push_csr_fp, __u32 *edges_idx_push_csr_fp, __u32 *sorted_edges_array_push_csr_fp, __u32 num_vertices);
void pageRankDataDrivenPullGraphCSRKernelCache(struct DoubleTaggedCache * cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankDataDrivenPushGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_push_csr_fp, __u64 *pageRanksNext_push_csr_fp, __u32 *out_degree_push_csr_fp, __u32 *edges_idx_push_csr_fp, __u32 *sorted_edges_array_push_csr_fp, __u32 num_vertices);
void pageRankDataDrivenPushGraphCSRKernelCache(struct DoubleTaggedCache * cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankDataDrivenPullPushGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_push_csr_fp, __u64 *pageRanksNext_push_csr_fp, __u32 *out_degree_push_csr_fp, __u32 *edges_idx_push_csr_fp, __u32 *sorted_edges_array_push_csr_fp, __u32 num_vertices);
void pageRankDataDrivenPullPushGraphCSRKernelCache(struct DoubleTaggedCache * cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************

#endif