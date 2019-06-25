
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#include "myMalloc.h"
#include "fixedPoint.h"
#include "quantization.h"

#include "graphGrid.h"

#ifdef GEM5_HARNESS
#include "gem5/gem5_harness.h"
#endif

#include "cache.h"
#include "pageRank_Kernels.h"

// you should add these to Aladdin as an extern "aladdin_sys_constants.h"
unsigned ACCELGRAPH = 0x300;
unsigned ACCELGRAPH_PAGERANK = 0x310;

// ********************************************************************************************
// ***************          GRID DataStructure               **************
// ********************************************************************************************

void pageRankPullRowGraphGridKernelAladdin(float *riDividedOnDiClause_pull_grid, float *pageRanksNext_pull_grid,  struct Partition *partitions, __u32 totalPartitions)
{

    __u32 i;
    for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
    {
        __u32 j;
iter :
        for (j = 0; j < totalPartitions; ++j)
        {
            __u32 k;
            __u32 src;
            __u32 dest;

            for (k = 0; k < partitions[(i * totalPartitions) + j].num_edges; ++k)
            {
                src  = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_src[k];
                dest = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_dest[k];

                pageRanksNext_pull_grid[dest] +=  riDividedOnDiClause_pull_grid[src];
            }
        }
    }
}

// ********************************************************************************************

void pageRankPullRowFixedPointGraphGridKernelAladdin(__u64 *riDividedOnDiClause_pull_grid_fp, __u64 *pageRanksNext_pull_grid_fp,  struct Partition *partitions, __u32 totalPartitions)
{

    __u32 i;
    for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
    {
        __u32 j;
iter :
        for (j = 0; j < totalPartitions; ++j)
        {
            __u32 k;
            __u32 src;
            __u32 dest;

            for (k = 0; k < partitions[(i * totalPartitions) + j].num_edges; ++k)
            {
                src  = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_src[k];
                dest = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_dest[k];

                pageRanksNext_pull_grid_fp[dest] +=  riDividedOnDiClause_pull_grid_fp[src];
            }
        }
    }
}

// ********************************************************************************************

void pageRankPushColumnGraphGridKernelAladdin(float *riDividedOnDiClause_push_grid, float *pageRanksNext_push_grid,  struct Partition *partitions, __u32 totalPartitions)
{

    __u32 j;
iter :
    for (j = 0; j < totalPartitions; ++j)
    {
        __u32 i;
        for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
        {
            __u32 k;
            __u32 src;
            __u32 dest;

            for (k = 0; k < partitions[(i * totalPartitions) + j].num_edges; ++k)
            {
                src  = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_src[k];
                dest = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_dest[k];

                pageRanksNext_push_grid[dest] +=  riDividedOnDiClause_push_grid[src];
            }
        }
    }
}

// ********************************************************************************************

void pageRankPushColumnFixedPointGraphGridKernelAladdin(__u64 *riDividedOnDiClause_push_grid_fp, __u64 *pageRanksNext_push_grid_fp,  struct Partition *partitions, __u32 totalPartitions)
{

    __u32 j;
iter :
    for (j = 0; j < totalPartitions; ++j)
    {
        __u32 i;
        for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
        {
            __u32 k;
            __u32 src;
            __u32 dest;

            for (k = 0; k < partitions[(i * totalPartitions) + j].num_edges; ++k)
            {
                src  = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_src[k];
                dest = (partitions[(i * totalPartitions) + j]).edgeList->edges_array_dest[k];

                pageRanksNext_push_grid_fp[dest] +=  riDividedOnDiClause_push_grid_fp[src];
            }
        }
    }
}

// ********************************************************************************************
// ***************          CSR DataStructure                                    **************
// ********************************************************************************************


void pageRankPullGraphCSRKernelAladdin(float *riDividedOnDiClause_pull_csr, float *pageRanksNext_pull_csr, __u32 *out_degree_pull_csr, __u32 *edges_idx_pull_csr, __u32 *sorted_edges_array_pull_csr, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;


iter :
    for(v = 0; v < num_vertices; v++)
    {
        float nodeIncomingPR = 0.0f;
        degree = out_degree_pull_csr[v];
        edge_idx = edges_idx_pull_csr[v];

        for(j = edge_idx ; j <  (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array_pull_csr[j];
            nodeIncomingPR += riDividedOnDiClause_pull_csr[u]; // pageRanks[v]/graph->vertices[v].out_degree;
        }
        pageRanksNext_pull_csr[v] = nodeIncomingPR;
    }
}

void pageRankPullGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices)
{


    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;

    for(v = 0; v < num_vertices; v++)
    {

#ifdef PREFETCH
        if((v + 1) < num_vertices)
        {
            edge_idx = edges_idx[v + 1];
            for(j = edge_idx ; j < (edge_idx + out_degree[v + 1]) ; j++)
            {
                u = sorted_edges_array[j];
                if(checkPrefetch(cache->doubleTag, (__u64) & (riDividedOnDiClause[u])))
                {
                    Prefetch(cache->cache, (__u64) & (riDividedOnDiClause[u]), 's', u);
                }
            }
            if(checkPrefetch(cache->doubleTag, (__u64) & (pageRanksNext[v + 1])))
            {
                Prefetch(cache->cache, (__u64) & (pageRanksNext[v + 1]), 'r', (v + 1));
            }
        }
#endif

        float nodeIncomingPR = 0.0f;
        degree = out_degree[v];
        edge_idx = edges_idx[v];

        // Access(cache->cache, (__u64) & (out_degree[v]), 'r', v);
        // Access(cache->cache, (__u64) & (edges_idx[v]), 'r', v);

        for(j = edge_idx ; j <  (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array[j];

            Access(cache->cache, (__u64) & (sorted_edges_array[j]), 'r', u);

            nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;

            Access(cache->cache, (__u64) & (riDividedOnDiClause[u]), 'r', u);
            Access(cache->doubleTag, (__u64) & (riDividedOnDiClause[u]), 'r', u);

        }

        pageRanksNext[v] = nodeIncomingPR;
        Access(cache->cache, (__u64) & (pageRanksNext[v]), 'r', v);
        Access(cache->cache, (__u64) & (pageRanksNext[v]), 'w', v);
        Access(cache->doubleTag, (__u64) & (pageRanksNext[v]), 'r', v);
    }


}


// ********************************************************************************************

void pageRankPushGraphCSRKernelAladdin(float *riDividedOnDiClause_push_csr, float *pageRanksNext_push_csr, __u32 *out_degree_push_csr, __u32 *edges_idx_push_csr, __u32 *sorted_edges_array_push_csr, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;


iter :
    for(v = 0; v < num_vertices; v++)
    {
        degree = out_degree_push_csr[v];
        edge_idx = edges_idx_push_csr[v];

        for(j = edge_idx ; j < (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array_push_csr[j];
            pageRanksNext_push_csr[u] += riDividedOnDiClause_push_csr[v];
        }
    }
}


void pageRankPushGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;

    for(v = 0; v < num_vertices; v++)
    {

#ifdef PREFETCH
        if((v + 1) < num_vertices)
        {
            edge_idx = edges_idx[v + 1];
            for(j = edge_idx ; j < (edge_idx + out_degree[v + 1]) ; j++)
            {
                u = sorted_edges_array[j];
                if(checkPrefetch(cache->doubleTag, (__u64) & (pageRanksNext[u])))
                {
                    Prefetch(cache->cache, (__u64) & (pageRanksNext[u]), 'r', u);
                }

            }

            if(checkPrefetch(cache->doubleTag, (__u64) & (riDividedOnDiClause[v + 1])))
            {
                Prefetch(cache->cache, (__u64) & (riDividedOnDiClause[v + 1]), 's', (v + 1));
            }
        }
#endif

        degree = out_degree[v];
        edge_idx = edges_idx[v];

        // Access(cache->cache, (__u64) & (out_degree[v]), 'r', v);
        // Access(cache->cache, (__u64) & (edges_idx[v]), 'r', v);

        for(j = edge_idx ; j < (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array[j];

            Access(cache->cache, (__u64) & (sorted_edges_array[j]), 'r', u);

            pageRanksNext[u] += riDividedOnDiClause[v];

            Access(cache->cache, (__u64) & (riDividedOnDiClause[v]), 'r', v);
            Access(cache->doubleTag, (__u64) & (riDividedOnDiClause[v]), 'r', v);

            Access(cache->cache, (__u64) & (pageRanksNext[u]), 'r', u);
            Access(cache->cache, (__u64) & (pageRanksNext[u]), 'w', u);
            Access(cache->doubleTag, (__u64) & (pageRanksNext[u]), 'r', u);
        }
    }
}

// ********************************************************************************************



void pageRankPullFixedPointGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_pull_csr_fp, __u64 *pageRanksNext_pull_csr_fp, __u32 *out_degree_pull_csr_fp, __u32 *edges_idx_pull_csr_fp, __u32 *sorted_edges_array_pull_csr_fp, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;


iter :
    for(v = 0; v < num_vertices; v++)
    {

        __u64 nodeIncomingPR = 0;
        degree = out_degree_pull_csr_fp[v];
        edge_idx = edges_idx_pull_csr_fp[v];

        for(j = edge_idx ; j <  (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array_pull_csr_fp[j];
            nodeIncomingPR += riDividedOnDiClause_pull_csr_fp[u]; // pageRanks[v]/graph->vertices[v].out_degree;
        }
        pageRanksNext_pull_csr_fp[v] = nodeIncomingPR;
    }

}

void pageRankPullFixedPointGraphCSRKernelCache(struct DoubleTaggedCache *cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices)
{


    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;

    for(v = 0; v < num_vertices; v++)
    {

#ifdef PREFETCH
        if((v + 1) < num_vertices)
        {
            edge_idx = edges_idx[v + 1];
            for(j = edge_idx ; j < (edge_idx + out_degree[v + 1]) ; j++)
            {
                u = sorted_edges_array[j];
                if(checkPrefetch(cache->doubleTag, (__u64) & (riDividedOnDiClause[u])))
                {
                    Prefetch(cache->cache, (__u64) & (riDividedOnDiClause[u]), 's', u);
                }
            }
            if(checkPrefetch(cache->doubleTag, (__u64) & (pageRanksNext[v + 1])))
            {
                Prefetch(cache->cache, (__u64) & (pageRanksNext[v + 1]), 'r', (v + 1));
            }
        }
#endif

        __u64 nodeIncomingPR = 0;
        degree = out_degree[v];
        edge_idx = edges_idx[v];

        // Access(cache->cache, (__u64) & (out_degree[v]), 'r', v);
        // Access(cache->cache, (__u64) & (edges_idx[v]), 'r', v);

        for(j = edge_idx ; j <  (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array[j];

            Access(cache->cache, (__u64) & (sorted_edges_array[j]), 'r', u);

            nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;

            Access(cache->cache, (__u64) & (riDividedOnDiClause[u]), 'r', u);
            Access(cache->doubleTag, (__u64) & (riDividedOnDiClause[u]), 'r', u);

        }

        pageRanksNext[v] = nodeIncomingPR;
        Access(cache->cache, (__u64) & (pageRanksNext[v]), 'r', v);
        Access(cache->cache, (__u64) & (pageRanksNext[v]), 'w', v);
        Access(cache->doubleTag, (__u64) & (pageRanksNext[v]), 'r', v);
    }


}


// ********************************************************************************************

void pageRankPushFixedPointGraphCSRKernelAladdin(__u64 *riDividedOnDiClause_push_csr_fp, __u64 *pageRanksNext_push_csr_fp, __u32 *out_degree_push_csr_fp, __u32 *edges_idx_push_csr_fp, __u32 *sorted_edges_array_push_csr_fp, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;


iter :
    for(v = 0; v < num_vertices; v++)
    {
        degree = out_degree_push_csr_fp[v];
        edge_idx = edges_idx_push_csr_fp[v];

        for(j = edge_idx ; j < (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array_push_csr_fp[j];
            pageRanksNext_push_csr_fp[u] += riDividedOnDiClause_push_csr_fp[v];
        }
    }
}


void pageRankPushFixedPointGraphCSRKernelCache(struct DoubleTaggedCache *cache, __u64 *riDividedOnDiClause, __u64 *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;

    for(v = 0; v < num_vertices; v++)
    {

#ifdef PREFETCH
        if((v + 1) < num_vertices)
        {
            edge_idx = edges_idx[v + 1];
            for(j = edge_idx ; j < (edge_idx + out_degree[v + 1]) ; j++)
            {
                u = sorted_edges_array[j];
                if(checkPrefetch(cache->doubleTag, (__u64) & (pageRanksNext[u])))
                {
                    Prefetch(cache->cache, (__u64) & (pageRanksNext[u]), 'r', u);
                }

            }

            if(checkPrefetch(cache->doubleTag, (__u64) & (riDividedOnDiClause[v + 1])))
            {
                Prefetch(cache->cache, (__u64) & (riDividedOnDiClause[v + 1]), 's', (v + 1));
            }
        }
#endif

        degree = out_degree[v];
        edge_idx = edges_idx[v];

        // Access(cache->cache, (__u64) & (out_degree[v]), 'r', v);
        // Access(cache->cache, (__u64) & (edges_idx[v]), 'r', v);

        for(j = edge_idx ; j < (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array[j];

            Access(cache->cache, (__u64) & (sorted_edges_array[j]), 'r', u);

            pageRanksNext[u] += riDividedOnDiClause[v];

            Access(cache->cache, (__u64) & (riDividedOnDiClause[v]), 'r', v);
            Access(cache->doubleTag, (__u64) & (riDividedOnDiClause[v]), 'r', v);

            Access(cache->cache, (__u64) & (pageRanksNext[u]), 'r', u);
            Access(cache->cache, (__u64) & (pageRanksNext[u]), 'w', u);
            Access(cache->doubleTag, (__u64) & (pageRanksNext[u]), 'r', u);
        }
    }
}

// ********************************************************************************************

__u32 pageRankDataDrivenPullGraphCSRKernelAladdin(float *riDividedOnDiClause_dd_pull_csr, float *pageRanks_dd_pull_csr,
        __u32 *in_degree_dd_pull_csr, __u32 *in_edges_idx_dd_pull_csr, __u32 *in_sorted_edges_array_dd_pull_csr,
        __u32 *out_degree_dd_pull_csr, __u32 *out_edges_idx_dd_pull_csr, __u32 *out_sorted_edges_array_dd_pull_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double damp = 0.85;
    double base_pr = 1 - damp;

iter:
    for(v = 0; v < num_vertices; v++)
    {
        if(workListCurr[v])
        {
            double error = 0;
            float nodeIncomingPR = 0;


            degree = in_degree_dd_pull_csr[v]; // when directed we use inverse graph out degree means in degree
            edge_idx = in_edges_idx_dd_pull_csr[v];


            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = in_sorted_edges_array_dd_pull_csr[j];
                nodeIncomingPR += riDividedOnDiClause_dd_pull_csr[u]; // sum (PRi/outDegree(i))
            }

            float oldPageRank =  pageRanks_dd_pull_csr[v];
            float newPageRank =  base_pr + (damp * nodeIncomingPR);
            error = fabs(newPageRank - oldPageRank);
            (*error_total) += error / num_vertices;

            if(error >= epsilon)
            {
                pageRanks_dd_pull_csr[v] = newPageRank;
                degree = out_degree_dd_pull_csr[v];
                edge_idx = out_edges_idx_dd_pull_csr[v];
                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = out_sorted_edges_array_dd_pull_csr[j];
                    workListNext[u] = 1;
                }

                activeVertices++;
            }
        }
    }


    return activeVertices;
}


// ********************************************************************************************

__u32 pageRankDataDrivenPullGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *riDividedOnDiClause_dd_pull_csr, float *pageRanks_dd_pull_csr,
        __u32 *in_degree_dd_pull_csr, __u32 *in_edges_idx_dd_pull_csr, __u32 *in_sorted_edges_array_dd_pull_csr,
        __u32 *out_degree_dd_pull_csr, __u32 *out_edges_idx_dd_pull_csr, __u32 *out_sorted_edges_array_dd_pull_csr,
        __u8  *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double damp = 0.85;
    double base_pr = 1 - damp;

    for(v = 0; v < num_vertices; v++)
    {

#ifdef PREFETCH
        if(workListCurr[v + 1])
            if((v + 1) < num_vertices)
            {
                degree = in_degree_dd_pull_csr[v + 1]; // when directed we use inverse graph out degree means in degree
                edge_idx = in_edges_idx_dd_pull_csr[v + 1];
                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = in_sorted_edges_array_dd_pull_csr[j];
                    if(checkPrefetch(cache->doubleTag, (__u64) & (riDividedOnDiClause_dd_pull_csr[u])))
                    {
                        Prefetch(cache->cache, (__u64) & (riDividedOnDiClause_dd_pull_csr[u]), 'r', u);
                    }

                }

                if(checkPrefetch(cache->doubleTag, (__u64) & (pageRanks_dd_pull_csr[v + 1])))
                {
                    Prefetch(cache->cache, (__u64) & (pageRanks_dd_pull_csr[v + 1]), 's', (v + 1));
                }
            }
#endif

        Access(cache->cache, (__u64) & (workListCurr[v]), 'r', v);
        if(workListCurr[v])
        {

            double error = 0;
            float nodeIncomingPR = 0;

            degree = in_degree_dd_pull_csr[v]; // when directed we use inverse graph out degree means in degree
            edge_idx = in_edges_idx_dd_pull_csr[v];
            // Access(cache->cache, (__u64) & (in_degree_dd_pull_csr[v]), 'r', v);
            // Access(cache->cache, (__u64) & (in_edges_idx_dd_pull_csr[v]), 'r', v);


            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = in_sorted_edges_array_dd_pull_csr[j];
                Access(cache->cache, (__u64) & (in_sorted_edges_array_dd_pull_csr[j]), 'r', u);


                nodeIncomingPR += riDividedOnDiClause_dd_pull_csr[u]; // sum (PRi/outDegree(i))
                Access(cache->cache, (__u64) & (riDividedOnDiClause_dd_pull_csr[u]), 'r', u);
                Access(cache->doubleTag, (__u64) & (riDividedOnDiClause_dd_pull_csr[u]), 'r', u);

            }

            float oldPageRank =  pageRanks_dd_pull_csr[v];
            Access(cache->cache, (__u64) & (pageRanks_dd_pull_csr[v]), 'r', v);
            Access(cache->doubleTag, (__u64) & (pageRanks_dd_pull_csr[v]), 'r', v);

            float newPageRank =  base_pr + (damp * nodeIncomingPR);
            error = fabs(newPageRank - oldPageRank);

            (*error_total) += error / num_vertices;
            Access(cache->cache, (__u64) & ((*error_total)), 'r', v);
            Access(cache->cache, (__u64) & ((*error_total)), 'w', v);

            if(error >= epsilon)
            {
                pageRanks_dd_pull_csr[v] = newPageRank;
                Access(cache->cache, (__u64) & (pageRanks_dd_pull_csr[v]), 'w', v);

                degree = out_degree_dd_pull_csr[v];
                edge_idx = out_edges_idx_dd_pull_csr[v];
                // Access(cache->cache, (__u64) & (out_degree_dd_pull_csr[v]), 'r', v);
                // Access(cache->cache, (__u64) & (out_edges_idx_dd_pull_csr[v]), 'r', v);

                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = out_sorted_edges_array_dd_pull_csr[j];
                    Access(cache->cache, (__u64) & (out_sorted_edges_array_dd_pull_csr[j]), 'r', u);

                    workListNext[u] = 1;
                    Access(cache->cache, (__u64) & (workListNext[u]), 'w', u);
                }

                activeVertices++;
            }
        }
    }


    return activeVertices;
}

// ********************************************************************************************

__u32 pageRankDataDrivenPushGraphCSRKernelAladdin(float *aResiduals_dd_push_csr, float *pageRanks_dd_push_csr,
        __u32 *out_degree_dd_push_csr, __u32 *out_edges_idx_dd_push_csr, __u32 *out_sorted_edges_array_dd_push_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double damp = 0.85;

iter:
    for(v = 0; v < num_vertices; v++)
    {
        if(workListCurr[v])
        {
            float oldPageRank =  pageRanks_dd_push_csr[v];
            float newPageRank =  aResiduals_dd_push_csr[v] + pageRanks_dd_push_csr[v];
            (*error_total) += fabs(newPageRank / num_vertices - oldPageRank / num_vertices);

            pageRanks_dd_push_csr[v] = newPageRank;

            degree = out_degree_dd_push_csr[v];
            float delta = damp * (aResiduals_dd_push_csr[v] / degree);

            edge_idx = out_edges_idx_dd_push_csr[v];

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = out_sorted_edges_array_dd_push_csr[j];
                float prevResidual = 0.0f;

                prevResidual = aResiduals_dd_push_csr[u];

                aResiduals_dd_push_csr[u] += delta;

                if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                {
                    activeVertices++;
                    if(!workListNext[u])
                    {
                        workListNext[u] = 1;
                    }
                }
            }
            aResiduals_dd_push_csr[v] = 0.0f;
        }
    }
    return activeVertices;
}

// ********************************************************************************************

__u32 pageRankDataDrivenPushGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *aResiduals_dd_push_csr, float *pageRanks_dd_push_csr,
        __u32 *out_degree_dd_push_csr, __u32 *out_edges_idx_dd_push_csr, __u32 *out_sorted_edges_array_dd_push_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double damp = 0.85;

    for(v = 0; v < num_vertices; v++)
    {

#ifdef PREFETCH
        if(workListCurr[v + 1])
            if((v + 1) < num_vertices)
            {
                degree = out_degree_dd_push_csr[v + 1]; // when directed we use inverse graph out degree means in degree
                edge_idx = out_edges_idx_dd_push_csr[v + 1];
                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = out_sorted_edges_array_dd_push_csr[j];
                    if(checkPrefetch(cache->doubleTag, (__u64) & (aResiduals_dd_push_csr[u])))
                    {
                        Prefetch(cache->cache, (__u64) & (aResiduals_dd_push_csr[u]), 'r', u);
                    }

                }

                if(checkPrefetch(cache->doubleTag, (__u64) & (aResiduals_dd_push_csr[v + 1])))
                {
                    Prefetch(cache->cache, (__u64) & (aResiduals_dd_push_csr[v + 1]), 's', (v + 1));
                }
            }
#endif

        Access(cache->cache, (__u64) & (workListCurr[v]), 'r', v);
        if(workListCurr[v])
        {
            float oldPageRank =  pageRanks_dd_push_csr[v];
            Access(cache->cache, (__u64) & (pageRanks_dd_push_csr[v]), 'r', v);
            Access(cache->doubleTag, (__u64) & (pageRanks_dd_push_csr[v]), 'r', v);

            float newPageRank =  aResiduals_dd_push_csr[v] + pageRanks_dd_push_csr[v];
            Access(cache->cache, (__u64) & (aResiduals_dd_push_csr[v]), 'r', v);
            Access(cache->doubleTag, (__u64) & (aResiduals_dd_push_csr[v]), 'r', v);

            (*error_total) += fabs(newPageRank / num_vertices - oldPageRank / num_vertices);

            pageRanks_dd_push_csr[v] = newPageRank;

            degree = out_degree_dd_push_csr[v];
            float delta = damp * (aResiduals_dd_push_csr[v] / degree);
            Access(cache->cache, (__u64) & (aResiduals_dd_push_csr[v]), 'r', v);
            Access(cache->cache, (__u64) & (out_degree_dd_push_csr[v]), 'r', v);

            edge_idx = out_edges_idx_dd_push_csr[v];

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = out_sorted_edges_array_dd_push_csr[j];
                float prevResidual = 0.0f;

                prevResidual = aResiduals_dd_push_csr[u];
                Access(cache->cache, (__u64) & (aResiduals_dd_push_csr[u]), 'r', u);
                Access(cache->doubleTag, (__u64) & (aResiduals_dd_push_csr[u]), 'r', u);

                aResiduals_dd_push_csr[u] += delta;
                Access(cache->cache, (__u64) & (aResiduals_dd_push_csr[u]), 'w', u);

                if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                {
                    activeVertices++;
                    if(!workListNext[u])
                    {
                        workListNext[u] = 1;
                        Access(cache->cache, (__u64) & (workListNext[u]), 'w', u);
                        Access(cache->doubleTag, (__u64) & (workListNext[u]), 'w', u);

                    }
                }
            }
            aResiduals_dd_push_csr[v] = 0.0f;
        }
    }
    return activeVertices;
}

// ********************************************************************************************

__u32 pageRankDataDrivenPullPushGraphCSRKernelAladdin(float *aResiduals_dd_pullpush_csr, float *pageRanks_dd_pullpush_csr,
        __u32 *in_degree_dd_pullpush_csr, __u32 *in_edges_idx_dd_pullpush_csr, __u32 *in_sorted_edges_array_dd_pullpush_csr,
        __u32 *out_degree_dd_pullpush_csr, __u32 *out_edges_idx_dd_pullpush_csr, __u32 *out_sorted_edges_array_dd_pullpush_csr,
        __u8 *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices)
{
    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double damp = 0.85;
    double base_pr = 1.0 - damp;

iter:
    for(v = 0; v < num_vertices; v++)
    {
        if(workListCurr[v])
        {
            float nodeIncomingPR = 0.0f;
            degree = in_degree_dd_pullpush_csr[v];
            edge_idx = in_edges_idx_dd_pullpush_csr[v];
            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = in_sorted_edges_array_dd_pullpush_csr[j];
                nodeIncomingPR += pageRanks_dd_pullpush_csr[u] / out_degree_dd_pullpush_csr[u];
            }

            float newPageRank = base_pr + (damp * nodeIncomingPR);
            float oldPageRank =  pageRanks_dd_pullpush_csr[v];

            (*error_total) += fabs(newPageRank / num_vertices - oldPageRank / num_vertices);

            pageRanks_dd_pullpush_csr[v] = newPageRank;

            degree = out_degree_dd_pullpush_csr[v];
            float delta = damp * (aResiduals_dd_pullpush_csr[v] / degree);
            edge_idx = out_edges_idx_dd_pullpush_csr[v];

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = out_sorted_edges_array_dd_pullpush_csr[j];
                float prevResidual = 0.0f;

                prevResidual = aResiduals_dd_pullpush_csr[u];

                aResiduals_dd_pullpush_csr[u] += delta;

                if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                {
                    activeVertices++;
                    if(!workListNext[u])
                    {
                        workListNext[u] = 1;
                    }
                }
            }
            aResiduals_dd_pullpush_csr[v] = 0.0f;
        }
    }
    return activeVertices;
}

// ********************************************************************************************

__u32 pageRankDataDrivenPullPushGraphCSRKernelCache(struct DoubleTaggedCache *cache, float *aResiduals_dd_pullpush_csr, float *pageRanks_dd_pullpush_csr,
        __u32 *in_degree_dd_pullpush_csr, __u32 *in_edges_idx_dd_pullpush_csr, __u32 *in_sorted_edges_array_dd_pullpush_csr,
        __u32 *out_degree_dd_pullpush_csr, __u32 *out_edges_idx_dd_pullpush_csr, __u32 *out_sorted_edges_array_dd_pullpush_csr,
        __u8  *workListCurr, __u8 *workListNext, double *error_total, double epsilon, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double damp = 0.85;
    double base_pr = 1 - damp;

    for(v = 0; v < num_vertices; v++)
    {

#ifdef PREFETCH
        if(workListCurr[v + 1])
            if((v + 1) < num_vertices)
            {
                degree = in_degree_dd_pullpush_csr[v + 1]; // when directed we use inverse graph out degree means in degree
                edge_idx = in_edges_idx_dd_pullpush_csr[v + 1];
                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = in_sorted_edges_array_dd_pullpush_csr[j];
                    if(checkPrefetch(cache->doubleTag, (__u64) & (pageRanks_dd_pullpush_csr[u])))
                    {
                        Prefetch(cache->cache, (__u64) & (pageRanks_dd_pullpush_csr[u]), 'r', u);
                    }

                    if(checkPrefetch(cache->doubleTag, (__u64) & (out_degree_dd_pullpush_csr[u])))
                    {
                        Prefetch(cache->cache, (__u64) & (out_degree_dd_pullpush_csr[u]), 'r', u);
                    }

                }

                if(checkPrefetch(cache->doubleTag, (__u64) & (aResiduals_dd_pullpush_csr[v + 1])))
                {
                    Prefetch(cache->cache, (__u64) & (aResiduals_dd_pullpush_csr[v + 1]), 's', (v + 1));
                }
            }
#endif

        Access(cache->cache, (__u64) & (workListCurr[v]), 'r', v);
        if(workListCurr[v])
        {
            float nodeIncomingPR = 0.0f;
            degree = in_degree_dd_pullpush_csr[v];
            edge_idx = in_edges_idx_dd_pullpush_csr[v];
            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = in_sorted_edges_array_dd_pullpush_csr[j];
                // Access(cache->cache, (__u64) & (in_sorted_edges_array_dd_pullpush_csr[j]), 'r', u);

                nodeIncomingPR += pageRanks_dd_pullpush_csr[u] / out_degree_dd_pullpush_csr[u];
                Access(cache->cache, (__u64) & (pageRanks_dd_pullpush_csr[u]), 'r', u);
                Access(cache->cache, (__u64) & (out_degree_dd_pullpush_csr[u]), 'r', u);

                Access(cache->doubleTag, (__u64) & (pageRanks_dd_pullpush_csr[u]), 'r', u);
                Access(cache->doubleTag, (__u64) & (out_degree_dd_pullpush_csr[u]), 'r', u);
            }

            float newPageRank = base_pr + (damp * nodeIncomingPR);
            float oldPageRank =  pageRanks_dd_pullpush_csr[v];
            Access(cache->cache, (__u64) & (pageRanks_dd_pullpush_csr[v]), 'r', v);
            Access(cache->doubleTag, (__u64) & (pageRanks_dd_pullpush_csr[v]), 'r', v);

            (*error_total) += fabs(newPageRank / num_vertices - oldPageRank / num_vertices);

            pageRanks_dd_pullpush_csr[v] = newPageRank;
            Access(cache->cache, (__u64) & (pageRanks_dd_pullpush_csr[v]), 'r', v);
            Access(cache->cache, (__u64) & (pageRanks_dd_pullpush_csr[v]), 'w', v);

            degree = out_degree_dd_pullpush_csr[v];
            float delta = damp * (aResiduals_dd_pullpush_csr[v] / degree);
            Access(cache->cache, (__u64) & (aResiduals_dd_pullpush_csr[v]), 'r', v);
            Access(cache->doubleTag, (__u64) & (aResiduals_dd_pullpush_csr[v]), 'r', v);

            edge_idx = out_edges_idx_dd_pullpush_csr[v];

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = out_sorted_edges_array_dd_pullpush_csr[j];
                // Access(cache->cache, (__u64) & (out_sorted_edges_array_dd_pullpush_csr[j]), 'r', u);

                float prevResidual = 0.0f;

                prevResidual = aResiduals_dd_pullpush_csr[u];
                Access(cache->cache, (__u64) & (aResiduals_dd_pullpush_csr[u]), 'r', u);
                Access(cache->doubleTag, (__u64) & (aResiduals_dd_pullpush_csr[u]), 'r', u);

                aResiduals_dd_pullpush_csr[u] += delta;
                Access(cache->cache, (__u64) & (aResiduals_dd_pullpush_csr[u]), 'w', u);


                if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                {
                    activeVertices++;

                    Access(cache->cache, (__u64) & (workListNext[u]), 'r', u);
                    Access(cache->doubleTag, (__u64) & (workListNext[u]), 'r', u);
                    if(!workListNext[u])
                    {
                        workListNext[u] = 1;
                        Access(cache->cache, (__u64) & (workListNext[u]), 'w', u);
                    }
                }
            }
            aResiduals_dd_pullpush_csr[v] = 0.0f;
            Access(cache->cache, (__u64) & (aResiduals_dd_pullpush_csr[v]), 'w', v);
            Access(cache->doubleTag, (__u64) & (aResiduals_dd_pullpush_csr[v]), 'w', v);
        }
    }

    return activeVertices;

}

// ********************************************************************************************