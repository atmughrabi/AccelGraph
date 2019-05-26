#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "grid.h"
#include "graphGrid.h"
#include "edgeList.h"
#include "myMalloc.h"
#include "graphConfig.h"

#include "reorder.h"
#include "graphCSR.h"

// #include "countsort.h"
// #include "radixsort.h"
#include "sortRun.h"

#include "timer.h"


void  graphGridReset(struct GraphGrid *graphGrid)
{

    graphGridResetActivePartitionsMap(graphGrid->grid);

}

void  graphGridPrint(struct GraphGrid *graphGrid)
{


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Graph Grid Properties");
    printf(" -----------------------------------------------------\n");
#if WEIGHTED
    printf("| %-51s | \n", "WEIGHTED");
#else
    printf("| %-51s | \n", "UN-WEIGHTED");
#endif

#if DIRECTED
    printf("| %-51s | \n", "DIRECTED");
#else
    printf("| %-51s | \n", "UN-DIRECTED");
#endif
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Number of Vertices (V)");
    printf("| %-51u | \n", graphGrid->grid->num_vertices);
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", graphGrid->grid->num_edges);
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Number of Partitions (P)");
    printf("| %-51u | \n", graphGrid->grid->num_partitions);
    printf(" -----------------------------------------------------\n");




    //   __u32 i;
    //    for ( i = 0; i < ( graphGrid->grid->num_partitions*graphGrid->grid->num_partitions); ++i)
    //       {

    //       __u32 x = i % graphGrid->grid->num_partitions;    // % is the "modulo operator", the remainder of i / width;
    // __u32 y = i / graphGrid->grid->num_partitions;

    //      if(graphGrid->grid->partitions[i].num_edges){

    //       printf("| %-11s (%u,%u) \n", "Partition: ", y, x);
    //      printf("| %-11s %-40u   \n", "Edges: ", graphGrid->grid->partitions[i].num_edges);
    //      printf("| %-11s %-40u   \n", "Vertices: ", graphGrid->grid->partitions[i].num_vertices);
    //      edgeListPrint(graphGrid->grid->partitions[i].edgeList);
    //       }

    //       }


}


struct GraphGrid *graphGridNew(struct EdgeList *edgeList)
{


    struct GraphGrid *graphGrid = (struct GraphGrid *) my_malloc( sizeof(struct GraphGrid));

#if WEIGHTED
    graphGrid->max_weight =  edgeList->max_weight;
#endif

    graphGrid->num_edges = edgeList->num_edges;
    graphGrid->num_vertices = edgeList->num_vertices;

    graphGrid->grid = gridNew(edgeList);


    return graphGrid;

}

void   graphGridFree(struct GraphGrid *graphGrid)
{

    if(graphGrid->grid)
        gridFree(graphGrid->grid);

    if(graphGrid)
        free(graphGrid);

}



struct GraphGrid *graphGridPreProcessingStep (const char *fnameb, __u32 sort, __u32 lmode, __u32 symmetric, __u32 weighted)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));

    printf("Filename : %s \n", fnameb);


    Start(timer);
    struct EdgeList *edgeList = readEdgeListsbin(fnameb, 0, symmetric, weighted);
    Stop(timer);
    // edgeListPrint(edgeList);
    graphGridPrintMessageWithtime("Read Edge List From File (Seconds)", Seconds(timer));



    if(lmode)
        edgeList = reorderGraphProcess(sort, edgeList, lmode, symmetric, fnameb);

    // Start(timer);
    edgeList = sortRunAlgorithms(edgeList, sort);
    // Stop(timer);
    // graphGridPrintMessageWithtime("Radix Sort Edges By Source (Seconds)",Seconds(timer));

    Start(timer);
    struct GraphGrid *graphGrid = graphGridNew(edgeList);
    Stop(timer);
    graphGridPrintMessageWithtime("Create Graph Grid (Seconds)", Seconds(timer));


    graphGridPrint(graphGrid);


    freeEdgeList(edgeList);
    free(timer);
    return graphGrid;


}



void graphGridPrintMessageWithtime(const char *msg, double time)
{

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}

