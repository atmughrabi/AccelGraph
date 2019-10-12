#ifndef BFS_KERNELS_H
#define BFS_KERNELS_H

#include <linux/types.h>

#include "bitmap.h"
#include "cache.h"



// ********************************************************************************************
// ***************          CSR DataStructure                                    **************
// ********************************************************************************************

// __u32 topDownStepGraphCSRKernelAladdin(struct GraphCSR *graph, struct ArrayQueue *sharedFrontierQueue,  struct ArrayQueue **localFrontierQueues, struct BFSStats *stats);
__u32 bottomUpStepGraphCSRKernelAladdin( int *parents,  __u32 *distances, struct Bitmap *bitmapCurr, struct Bitmap *bitmapNext, __u32 *out_degree_pull_csr, __u32 *edges_idx_pull_csr, __u32 *sorted_edges_array_pull_csr, __u32 num_vertices);

#endif