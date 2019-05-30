
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#include "myMalloc.h"
#include "fixedPoint.h"
#include "quantization.h"

#ifdef GEM5_HARNESS
#include "gem5/gem5_harness.h"
#endif

#include "cache.h"
#include "pageRank_Kernels.h"


// ********************************************************************************************
// ***************          GRID DataStructure               **************
// ********************************************************************************************




// ********************************************************************************************
// ***************          CSR DataStructure                                    **************
// ********************************************************************************************


void pageRankPullGraphCSRKernelAladdin(float *riDividedOnDiClause, float *pageRanksNext, __u32 *out_degree, __u32 *edges_idx, __u32 *sorted_edges_array, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
sum : for(v = 0; v < num_vertices; v++)
    {
        float nodeIncomingPR = 0.0f;
        degree = out_degree[v];
        edge_idx = edges_idx[v];

        for(j = edge_idx ; j <  (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array[j];
            nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
        }
        pageRanksNext[v] = nodeIncomingPR;
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
                Prefetch(cache->cache, (__u64) & (pageRanksNext[v + 1]), 'w', v);
            }
        }

        float nodeIncomingPR = 0.0f;
        degree = out_degree[v];
        edge_idx = edges_idx[v];

        Access(cache->cache, (__u64) & (out_degree[v]), 'r', v);
        Access(cache->cache, (__u64) & (edges_idx[v]), 'r', v);

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