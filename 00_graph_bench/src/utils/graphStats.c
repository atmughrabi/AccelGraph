#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <string.h>
#include <omp.h>

#include "graphStats.h"
#include "myMalloc.h"
#include "graphCSR.h"
#include "graphConfig.h"
#include "timer.h"




void collectStats( __u32 binSize, const char *fnameb,  __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted, __u32 inout_degree)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    // printf("Filename : %s \n",fnameb);

    printf(" *****************************************************\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Collect Stats Process");
    printf(" -----------------------------------------------------\n");
    Start(timer);

    struct GraphCSR *graphStats = graphCSRPreProcessingStep (fnameb, sort, lmode, symmetric, weighted);


    __u32 *histogram_in = (__u32 *) my_malloc(sizeof(__u32) * binSize);
    __u32 *histogram_out = (__u32 *) my_malloc(sizeof(__u32) * binSize);


    __u32 i = 0;
    #pragma omp parallel for
    for(i = 0 ; i < binSize; i++)
    {
        histogram_in[i] = 0;
        histogram_out[i] = 0;
    }

    char *fname_txt = (char *) malloc((strlen(fnameb) + 20) * sizeof(char));
    char *fname_stats_out = (char *) malloc((strlen(fnameb) + 20) * sizeof(char));
    char *fname_stats_in = (char *) malloc((strlen(fnameb) + 20) * sizeof(char));
    char *fname_adjMat = (char *) malloc((strlen(fnameb) + 20) * sizeof(char));


    fname_txt = strcpy (fname_txt, fnameb);
    fname_adjMat = strcpy (fname_adjMat, fnameb);


    fname_adjMat  = strcat (fname_adjMat, ".bin-adj-SM.dat");// out-degree

    if(lmode == 1)
    {
        fname_stats_in = strcat (fname_txt, ".in-degree.dat");// in-degree
        countHistogram(graphStats, histogram_in, binSize, inout_degree);
        printHistogram(fname_stats_in, histogram_in, binSize);
    }
    else if(lmode == 2)
    {
        fname_stats_out = strcat (fname_txt, ".out-degree.dat");// out-degree
        countHistogram(graphStats, histogram_out, binSize, inout_degree);
        printHistogram(fname_stats_out, histogram_out, binSize);
    }


    printSparseMatrixList(fname_adjMat,  graphStats, binSize);


    Stop(timer);


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Collect Stats Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");
    printf(" *****************************************************\n");

    free(timer);
    graphCSRFree(graphStats);
    free(histogram_in);
    free(histogram_out);
    free(fname_txt);
    free(fname_stats_out);
    free(fname_stats_in);
    free(fname_adjMat);

}


void countHistogram(struct GraphCSR *graphStats, __u32 *histogram, __u32 binSize, __u32 inout_degree)
{

    __u32 v;
    __u32 index;

    #pragma omp parallel for
    for(v = 0; v < graphStats->num_vertices; v++)
    {

        index = v / ((graphStats->num_vertices / binSize) + 1);

        if(inout_degree == 1)
        {
            #pragma omp atomic update
            histogram[index] += graphStats->vertices->in_degree[v];
        }
        else if(inout_degree == 2)
        {
            #pragma omp atomic update
            histogram[index] += graphStats->vertices->out_degree[v];
        }
    }

}


void printHistogram(const char *fname_stats, __u32 *histogram, __u32 binSize)
{

    __u32 index;
    FILE *fptr;
    fptr = fopen(fname_stats, "w");
    for(index = 0; index < binSize; index++)
    {
        fprintf(fptr, "%u %u \n", index, histogram[index]);
    }
    fclose(fptr);
}


void printSparseMatrixList(const char *fname_stats, struct GraphCSR *graphStats, __u32 binSize)
{


    __u32 *SparseMatrix = (__u32 *) my_malloc(sizeof(__u32) * binSize * binSize);


    __u32 x;
    __u32 y;
    #pragma omp parallel for private(y) shared(SparseMatrix)
    for(x = 0; x < binSize; x++)
    {
        for(y = 0; y < binSize; y++)
        {
            SparseMatrix[(binSize * y) + x] = 0;
        }
    }


    __u32 i;

    #pragma omp parallel for
    for(i = 0; i < graphStats->num_edges; i++)
    {
        __u32 src;
        __u32 dest;
        src = graphStats->sorted_edges_array->edges_array_src[i] / ((graphStats->num_vertices / binSize) + 1);
        dest = graphStats->sorted_edges_array->edges_array_dest[i] / ((graphStats->num_vertices / binSize) + 1);

        #pragma omp atomic update
        SparseMatrix[(binSize * dest) + src]++;

    }

    FILE *fptr;
    fptr = fopen(fname_stats, "w");
    for(x = 0; x < binSize; x++)
    {
        for(y = 0; y < binSize; y++)
        {
            fprintf(fptr, "%u %u %u\n", x, y, SparseMatrix[(binSize * y) + x]);
        }
    }

    fclose(fptr);
    free(SparseMatrix);

}

