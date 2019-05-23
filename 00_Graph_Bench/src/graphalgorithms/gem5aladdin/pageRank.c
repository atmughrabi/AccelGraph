#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "bitmap.h"
#include "pageRank.h"

#include "fixedPoint.h"
#include "quantization.h"

#include "reorder.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

#include "cache.h"
#include "bloomMultiHash.h"

//gem5-aladdin
#ifdef DMA_MODE
#include "gem5/dma_interface.h"
#endif

#ifdef GEM5_HARNESS
#include "gem5/gem5_harness.h"
#endif

// ********************************************************************************************
// ***************          Auxilary functions                                   **************
// ********************************************************************************************

void addAtomicFloat(float *num, float value)
{

    float newV, oldV;
    __u32 *lnewV;
    __u32 *loldV;

    do
    {
        oldV = *num;
        newV = oldV + value;
        loldV = (__u32 *)&oldV;
        lnewV = (__u32 *)&newV;
    }
    while(!__sync_bool_compare_and_swap((__u32 *)num, *(loldV), *(lnewV)));

}


void addAtomicDouble(double *num, double value)
{

    double newV, oldV;
    __u64 *lnewV;
    __u64 *loldV;

    do
    {
        oldV = *num;
        newV = oldV + value;
        loldV = (__u64 *)&oldV;
        lnewV = (__u64 *)&newV;
    }
    while(!__sync_bool_compare_and_swap((__u64 *)num, *(loldV), *(lnewV)));

}


void swapWorkLists (__u8 **workList1, __u8 **workList2)
{


    __u8 *workList_temp = *workList1;
    *workList1 = *workList2;
    *workList2 = workList_temp;

}

void resetWorkList(__u8 *workList, __u32 size)
{

    __u32 i;

    #pragma omp parallel for
    for(i = 0; i < size ; i++)
    {
        workList[i] = 0;

    }


}

void setWorkList(__u8 *workList,  __u32 size)
{

    __u32 i;

    #pragma omp parallel for
    for(i = 0; i < size ; i++)
    {
        workList[i] = 1;

    }


}

void setAtomic(__u64 *num, __u64 value)
{


    __u64 newV, oldV;

    do
    {
        oldV = *num;
        newV = value;
    }
    while(!__sync_bool_compare_and_swap(num, oldV, newV));

}

void addAtomicFixedPoint(__u64 *num, __u64 value)
{

    __u64 newV, oldV;

    do
    {
        oldV = *num;
        newV = oldV + value;
    }
    while(!__sync_bool_compare_and_swap(num, oldV, newV));

}

void pageRankPrint(float *pageRankArray, __u32 num_vertices)
{
    __u32 v;
    for(v = 0; v < num_vertices; v++)
    {
        printf("Rank[%d]=%f \n", v, pageRankArray[v]);
    }
}

// ********************************************************************************************
// ***************          GRID DataStructure               **************
// ********************************************************************************************


// function STREAMVERTICES(Fv,F)
//  Sum = 0
//    for each vertex do
//      if F(vertex) then
//        Sum += Fv(edge)
//      end if
//    end for
//  return Sum
// end function

// function STREAMEDGES(Fe,F)
//  Sum = 0
//    for each active block do >> block with active edges
//      for each edge ∈ block do
//        if F(edge.source) then
//          Sum += Fe(edge)
//        end if
//      end for
//    end for
//  return Sum
// end function
//we assume that the edges are not sorted in each partition

float  *pageRankGraphGrid(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphGrid *graph)
{

    float *pageRanks = NULL;

    switch (pushpull)
    {
    case 0: // push
        pageRanks = pageRankPullRowGraphGrid(epsilon, iterations, graph);
        break;
    case 1: // pull
        pageRanks = pageRankPushColumnGraphGrid(epsilon, iterations, graph);
        break;
    case 2: // pull
        pageRanks = pageRankPullRowFixedPointGraphGrid(epsilon, iterations, graph);
        break;
    case 3: // push
        pageRanks = pageRankPushColumnFixedPointGraphGrid(epsilon, iterations, graph);
        break;
    default:// push
        pageRanks = pageRankPullRowGraphGrid(epsilon, iterations, graph);
        break;
    }

    return pageRanks;

}


float *pageRankPullRowGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph)
{

    __u32 iter;
    __u32 v;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    __u32 totalPartitions  = graph->grid->num_partitions;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Row (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0.0f;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->grid->out_degree[v])
                riDividedOnDiClause[v] = pageRanks[v] / graph->grid->out_degree[v];
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);

        __u32 i;
        #pragma omp parallel for private(i)
        for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
        {
            __u32 j;
            // #pragma omp parallel for private(j)
            for (j = 0; j < totalPartitions; ++j)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

                    // #pragma omp atomic update
                    // __sync_fetch_and_add(&pageRanksNext[dest],riDividedOnDiClause[src]);
                    // addAtomicFloat(float *num, float value)

                    #pragma omp atomic update
                    pageRanksNext[dest] +=  riDividedOnDiClause[src];
                }
            }
        }


        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}



float *pageRankPullRowFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph)
{

    __u32 iter;
    __u32 v;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    __u32 totalPartitions  = graph->grid->num_partitions;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Row FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");


    Start(timer);

    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->grid->out_degree[v])
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->grid->out_degree[v]);
            else
                riDividedOnDiClause[v] = 0;
        }

        // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);

        __u32 i;
        #pragma omp parallel for private(i)
        for (i = 0; i < totalPartitions; ++i)  // iterate over partitions rowwise
        {
            __u32 j;
            for (j = 0; j < totalPartitions; ++j)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

                    #pragma omp atomic update
                    pageRanksNext[dest] +=  riDividedOnDiClause[src];
                }
            }
        }


        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}



/******************************************************************/



float *pageRankPushColumnGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph)
{

    __u32 iter;
    __u32 v;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    __u32 totalPartitions  = graph->grid->num_partitions;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push-Col (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0.0f;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->grid->out_degree[v])
                riDividedOnDiClause[v] = pageRanks[v] / graph->grid->out_degree[v];
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);

        __u32 j;
        #pragma omp parallel for private(j)
        for (j = 0; j < totalPartitions; ++j)  // iterate over partitions columnwise
        {
            __u32 i;

            for (i = 0; i < totalPartitions; ++i)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

                    #pragma omp atomic update
                    pageRanksNext[dest] +=  riDividedOnDiClause[src];

                    // addAtomicFloat(&pageRanksNext[dest] , riDividedOnDiClause[src]);
                }
            }
        }


        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}



float *pageRankPushColumnFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph)
{

    __u32 iter;
    __u32 v;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    __u32 totalPartitions  = graph->grid->num_partitions;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push-Col FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0.0f;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->grid->out_degree[v])
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->grid->out_degree[v]);
            else
                riDividedOnDiClause[v] = 0;
        }

        // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);

        __u32 j;
        #pragma omp parallel for private(j)
        for (j = 0; j < totalPartitions; ++j)  // iterate over partitions columnwise
        {
            __u32 i;
            for (i = 0; i < totalPartitions; ++i)
            {
                __u32 k;
                __u32 src;
                __u32 dest;
                struct Partition *partition = &graph->grid->partitions[(i * totalPartitions) + j];
                for (k = 0; k < partition->num_edges; ++k)
                {
                    src  = partition->edgeList->edges_array_src[k];
                    dest = partition->edgeList->edges_array_dest[k];

                    #pragma omp atomic update
                    pageRanksNext[dest] +=  riDividedOnDiClause[src];

                    // addAtomicFloat(&pageRanksNext[dest] , riDividedOnDiClause[src]);
                }
            }
        }


        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}




// ********************************************************************************************
// ***************          CSR DataStructure                                    **************
// ********************************************************************************************


float *pageRankGraphCSR(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphCSR *graph)
{

    float *pageRanks = NULL;

    switch (pushpull)
    {

    case 0: // pull
        pageRanks = pageRankPullGraphCSR(epsilon, iterations, graph);
        break;
    case 1: // push
        pageRanks = pageRankPushGraphCSR(epsilon, iterations, graph);
        break;

    case 2: // pull
        pageRanks = pageRankPullFixedPointGraphCSR(epsilon, iterations, graph);
        break;
    case 3: // push
        pageRanks = pageRankPushFixedPointGraphCSR(epsilon, iterations, graph);
        break;

    case 4: // pull
        pageRanks = pageRankPulCacheAnalysisGraphCSR(epsilon, iterations, graph);
        break;
    case 5: // push
        pageRanks = pageRankPushQuantizationGraphCSR(epsilon, iterations, graph);
        break;

    case 6: // pull
        pageRanks = pageRankDataDrivenPullGraphCSR(epsilon, iterations, graph);
        break;
    case 7: // push
        pageRanks = pageRankDataDrivenPushGraphCSR(epsilon, iterations, graph);
        break;
    case 8: // pullpush
        pageRanks = pageRankDataDrivenPullPushGraphCSR(epsilon, iterations, graph);
        break;

    // case 9: // push
    //     pageRankDataDrivenPullFixedPointGraphCSR(epsilon, iterations, graph);
    // break;
    // case 10: // pull
    //     pageRankDataDrivenPushFixedPointGraphCSR(epsilon, iterations, graph);
    // break;

    default:// pull
        pageRanks = pageRankPullGraphCSR(epsilon, iterations, graph);
        break;
    }

    return pageRanks;

}

void pageRankPullGraphCSRKernel(float *riDividedOnDiClause, float *pageRanksNext, struct Vertex *vertices, __u32 *sorted_edges_array, __u32 num_vertices)
{

    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
loop : for(v = 0; v < num_vertices; v++)
    {
        float nodeIncomingPR = 0.0f;
        degree = vertices->out_degree[v];
        edge_idx = vertices->edges_idx[v];

        for(j = edge_idx ; j <  (edge_idx+degree) ; j++)
        {
            u = sorted_edges_array[j];
            nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
        }
        pageRanksNext[v] = nodeIncomingPR;
    }

}

// topoligy driven approach
float *pageRankPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{

    __u32 iter;
    // __u32 j;
    __u32 v;
    // __u32 u;
    // __u32 degree;
    // __u32 edge_idx;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Vertex *vertices = NULL;
    __u32 *sorted_edges_array = NULL;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

#if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edges_array->edges_array_dest;
#else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edges_array->edges_array_dest;
#endif

    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices->out_degree[v])
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices->out_degree[v];
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        // #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,edge_idx) schedule(dynamic, 1024)
        // for(v = 0; v < graph->num_vertices; v++)
        // {
        //     float nodeIncomingPR = 0.0f;
        //     degree = vertices->out_degree[v];
        //     edge_idx = vertices->edges_idx[v];
        //     for(j = edge_idx ; j < (edge_idx + degree) ; j++)
        //     {
        //         u = sorted_edges_array[j];
        //         nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
        //     }
        //     pageRanksNext[v] = nodeIncomingPR;
        // }

#ifdef GEM5_HARNESS
         mapArrayToAccelerator(
            ACCELGRAPH_CSR_PAGERANK_PULL, "riDividedOnDiClause", &(riDividedOnDiClause[0]), graph->num_vertices * sizeof(__u32));
        mapArrayToAccelerator(
            ACCELGRAPH_CSR_PAGERANK_PULL, "pageRanksNext", &(pageRanksNext[0]), graph->num_vertices * sizeof(__u32));
        mapArrayToAccelerator(
            ACCELGRAPH_CSR_PAGERANK_PULL, "out_degree", &(vertices->out_degree[0]), graph->num_vertices * sizeof(struct Vertex));
         mapArrayToAccelerator(
            ACCELGRAPH_CSR_PAGERANK_PULL, "edges_idx", &(vertices->edges_idx[0]), graph->num_vertices * sizeof(struct Vertex));
        mapArrayToAccelerator(
            ACCELGRAPH_CSR_PAGERANK_PULL, "sorted_edges_array", &(sorted_edges_array[0]), graph->num_edges * sizeof(__u32));
        invokeAcceleratorAndBlock(ACCELGRAPH_CSR_PAGERANK_PULL);
#else
        pageRankPullGraphCSRKernel(riDividedOnDiClause, pageRanksNext, vertices, sorted_edges_array, graph->num_vertices);
#endif

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}
float *pageRankPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{


    __u32 iter;
    __u32 i;
    __u32 v;

    // double error = 0;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));


    omp_lock_t *vertex_lock  = (omp_lock_t *) my_malloc( graph->num_vertices * sizeof(omp_lock_t));




    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_init_lock(&(vertex_lock[i]));
    }


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;
        #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices->out_degree[v])
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices->out_degree[v];
            else
                riDividedOnDiClause[v] = 0;

        }

        #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {

            __u32 degree = graph->vertices->out_degree[v];
            __u32 edge_idx = graph->vertices->edges_idx[v];
            // __u32 tid = omp_get_thread_num();
            __u32 j;

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                __u32 u = graph->sorted_edges_array->edges_array_dest[j];

                // omp_set_lock(&(vertex_lock[u]));
                //   pageRanksNext[u] += riDividedOnDiClause[v];
                // omp_unset_lock((&vertex_lock[u]));

                #pragma omp atomic update
                pageRanksNext[u] += riDividedOnDiClause[v];

                // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
                // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

                // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
            }
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {

            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        Stop(timer_inner);

        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");
    // pageRankPrint(pageRanks, graph->num_vertices);

    #pragma omp parallel for
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(timer);
    free(timer_inner);
    free(vertex_lock);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}


// topoligy driven approach
float *pageRankPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{

    __u32 iter;
    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);

    // __u64 base_pr_fp = FloatToFixed64(base_pr);
    // __u64 epsilon_fp = DoubleToFixed64(epsilon);
    // __u64 num_vertices_fp = UInt32ToFixed64();

    struct Vertex *vertices = NULL;
    __u32 *sorted_edges_array = NULL;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

#if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edges_array->edges_array_dest;
#else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edges_array->edges_array_dest;
#endif


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    // __u64* outDegreesFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
    // __u64* pageRanksFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices->out_degree[v])
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices->out_degree[v]);
            else
                riDividedOnDiClause[v] = 0;
        }

        // Stop(timer_inner);
        // printf("|A %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));

        //  Start(timer_inner);
        #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,edge_idx) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            degree = vertices->out_degree[v];
            edge_idx = vertices->edges_idx[v];
            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = sorted_edges_array[j];
                pageRanksNext[v] += riDividedOnDiClause[u];
            }

        }
        // Stop(timer_inner);
        // printf("|B %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));

        // Start(timer_inner);
        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            // pageRanksFP[v] = FloatToFixed(nextPageRank);
            pageRanksNext[v] = 0;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        // Stop(timer_inner);
        // printf("|C %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(riDividedOnDiClause);

    return pageRanks;

}

float *pageRankPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;

    // double error = 0;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    // __u64 base_prFP = DoubleToFixed(base_pr);
    // __u64 DampFP = DoubleToFixed(Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));


    omp_lock_t *vertex_lock  = (omp_lock_t *) my_malloc( graph->num_vertices * sizeof(omp_lock_t));



    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_init_lock(&(vertex_lock[i]));
    }


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    // __u32* pageRanksFP = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        // pageRanksFP[v]=base_prFP;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;
        #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices->out_degree[v])
            {
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices->out_degree[v]);
                // riDividedOnDiClause[v] = DIVFixed64V1(pageRanksFP[v],UInt64ToFixed(graph->vertices[v].out_degree));
            }
            else
                riDividedOnDiClause[v] = 0;

        }
        // Stop(timer_inner);
        // printf("|A%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
        // Start(timer_inner);
        #pragma omp parallel for default(none) schedule(dynamic, 1024) private(v) shared(graph,pageRanksNext,riDividedOnDiClause)
        for(v = 0; v < graph->num_vertices; v++)
        {



            __u32 degree = graph->vertices->out_degree[v];
            __u32 edge_idx = graph->vertices->edges_idx[v];
            // __u32 tid = omp_get_thread_num();
            __u32 j;

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                __u32 u = graph->sorted_edges_array->edges_array_dest[j];

                // omp_set_lock(&(vertex_lock[u]));
                //   pageRanksNext[u] += riDividedOnDiClause[v];
                // omp_unset_lock((&vertex_lock[u]));

                #pragma omp atomic update
                pageRanksNext[u] += riDividedOnDiClause[v];

                // addAtomicFixedPoint(&pageRanksNext[u] , riDividedOnDiClause[v]);
            }
        }
        // Stop(timer_inner);
        // printf("|B%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
        // Start(timer_inner);
        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            // pageRanksFP[v] = FloatToFixed(nextPageRank);
            pageRanksNext[v] = 0;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);

    #pragma omp parallel for
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(timer);
    free(timer_inner);
    free(vertex_lock);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}

// topoligy driven approach
float *pageRankPulCacheAnalysisGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{

    __u32 BLOCKSIZE = 128;
    __u32 L1_SIZE = 262144;

    // __u32 BLOCKSIZE = 64;
    // __u32 L1_SIZE = 32768;

    __u32 L1_ASSOC = 8;
    // __u32 NUM_VERTICES = graph->num_vertices;

    struct Cache *cache = ( struct Cache *) my_malloc(sizeof(struct Cache));
    cache->verticesMiss = (uint *)my_malloc(sizeof(uint) * graph->num_vertices);
    cache->numVertices = graph->num_vertices;
    initCache(cache, L1_SIZE, L1_ASSOC, BLOCKSIZE);

    struct Cache *cache_prefetch = ( struct Cache *) my_malloc(sizeof(struct Cache));
    cache_prefetch->verticesMiss = (uint *)my_malloc(sizeof(uint) * graph->num_vertices);
    cache_prefetch->numVertices = graph->num_vertices;
    initCache(cache_prefetch, L1_SIZE, L1_ASSOC, BLOCKSIZE);

    // double error = 0.01;

    // struct Cache *cache_top = ( struct Cache *) my_malloc(sizeof(struct Cache));
    // cache_top->verticesMiss = (uint *)my_malloc(sizeof(uint) * graph->num_vertices);
    // cache_top->numVertices = graph->num_vertices;
    // initCache(cache_top, L1_SIZE, L1_ASSOC, BLOCKSIZE);
    // Cache *capi_cache_data = new Cache(cache_size, cache_assoc, blk_size);
    // capi_cache_data->verticesMiss = (uint *)malloc(sizeof(uint) * numVertices);
    // capi_cache_data->numVertices = numVertices;

    // Cache *capi_cache_struct = new Cache(cache_size, cache_assoc, blk_size);
    // capi_cache_struct->verticesMiss = (uint *)malloc(sizeof(uint) * numVertices);
    // capi_cache_struct->numVertices = numVertices;


    // uint *nodesMissMap = (uint *)malloc(sizeof(uint) * graph->num_vertices);

    __u32 i;
    #pragma omp parallel for
    for(i = 0; i < graph->num_vertices; i++)
    {
        cache->verticesMiss[i] = 0;
        // cache_top->verticesMiss[i] = 0;
        // capi_cache_data->verticesMiss[i] = 0;
        // capi_cache_struct->verticesMiss[i] = 0;
        // nodesMissMap[i] = 0;
    }



    __u32 iter;
    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 edge_idx;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);

    // __u64 base_pr_fp = FloatToFixed64(base_pr);
    // __u64 epsilon_fp = DoubleToFixed64(epsilon);
    // __u64 num_vertices_fp = UInt32ToFixed64();

    struct Vertex *vertices = NULL;
    __u32 *sorted_edges_array = NULL;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));

#if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edges_array->edges_array_dest;
#else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edges_array->edges_array_dest;
#endif


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    // __u64* outDegreesFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
    // __u64* pageRanksFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));

    __u32 *labels;
    __u32 *labelsInverse;
    __u32 *degrees;

    labels = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    labelsInverse = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));
    degrees = (__u32 *) my_malloc(graph->num_vertices * sizeof(__u32));

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        labelsInverse[v] = v;
        degrees[v] = graph->vertices->out_degree[v];

    }

    labelsInverse = radixSortEdgesByDegree(degrees, labelsInverse, graph->num_vertices);

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++)
    {
        labels[labelsInverse[v]] = v;
    }

    // struct BloomMultiHash *bloomMultiHash  = newBloomMultiHash(graph->vertices[labelsInverse[(graph->num_vertices - 1)]].out_degree, error);


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull Cache (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices->out_degree[v])
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices->out_degree[v]);
            else
                riDividedOnDiClause[v] = 0;
        }

        // Stop(timer_inner);
        // printf("|A %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
        //  Start(timer_inner);


        // FILE *fptr;
        // fptr = fopen("./livejournal.32k.outdegree.PR.rabbit.out", "w");
        __u32 top = (32768);
        // printf("top %u \n", graph->vertices[37356].out_degree);
        // #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,edge_idx) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            degree = vertices->out_degree[v];

            // if(labels[v] > (graph->num_vertices - top))
            //     Access(cache_top, (__u64) & (vertices[v].out_degree), 'r', '1', v);
            // else
            //     Access(cache, (__u64) & (vertices[v].out_degree), 'r', '0', v);

            // if(labels[v] > (graph->num_vertices - top))
            //     Access(cache_top, (__u64) & (vertices[v].edges_idx), 'r', '1', v);
            // else
            //     Access(cache ,(__u64) & (vertices[v].edges_idx), 'r', '0', v);

            // prefetcing V+1
            if((v + 1) < graph->num_vertices)
            {
                edge_idx = vertices->edges_idx[v + 1];
                for(j = edge_idx ; j < (edge_idx + vertices->out_degree[v + 1]) ; j++)
                {
                    u = sorted_edges_array[j];


                    if(checkPrefetch(cache_prefetch, (__u64) & (riDividedOnDiClause[u]), '0'))
                    {
                        if(labels[u] < (graph->num_vertices - top))
                        {

                            Prefetch(cache, (__u64) & (riDividedOnDiClause[u]), 's', '1', u);
                            // Access(cache_prefetch, (__u64) & (riDividedOnDiClause[u]), 's', '1', u);
                        }
                        else
                        {
                            Prefetch(cache, (__u64) & (riDividedOnDiClause[u]), 's', '0', u);
                            // Access(cache_prefetch, (__u64) & (riDividedOnDiClause[u]), 's', '0', u);
                        }
                    }
                }

                if(checkPrefetch(cache_prefetch, (__u64) & (pageRanksNext[v + 1]), '0'))
                {
                    if(labels[v + 1] > (graph->num_vertices - top))
                    {
                        Prefetch(cache, (__u64) & (pageRanksNext[v + 1]), 'w', '1', v);
                    }
                    else
                    {
                        Prefetch(cache, (__u64) & (pageRanksNext[v + 1]), 'w', '0', v);
                    }
                }

            }


            edge_idx = vertices->edges_idx[v];

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                u = sorted_edges_array[j];

                if(labels[u] > (graph->num_vertices - top))
                {
                    Access(cache, (__u64) & (riDividedOnDiClause[u]), 'r', '1', u);
                    Access(cache_prefetch, (__u64) & (riDividedOnDiClause[u]), 'r', '1', u);
                    // Access(cache_top, (__u64) &(sorted_edges_array[j]), 'r', '1', v);
                }
                else
                {
                    Access(cache, (__u64) & (riDividedOnDiClause[u]), 'r', '0', u);
                    Access(cache_prefetch, (__u64) & (riDividedOnDiClause[u]), 'r', '0', u);
                    // Access(cache, (__u64) &(sorted_edges_array[j]), 'r', '0', v);
                }

                pageRanksNext[v] += riDividedOnDiClause[u];
            }

            if(labels[v] > (graph->num_vertices - top))
            {
                Access(cache, (__u64) & (pageRanksNext[v]), 'r', '1', v);
                Access(cache, (__u64) & (pageRanksNext[v]), 'w', '1', v);

                Access(cache_prefetch, (__u64) & (pageRanksNext[v]), 'r', '1', v);
                // Access(cache_prefetch, (__u64) & (pageRanksNext[v]), 'w', '1', v);
            }
            else
            {
                Access(cache, (__u64) & (pageRanksNext[v]), 'r', '0', v);
                Access(cache, (__u64) & (pageRanksNext[v]), 'w', '0', v);

                Access(cache_prefetch, (__u64) & (pageRanksNext[v]), 'r', '0', v);
                // Access(cache_prefetch, (__u64) & (pageRanksNext[v]), 'w', '0', v);
            }

        }

        // fclose(fptr);
        // Stop(timer_inner);
        // printf("|B %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
        // Start(timer_inner);
        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            // pageRanksFP[v] = FloatToFixed(nextPageRank);
            pageRanksNext[v] = 0;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        // Stop(timer_inner);
        // printf("|C %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    //  for(v = 0; v < graph->num_vertices; v++)
    // {
    //     // pageRanks[v] = pageRanks[v] / graph->num_vertices;
    //   printf("[%u]=%u \n",v, bloomMultiHash->counter[v]);
    // }

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);

    printStats(cache);
    // printStats(cache_prefetch);

    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}

float *pageRankPushQuantizationGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;

    // double error = 0;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    // __u64 base_prFP = DoubleToFixed(base_pr);
    // __u64 DampFP = DoubleToFixed(Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));


    omp_lock_t *vertex_lock  = (omp_lock_t *) my_malloc( graph->num_vertices * sizeof(omp_lock_t));




    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_init_lock(&(vertex_lock[i]));
    }


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    // __u32* pageRanksFP = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push Quant (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        // pageRanksFP[v]=base_prFP;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;
        #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices->out_degree[v])
            {
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices->out_degree[v]);
                // riDividedOnDiClause[v] = DIVFixed64V1(pageRanksFP[v],UInt64ToFixed(graph->vertices[v].out_degree));
            }
            else
                riDividedOnDiClause[v] = 0;

        }
        // Stop(timer_inner);
        // printf("|A%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
        // Start(timer_inner);
        #pragma omp parallel for default(none) schedule(dynamic, 1024) private(v) shared(graph,pageRanksNext,riDividedOnDiClause)
        for(v = 0; v < graph->num_vertices; v++)
        {



            __u32 degree = graph->vertices->out_degree[v];
            __u32 edge_idx = graph->vertices->edges_idx[v];
            // __u32 tid = omp_get_thread_num();
            __u32 j;

            for(j = edge_idx ; j < (edge_idx + degree) ; j++)
            {
                __u32 u = graph->sorted_edges_array->edges_array_dest[j];

                // omp_set_lock(&(vertex_lock[u]));
                //   pageRanksNext[u] += riDividedOnDiClause[v];
                // omp_unset_lock((&vertex_lock[u]));

                #pragma omp atomic update
                pageRanksNext[u] += riDividedOnDiClause[v];

                // addAtomicFixedPoint(&pageRanksNext[u] , riDividedOnDiClause[v]);
            }
        }
        // Stop(timer_inner);
        // printf("|B%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
        // Start(timer_inner);
        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            // pageRanksFP[v] = FloatToFixed(nextPageRank);
            pageRanksNext[v] = 0;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }


    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);

    #pragma omp parallel for
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(timer);
    free(timer_inner);
    free(vertex_lock);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}

float *pageRankDataDrivenPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{



    __u32 iter;
    __u32 i;
    __u32 v;



    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Vertex *vertices = NULL;
    __u32 *sorted_edges_array = NULL;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;


    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);

#if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edges_array->edges_array_dest;
#else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edges_array->edges_array_dest;
#endif


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);
    #pragma omp parallel for reduction(+:activeVertices)
    for(i = 0; i < graph->num_vertices; i++)
    {
        pageRanks[i] = base_pr;
        workListNext[i] = 1;
        activeVertices++;
    }

    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);
    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices->out_degree[v])
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices->out_degree[v];
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        #pragma omp parallel for default(none) shared(epsilon,pageRanks,riDividedOnDiClause,sorted_edges_array,vertices,workListCurr,workListNext,base_pr,graph) private(v) reduction(+:activeVertices,error_total) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {
                __u32 edge_idx;
                __u32 degree;
                __u32 j;
                __u32 u;
                double error = 0;
                float nodeIncomingPR = 0;
                degree = vertices->out_degree[v]; // when directed we use inverse graph out degree means in degree
                edge_idx = vertices->edges_idx[v];
                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = sorted_edges_array[j];
                    nodeIncomingPR += riDividedOnDiClause[u]; // sum (PRi/outDegree(i))
                }
                float oldPageRank =  pageRanks[v];
                float newPageRank =  base_pr + (Damp * nodeIncomingPR);
                error = fabs(newPageRank - oldPageRank);
                error_total += error / graph->num_vertices;
                if(error >= epsilon)
                {
                    pageRanks[v] = newPageRank;
                    degree = graph->vertices->out_degree[v];
                    edge_idx = graph->vertices->edges_idx[v];
                    for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                    {
                        u = graph->sorted_edges_array->edges_array_dest[j];

                        #pragma omp atomic write
                        workListNext[u] = 1;
                        // __u8 old_val = workListNext[u];
                        // if(!old_val){
                        //    __sync_bool_compare_and_swap(&workListNext[u], 0, 1);
                        // }
                    }
                    activeVertices++;
                }
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(riDividedOnDiClause);

    return pageRanks;
}
float *pageRankDataDrivenPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{

    __u32 iter;
    __u32 v;
    __u32 edge_idx;
    __u32 degree;
    __u32 j;
    __u32 u;


    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Vertex *vertices = NULL;
    __u32 *sorted_edges_array = NULL;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;


    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);

#if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edges_array->edges_array_dest;
#else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edges_array->edges_array_dest;
#endif


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *aResiduals = (float *) my_malloc(graph->num_vertices * sizeof(float));



    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);


    #pragma omp parallel for private(edge_idx,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        aResiduals[v] = 0.0;
        workListCurr[v] = 1;
        workListNext[v] = 0;
        activeVertices++;
        degree = vertices->out_degree[v]; // when directed we use inverse graph out degree means in degree
        edge_idx = vertices->edges_idx[v];
        for(j = edge_idx ; j < (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array[j];
            if(graph->vertices->out_degree[u])
                aResiduals[v] += 1.0f / graph->vertices->out_degree[u]; // sum (PRi/outDegree(i))
        }
        aResiduals[v] = (1.0f - Damp) * Damp * aResiduals[v];
    }

    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for default(none) private(edge_idx,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {
                float oldPageRank =  pageRanks[v];
                float newPageRank =  aResiduals[v] + pageRanks[v];
                error_total += fabs(newPageRank / graph->num_vertices - oldPageRank / graph->num_vertices);

                // #pragma omp atomic write
                pageRanks[v] = newPageRank;

                degree = graph->vertices->out_degree[v];
                float delta = Damp * (aResiduals[v] / degree);
                edge_idx = graph->vertices->edges_idx[v];

                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = graph->sorted_edges_array->edges_array_dest[j];
                    float prevResidual = 0.0f;

                    prevResidual = aResiduals[u];

                    #pragma omp atomic update
                    aResiduals[u] += delta;

                    if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                    {
                        activeVertices++;
                        if(!workListNext[u])
                        {

                            // #pragma omp atomic write
                            workListNext[u] = 1;

                        }
                    }
                }
                aResiduals[v] = 0.0f;
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(aResiduals);
    free(riDividedOnDiClause);

    return pageRanks;
}


float *pageRankDataDrivenPullPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph)
{

    __u32 iter;
    __u32 v;
    __u32 edge_idx;
    __u32 degree;
    __u32 j;
    __u32 u;


    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Vertex *vertices = NULL;
    __u32 *sorted_edges_array = NULL;
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;


    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);

#if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edges_array->edges_array_dest;
#else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edges_array->edges_array_dest;
#endif


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *aResiduals = (float *) my_malloc(graph->num_vertices * sizeof(float));



    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);


    #pragma omp parallel for private(edge_idx,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        aResiduals[v] = 0.0f;
        workListCurr[v] = 1;
        workListNext[v] = 0;
        activeVertices++;
        degree = vertices->out_degree[v]; // when directed we use inverse graph out degree means in degree
        edge_idx = vertices->edges_idx[v];
        for(j = edge_idx ; j < (edge_idx + degree) ; j++)
        {
            u = sorted_edges_array[j];
            if(graph->vertices->out_degree[u])
                aResiduals[v] += 1.0f / graph->vertices->out_degree[u]; // sum (PRi/outDegree(i))
        }
        aResiduals[v] = (1.0f - Damp) * Damp * aResiduals[v];
    }

    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for default(none) private(edge_idx,degree,v,j,u) shared(vertices,sorted_edges_array,epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {

                float nodeIncomingPR = 0.0f;
                degree = vertices->out_degree[v];
                edge_idx = vertices->edges_idx[v];
                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = sorted_edges_array[j];
                    nodeIncomingPR += pageRanks[u] / graph->vertices->out_degree[u];
                }

                float newPageRank = base_pr + (Damp * nodeIncomingPR);
                float oldPageRank =  pageRanks[v];
                // float newPageRank =  aResiduals[v]+pageRanks[v];
                error_total += fabs(newPageRank / graph->num_vertices - oldPageRank / graph->num_vertices);

                #pragma omp atomic write
                pageRanks[v] = newPageRank;

                degree = graph->vertices->out_degree[v];
                float delta = Damp * (aResiduals[v] / degree);
                edge_idx = graph->vertices->edges_idx[v];
                for(j = edge_idx ; j < (edge_idx + degree) ; j++)
                {
                    u = graph->sorted_edges_array->edges_array_dest[j];
                    float prevResidual = 0.0f;

                    prevResidual = aResiduals[u];

                    #pragma omp atomic update
                    aResiduals[u] += delta;

                    if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                    {
                        activeVertices++;
                        if(!workListNext[u])
                        {
                            workListNext[u] = 1;
                        }
                    }
                }
                aResiduals[v] = 0.0f;
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(aResiduals);
    free(riDividedOnDiClause);

    return pageRanks;

}


// float* pageRankDataDrivenPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


// }

// float* pageRankDataDrivenPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


// }

// float* pageRankDataDrivenPullPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


// }



// ********************************************************************************************
// ***************          ArrayList DataStructure              **************
// ********************************************************************************************


float *pageRankGraphAdjArrayList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList *graph)
{

    float *pageRanks = NULL;

    switch (pushpull)
    {

    case 0: // pull
        pageRanks = pageRankPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 1: // push
        pageRanks = pageRankPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 2: // pull
        pageRanks = pageRankPullFixedPointGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 3: // push
        pageRanks = pageRankPushFixedPointGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 4: // pull
        pageRanks = pageRankDataDrivenPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 5: // push
        pageRanks = pageRankDataDrivenPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
    case 6: // pullpush
        pageRanks = pageRankDataDrivenPullPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
    default:// push
        pageRanks = pageRankPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
    }

    return pageRanks;

}

float *pageRankPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph)
{

    __u32 iter;
    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 activeVertices = 0;
    double error_total = 0;
    struct EdgeList *Nodes;

    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices[v].out_degree;
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float nodeIncomingPR = 0.0f;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
            Nodes = graph->vertices[v].inNodes;
            degree = graph->vertices[v].in_degree;
#else
            Nodes = graph->vertices[v].outNodes;
            degree = graph->vertices[v].out_degree;
#endif

            for(j = 0 ; j < (degree) ; j++)
            {
                u = Nodes->edges_array_dest[j];
                nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
            }

            pageRanksNext[v] = nodeIncomingPR;
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}
float *pageRankPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;

    // double error = 0;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    struct EdgeList *Nodes;


    omp_lock_t *vertex_lock  = (omp_lock_t *) my_malloc( graph->num_vertices * sizeof(omp_lock_t));




    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_init_lock(&(vertex_lock[i]));
    }


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0.0f;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;
        #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
        for(v = 0; v < graph->num_vertices; v++)
        {


            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices[v].out_degree;
            else
                riDividedOnDiClause[v] = 0.0f;

        }

        #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {

            Nodes = graph->vertices[v].outNodes;
            __u32 degree = graph->vertices[v].out_degree;
            // __u32 tid = omp_get_thread_num();
            __u32 j;

            for(j = 0 ; j < (degree) ; j++)
            {
                __u32 u = Nodes->edges_array_dest[j];

                // omp_set_lock(&(vertex_lock[u]));
                //   pageRanksNext[u] += riDividedOnDiClause[v];
                // omp_unset_lock((&vertex_lock[u]));

                #pragma omp atomic update
                pageRanksNext[u] += riDividedOnDiClause[v];

                // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
                // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

                // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
            }
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {



            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        Stop(timer_inner);

        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");
    // pageRankPrint(pageRanks, graph->num_vertices);

    #pragma omp parallel for
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(timer);
    free(timer_inner);
    free(vertex_lock);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}
float *pageRankPullFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph)
{

    __u32 iter;
    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 activeVertices = 0;
    double error_total = 0;
    struct EdgeList *Nodes;

    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices[v].out_degree);
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float nodeIncomingPR = 0.0f;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
            Nodes = graph->vertices[v].inNodes;
            degree = graph->vertices[v].in_degree;
#else
            Nodes = graph->vertices[v].outNodes;
            degree = graph->vertices[v].out_degree;
#endif

            for(j = 0 ; j < (degree) ; j++)
            {
                u = Nodes->edges_array_dest[j];
                nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
            }

            pageRanksNext[v] = nodeIncomingPR;
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}
float *pageRankPushFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;

    // double error = 0;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    struct EdgeList *Nodes;


    omp_lock_t *vertex_lock  = (omp_lock_t *) my_malloc( graph->num_vertices * sizeof(omp_lock_t));



    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_init_lock(&(vertex_lock[i]));
    }


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0.0f;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;
        #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
        for(v = 0; v < graph->num_vertices; v++)
        {


            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices[v].out_degree);
            else
                riDividedOnDiClause[v] = 0;

        }

        #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {

            Nodes = graph->vertices[v].outNodes;
            __u32 degree = graph->vertices[v].out_degree;
            // __u32 tid = omp_get_thread_num();
            __u32 j;

            for(j = 0 ; j < (degree) ; j++)
            {
                __u32 u = Nodes->edges_array_dest[j];

                // omp_set_lock(&(vertex_lock[u]));
                //   pageRanksNext[u] += riDividedOnDiClause[v];
                // omp_unset_lock((&vertex_lock[u]));

                #pragma omp atomic update
                pageRanksNext[u] += riDividedOnDiClause[v];

                // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
                // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

                // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
            }
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {



            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        Stop(timer_inner);

        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");
    // pageRankPrint(pageRanks, graph->num_vertices);

    #pragma omp parallel for
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(timer);
    free(timer_inner);
    free(vertex_lock);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;
}
float *pageRankDataDrivenPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;



    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;
    struct EdgeList *Nodes;


    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);




    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);
    #pragma omp parallel for reduction(+:activeVertices)
    for(i = 0; i < graph->num_vertices; i++)
    {
        pageRanks[i] = base_pr;
        workListNext[i] = 1;
        activeVertices++;
    }

    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);
    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices[v].out_degree;
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        #pragma omp parallel for default(none) shared(epsilon,pageRanks,riDividedOnDiClause,workListCurr,workListNext,base_pr,graph) private(v,Nodes) reduction(+:activeVertices,error_total) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {

                __u32 degree;
                __u32 j;
                __u32 u;
                double error = 0;
                float nodeIncomingPR = 0;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
                Nodes = graph->vertices[v].inNodes;
                degree = graph->vertices[v].in_degree;
#else
                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;
#endif

                for(j = 0 ; j < (degree) ; j++)
                {
                    u = Nodes->edges_array_dest[j];
                    nodeIncomingPR += riDividedOnDiClause[u]; // sum (PRi/outDegree(i))
                }
                float oldPageRank =  pageRanks[v];
                float newPageRank =  base_pr + (Damp * nodeIncomingPR);
                error = fabs(newPageRank - oldPageRank);
                error_total += error / graph->num_vertices;
                if(error >= epsilon)
                {
                    pageRanks[v] = newPageRank;
                    Nodes = graph->vertices[v].outNodes;
                    degree = graph->vertices[v].out_degree;
                    for(j = 0 ; j < (degree) ; j++)
                    {
                        u = Nodes->edges_array_dest[j];

                        #pragma omp atomic write
                        workListNext[u] = 1;
                        // __u8 old_val = workListNext[u];
                        // if(!old_val){
                        //    __sync_bool_compare_and_swap(&workListNext[u], 0, 1);
                        // }
                    }
                    activeVertices++;
                }
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(riDividedOnDiClause);

    return pageRanks;
}
float *pageRankDataDrivenPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph)
{

    __u32 iter;
    __u32 v;
    __u32 degree;
    __u32 j;
    __u32 u;


    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;
    struct EdgeList *Nodes;



    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *aResiduals = (float *) my_malloc(graph->num_vertices * sizeof(float));



    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);


    #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        aResiduals[v] = 0.0;
        workListCurr[v] = 1;
        workListNext[v] = 0;
        activeVertices++;


#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
#else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
#endif


        for(j = 0 ; j < (degree) ; j++)
        {
            u = Nodes->edges_array_dest[j];
            if(graph->vertices[u].out_degree)
                aResiduals[v] += 1.0f / graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
        }
        aResiduals[v] = (1.0f - Damp) * Damp * aResiduals[v];
    }

    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {
                float oldPageRank =  pageRanks[v];
                float newPageRank =  aResiduals[v] + pageRanks[v];
                error_total += fabs(newPageRank / graph->num_vertices - oldPageRank / graph->num_vertices);

                // #pragma omp atomic write
                pageRanks[v] = newPageRank;

                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;
                float delta = Damp * (aResiduals[v] / degree);


                for(j = 0 ; j < (degree) ; j++)
                {
                    u = Nodes->edges_array_dest[j];
                    float prevResidual = 0.0f;

                    prevResidual = aResiduals[u];

                    #pragma omp atomic update
                    aResiduals[u] += delta;

                    if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                    {
                        activeVertices++;
                        if(!workListNext[u])
                        {

                            // #pragma omp atomic write
                            workListNext[u] = 1;

                        }
                    }
                }
                aResiduals[v] = 0.0f;
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(aResiduals);
    free(riDividedOnDiClause);

    return pageRanks;
}
float *pageRankDataDrivenPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph)
{

    __u32 iter;
    __u32 v;
    __u32 degree;
    __u32 j;
    __u32 u;
    struct EdgeList *Nodes;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;

    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *aResiduals = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);


    #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        aResiduals[v] = 0.0f;
        workListCurr[v] = 1;
        workListNext[v] = 0;
        activeVertices++;


#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
#else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
#endif

        for(j = 0 ; j < (degree) ; j++)
        {
            u = Nodes->edges_array_dest[j];
            if(graph->vertices[u].out_degree)
                aResiduals[v] += 1.0f / graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
        }
        aResiduals[v] = (1.0f - Damp) * Damp * aResiduals[v];
    }

    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {

                float nodeIncomingPR = 0.0f;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
                Nodes = graph->vertices[v].inNodes;
                degree = graph->vertices[v].in_degree;
#else
                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;
#endif

                for(j = 0 ; j < (degree) ; j++)
                {
                    u = Nodes->edges_array_dest[j];
                    nodeIncomingPR += pageRanks[u] / graph->vertices[u].out_degree;
                }

                float newPageRank = base_pr + (Damp * nodeIncomingPR);
                float oldPageRank =  pageRanks[v];
                // float newPageRank =  aResiduals[v]+pageRanks[v];
                error_total += fabs(newPageRank / graph->num_vertices - oldPageRank / graph->num_vertices);

                #pragma omp atomic write
                pageRanks[v] = newPageRank;

                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;
                float delta = Damp * (aResiduals[v] / degree);



                for(j = 0 ; j < (degree) ; j++)
                {
                    __u32 u = Nodes->edges_array_dest[j];
                    float prevResidual = 0.0f;

                    prevResidual = aResiduals[u];

                    #pragma omp atomic update
                    aResiduals[u] += delta;

                    if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                    {
                        activeVertices++;
                        if(!workListNext[u])
                        {
                            workListNext[u] = 1;
                        }
                    }
                }
                aResiduals[v] = 0.0f;
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(aResiduals);
    free(riDividedOnDiClause);

    return pageRanks;

}


// ********************************************************************************************
// ***************          LinkedList DataStructure           **************
// ********************************************************************************************


float *pageRankGraphAdjLinkedList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList *graph)
{

    float *pageRanks = NULL;

    switch (pushpull)
    {
    case 0: // pull
        pageRanks = pageRankPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 1: // push
        pageRanks = pageRankPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 2: // pull
        pageRanks = pageRankPullFixedPointGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 3: // push
        pageRanks = pageRankPushFixedPointGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 4: // pull
        pageRanks = pageRankDataDrivenPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 5: // push
        pageRanks = pageRankDataDrivenPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    case 6: // pullpush
        pageRanks = pageRankDataDrivenPullPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    default:// push
        pageRanks = pageRankPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
    }

    return pageRanks;

}

float *pageRankPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph)
{

    __u32 iter;
    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 activeVertices = 0;
    double error_total = 0;
    struct AdjLinkedListNode *Nodes;

    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices[v].out_degree;
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float nodeIncomingPR = 0.0f;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
            Nodes = graph->vertices[v].inNodes;
            degree = graph->vertices[v].in_degree;
#else
            Nodes = graph->vertices[v].outNodes;
            degree = graph->vertices[v].out_degree;
#endif

            for(j = 0 ; j < (degree) ; j++)
            {
                u = Nodes->dest;
                Nodes = Nodes->next;
                nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
            }

            pageRanksNext[v] = nodeIncomingPR;
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}
float *pageRankPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;

    // double error = 0;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    struct AdjLinkedListNode *Nodes;


    omp_lock_t *vertex_lock  = (omp_lock_t *) my_malloc( graph->num_vertices * sizeof(omp_lock_t));




    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_init_lock(&(vertex_lock[i]));
    }


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *pageRanksNext = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0.0f;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;
        #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
        for(v = 0; v < graph->num_vertices; v++)
        {


            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices[v].out_degree;
            else
                riDividedOnDiClause[v] = 0.0f;

        }

        #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {

            Nodes = graph->vertices[v].outNodes;
            __u32 degree = graph->vertices[v].out_degree;
            // __u32 tid = omp_get_thread_num();
            __u32 j;

            for(j = 0 ; j < (degree) ; j++)
            {
                __u32 u = Nodes->dest;
                Nodes = Nodes->next;

                // omp_set_lock(&(vertex_lock[u]));
                //   pageRanksNext[u] += riDividedOnDiClause[v];
                // omp_unset_lock((&vertex_lock[u]));

                #pragma omp atomic update
                pageRanksNext[u] += riDividedOnDiClause[v];

                // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
                // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

                // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
            }
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {



            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        Stop(timer_inner);

        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");
    // pageRankPrint(pageRanks, graph->num_vertices);

    #pragma omp parallel for
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(timer);
    free(timer_inner);
    free(vertex_lock);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}
float *pageRankPullFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph)
{

    __u32 iter;
    __u32 j;
    __u32 v;
    __u32 u;
    __u32 degree;
    __u32 activeVertices = 0;
    double error_total = 0;
    struct AdjLinkedListNode *Nodes;

    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        error_total = 0;
        activeVertices = 0;
        Start(timer_inner);
        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices[v].out_degree);
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float nodeIncomingPR = 0.0f;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
            Nodes = graph->vertices[v].inNodes;
            degree = graph->vertices[v].in_degree;
#else
            Nodes = graph->vertices[v].outNodes;
            degree = graph->vertices[v].out_degree;
#endif

            for(j = 0 ; j < (degree) ; j++)
            {
                u = Nodes->dest;
                Nodes = Nodes->next;
                nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
            }

            pageRanksNext[v] = nodeIncomingPR;
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {
            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }


        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // printf(" -----------------------------------------------------\n");
    // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
    // printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(timer);
    free(timer_inner);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}
float *pageRankPushFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;

    // double error = 0;
    __u32 activeVertices = 0;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    struct AdjLinkedListNode *Nodes;


    omp_lock_t *vertex_lock  = (omp_lock_t *) my_malloc( graph->num_vertices * sizeof(omp_lock_t));




    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_init_lock(&(vertex_lock[i]));
    }


    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    __u64 *pageRanksNext = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));
    __u64 *riDividedOnDiClause = (__u64 *) my_malloc(graph->num_vertices * sizeof(__u64));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);


    #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        pageRanksNext[v] = 0.0f;
    }

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;
        #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
        for(v = 0; v < graph->num_vertices; v++)
        {


            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v] / graph->vertices[v].out_degree);
            else
                riDividedOnDiClause[v] = 0;

        }

        #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {

            Nodes = graph->vertices[v].outNodes;
            __u32 degree = graph->vertices[v].out_degree;
            // __u32 tid = omp_get_thread_num();
            __u32 j;

            for(j = 0 ; j < (degree) ; j++)
            {
                __u32  u = Nodes->dest;
                Nodes = Nodes->next;
                // omp_set_lock(&(vertex_lock[u]));
                //   pageRanksNext[u] += riDividedOnDiClause[v];
                // omp_unset_lock((&vertex_lock[u]));

                #pragma omp atomic update
                pageRanksNext[u] += riDividedOnDiClause[v];

                // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
                // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

                // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
            }
        }

        #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices)
        for(v = 0; v < graph->num_vertices; v++)
        {



            float prevPageRank =  pageRanks[v];
            float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
            pageRanks[v] = nextPageRank;
            pageRanksNext[v] = 0.0f;
            double error = fabs( nextPageRank - prevPageRank);
            error_total += (error / graph->num_vertices);

            if(error >= epsilon)
            {
                activeVertices++;
            }
        }

        Stop(timer_inner);

        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");
    // pageRankPrint(pageRanks, graph->num_vertices);

    #pragma omp parallel for
    for (i = 0; i < graph->num_vertices; i++)
    {
        omp_destroy_lock(&(vertex_lock[i]));
    }

    free(timer);
    free(timer_inner);
    free(vertex_lock);
    free(pageRanksNext);
    free(riDividedOnDiClause);

    return pageRanks;

}
float *pageRankDataDrivenPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph)
{

    __u32 iter;
    __u32 i;
    __u32 v;



    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;
    struct AdjLinkedListNode *Nodes;


    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);




    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);
    #pragma omp parallel for reduction(+:activeVertices)
    for(i = 0; i < graph->num_vertices; i++)
    {
        pageRanks[i] = base_pr;
        workListNext[i] = 1;
        activeVertices++;
    }

    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);
    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(graph->vertices[v].out_degree)
                riDividedOnDiClause[v] = pageRanks[v] / graph->vertices[v].out_degree;
            else
                riDividedOnDiClause[v] = 0.0f;
        }

        #pragma omp parallel for default(none) shared(epsilon,pageRanks,riDividedOnDiClause,workListCurr,workListNext,base_pr,graph) private(v,Nodes) reduction(+:activeVertices,error_total) schedule(dynamic, 1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {

                __u32 degree;
                __u32 j;
                __u32 u;
                double error = 0;
                float nodeIncomingPR = 0;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
                Nodes = graph->vertices[v].inNodes;
                degree = graph->vertices[v].in_degree;
#else
                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;
#endif

                for(j = 0 ; j < (degree) ; j++)
                {
                    u = Nodes->dest;
                    Nodes = Nodes->next;
                    nodeIncomingPR += riDividedOnDiClause[u]; // sum (PRi/outDegree(i))
                }
                float oldPageRank =  pageRanks[v];
                float newPageRank =  base_pr + (Damp * nodeIncomingPR);
                error = fabs(newPageRank - oldPageRank);
                error_total += error / graph->num_vertices;
                if(error >= epsilon)
                {
                    pageRanks[v] = newPageRank;
                    Nodes = graph->vertices[v].outNodes;
                    degree = graph->vertices[v].out_degree;
                    for(j = 0 ; j < (degree) ; j++)
                    {
                        u = Nodes->dest;
                        Nodes = Nodes->next;
                        #pragma omp atomic write
                        workListNext[u] = 1;
                        // __u8 old_val = workListNext[u];
                        // if(!old_val){
                        //    __sync_bool_compare_and_swap(&workListNext[u], 0, 1);
                        // }
                    }
                    activeVertices++;
                }
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop

    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(riDividedOnDiClause);

    return pageRanks;

}
float *pageRankDataDrivenPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph)
{

    __u32 iter;
    __u32 v;
    __u32 degree;
    __u32 j;
    __u32 u;


    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;
    struct AdjLinkedListNode *Nodes;



    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *aResiduals = (float *) my_malloc(graph->num_vertices * sizeof(float));



    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);


    #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        aResiduals[v] = 0.0;
        workListCurr[v] = 1;
        workListNext[v] = 0;
        activeVertices++;


#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
#else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
#endif


        for(j = 0 ; j < (degree) ; j++)
        {
            u = Nodes->dest;
            Nodes = Nodes->next;
            if(graph->vertices[u].out_degree)
                aResiduals[v] += 1.0f / graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
        }
        aResiduals[v] = (1.0f - Damp) * Damp * aResiduals[v];
    }

    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {
                float oldPageRank =  pageRanks[v];
                float newPageRank =  aResiduals[v] + pageRanks[v];
                error_total += fabs(newPageRank / graph->num_vertices - oldPageRank / graph->num_vertices);

                // #pragma omp atomic write
                pageRanks[v] = newPageRank;

                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;
                float delta = Damp * (aResiduals[v] / degree);


                for(j = 0 ; j < (degree) ; j++)
                {
                    u = Nodes->dest;
                    Nodes = Nodes->next;
                    float prevResidual = 0.0f;

                    prevResidual = aResiduals[u];

                    #pragma omp atomic update
                    aResiduals[u] += delta;

                    if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                    {
                        activeVertices++;
                        if(!workListNext[u])
                        {

                            // #pragma omp atomic write
                            workListNext[u] = 1;

                        }
                    }
                }
                aResiduals[v] = 0.0f;
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(aResiduals);
    free(riDividedOnDiClause);

    return pageRanks;

}

float *pageRankDataDrivenPullPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph)
{

    __u32 iter;
    __u32 v;
    __u32 degree;
    __u32 j;
    __u32 u;
    struct AdjLinkedListNode *Nodes;
    double error_total = 0;
    // float init_pr = 1.0f / (float)graph->num_vertices;
    float base_pr = (1.0f - Damp);
    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct Timer *timer_inner = (struct Timer *) malloc(sizeof(struct Timer));
    __u8 *workListCurr = NULL;
    __u8 *workListNext = NULL;
    int activeVertices = 0;


    workListCurr  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));
    workListNext  = (__u8 *) my_malloc(graph->num_vertices * sizeof(__u8));


    resetWorkList(workListNext, graph->num_vertices);
    resetWorkList(workListCurr, graph->num_vertices);



    float *pageRanks = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *riDividedOnDiClause = (float *) my_malloc(graph->num_vertices * sizeof(float));
    float *aResiduals = (float *) my_malloc(graph->num_vertices * sizeof(float));

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration", "Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

    Start(timer);

    Start(timer_inner);


    #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = base_pr;
        aResiduals[v] = 0.0f;
        workListCurr[v] = 1;
        workListNext[v] = 0;
        activeVertices++;


#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
#else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
#endif

        for(j = 0 ; j < (degree) ; j++)
        {
            u = Nodes->dest;
            Nodes = Nodes->next;
            if(graph->vertices[u].out_degree)
                aResiduals[v] += 1.0f / graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
        }
        aResiduals[v] = (1.0f - Damp) * Damp * aResiduals[v];
    }

    Stop(timer_inner);
    printf("| %-10s | %-8u | %-15.13lf | %-9f | \n", "Init", activeVertices, error_total, Seconds(timer_inner));

    for(iter = 0; iter < iterations; iter++)
    {
        Start(timer_inner);
        error_total = 0;
        activeVertices = 0;

        #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
        for(v = 0; v < graph->num_vertices; v++)
        {
            if(workListCurr[v])
            {

                float nodeIncomingPR = 0.0f;

#if DIRECTED // will look at the other neighbours if directed by using inverese edge list
                Nodes = graph->vertices[v].inNodes;
                degree = graph->vertices[v].in_degree;
#else
                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;
#endif

                for(j = 0 ; j < (degree) ; j++)
                {
                    u = Nodes->dest;
                    Nodes = Nodes->next;
                    nodeIncomingPR += pageRanks[u] / graph->vertices[u].out_degree;
                }

                float newPageRank = base_pr + (Damp * nodeIncomingPR);
                float oldPageRank =  pageRanks[v];
                // float newPageRank =  aResiduals[v]+pageRanks[v];
                error_total += fabs(newPageRank / graph->num_vertices - oldPageRank / graph->num_vertices);

                #pragma omp atomic write
                pageRanks[v] = newPageRank;

                Nodes = graph->vertices[v].outNodes;
                degree = graph->vertices[v].out_degree;

                float delta = Damp * (aResiduals[v] / degree);



                for(j = 0 ; j < (degree) ; j++)
                {
                    u = Nodes->dest;
                    Nodes = Nodes->next;
                    float prevResidual = 0.0f;

                    prevResidual = aResiduals[u];

                    #pragma omp atomic update
                    aResiduals[u] += delta;

                    if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon))
                    {
                        activeVertices++;
                        if(!workListNext[u])
                        {
                            workListNext[u] = 1;
                        }
                    }
                }
                aResiduals[v] = 0.0f;
            }
        }

        // activeVertices = getNumOfSetBits(workListNext);
        swapWorkLists(&workListNext, &workListCurr);
        resetWorkList(workListNext, graph->num_vertices);

        Stop(timer_inner);
        printf("| %-10u | %-8u | %-15.13lf | %-9f | \n", iter, activeVertices, error_total, Seconds(timer_inner));
        if(activeVertices == 0)
            break;

    }// end iteration loop


    double sum = 0.0f;
    #pragma omp parallel for reduction(+:sum)
    for(v = 0; v < graph->num_vertices; v++)
    {
        pageRanks[v] = pageRanks[v] / graph->num_vertices;
        sum += pageRanks[v];
    }

    Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations", "PR Sum", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");
    printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n", iter, sum, error_total, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    // pageRankPrint(pageRanks, graph->num_vertices);
    free(workListCurr);
    free(workListNext);
    free(timer);
    free(timer_inner);
    free(aResiduals);
    free(riDividedOnDiClause);


    return pageRanks;

}