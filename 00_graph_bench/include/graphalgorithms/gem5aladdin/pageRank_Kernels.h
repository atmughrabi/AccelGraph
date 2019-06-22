#ifndef PAGERANK_KERNELS_H
#define PAGERANK_KERNELS_H

#include <linux/types.h>
#include "cache.h"

// ********************************************************************************************
// ***************          GRID DataStructure               **************
// ********************************************************************************************

void pageRankPullRowGraphGridKernelAladdin(float *riDividedOnDiClause_pull_grid, float *pageRanksNext_pull_grid,  struct Partition *partitions, __u32 totalPartitions);
// ********************************************************************************************
void pageRankPushColumnGraphGridKernelAladdin(float *riDividedOnDiClause_push_grid, float *pageRanksNext_push_grid,  struct Partition *partitions, __u32 totalPartitions);

// ********************************************************************************************
// ***************          CSR DataStructure                                    **************
// ********************************************************************************************

void pageRankPullGraphCSRKernelAladdin(float *riDividedOnDiClause_pull_csr, float *pageRanksNext_pull_csr, __u32 *out_degree_pull_csr, __u32 *edges_idx_pull_csr, __u32 *sorted_edges_array_pull_csr, __u32 num_vertices);
void pageRankPullGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankPushGraphCSRKernelAladdin(float *riDividedOnDiClause_push_csr, float *pageRanksNext_push_csr, __u32 *out_degree_push_csr, __u32 *edges_idx_push_csr, __u32 *sorted_edges_array_push_csr, __u32 num_vertices);
void pageRankPushGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankPullFixedPointGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_pull_csr_fp, __u64 *pageRanksNext_pull_csr_fp, __u32 *out_degree_pull_csr_fp, __u32 *edges_idx_pull_csr_fp, __u32 *sorted_edges_array_pull_csr_fp, __u32 num_vertices);
void pageRankPullFixedPointGraphCSRKernelCache(struct DoubleTaggedCache *cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
void pageRankPushFixedPointGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_push_csr_fp, __u64 *pageRanksNext_push_csr_fp, __u32 *out_degree_push_csr_fp, __u32 *edges_idx_push_csr_fp, __u32 *sorted_edges_array_push_csr_fp, __u32 num_vertices);
void pageRankPushFixedPointGraphCSRKernelCache(struct DoubleTaggedCache *cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices);
// ********************************************************************************************
__u32 pageRankDataDrivenPullGraphCSRKernelAladdin(float *riDividedOnDiClause_dd_pull_csr, float *pageRanks_dd_pull_csr,
        __u32 *in_degree_dd_pull_csr, __u32 *in_edges_idx_dd_pull_csr, __u32 *in_sorted_edges_array_dd_pull_csr,
        __u32 *out_degree_dd_pull_csr, __u32 *out_edges_idx_dd_pull_csr, __u32 *out_sorted_edges_array_dd_pull_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices);
__u32 pageRankDataDrivenPullGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *riDividedOnDiClause_dd_pull_csr, float *pageRanks_dd_pull_csr,
        __u32 *in_degree_dd_pull_csr, __u32 *in_edges_idx_dd_pull_csr, __u32 *in_sorted_edges_array_dd_pull_csr,
        __u32 *out_degree_dd_pull_csr, __u32 *out_edges_idx_dd_pull_csr, __u32 *out_sorted_edges_array_dd_pull_csr,
        __u8  *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices);
// ********************************************************************************************
__u32 pageRankDataDrivenPushGraphCSRKernelAladdin(float *aResiduals_dd_push_csr, float *pageRanks_dd_push_csr,
        __u32 *out_degree_dd_push_csr, __u32 *out_edges_idx_dd_push_csr, __u32 *out_sorted_edges_array_dd_push_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices);
__u32 pageRankDataDrivenPushGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *aResiduals_dd_push_csr, float *pageRanks_dd_push_csr,
        __u32 *out_degree_dd_push_csr, __u32 *out_edges_idx_dd_push_csr, __u32 *out_sorted_edges_array_dd_push_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices);
// ********************************************************************************************
__u32 pageRankDataDrivenPullPushGraphCSRKernelAladdin(float *riDividedOnDiClause_dd_pullpush_csr, float *pageRanks_dd_pullpush_csr,
        __u32 *in_degree_dd_pullpush_csr, __u32 *in_edges_idx_dd_pullpush_csr, __u32 *in_sorted_edges_array_dd_pullpush_csr,
        __u32 *out_degree_dd_pullpush_csr, __u32 *out_edges_idx_dd_pullpush_csr, __u32 *out_sorted_edges_array_dd_pullpush_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices);
__u32 pageRankDataDrivenPullPushGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *riDividedOnDiClause_dd_pullpush_csr, float *pageRanks_dd_pullpush_csr,
        __u32 *in_degree_dd_pullpush_csr, __u32 *in_edges_idx_dd_pullpush_csr, __u32 *in_sorted_edges_array_dd_pullpush_csr,
        __u32 *out_degree_dd_pullpush_csr, __u32 *out_edges_idx_dd_pullpush_csr, __u32 *out_sorted_edges_array_dd_pullpush_csr,
        __u8  *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices);
// ********************************************************************************************


#endif