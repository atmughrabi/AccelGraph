#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "grid.h"
#include "graphGrid.h"
#include "edgeList.h"
#include "myMalloc.h"
#include "graphConfig.h"


void  graphGridPrint(struct GraphGrid *graphGrid){


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

    // __u32 i;
  //    for ( i = 0; i < ( graphGrid->grid->num_partitions*graphGrid->grid->num_partitions); ++i)
  //       {

  //       __u32 x = i % graphGrid->grid->num_partitions;    // % is the "modulo operator", the remainder of i / width;
		// __u32 y = i / graphGrid->grid->num_partitions;
	   
  //      if(graphGrid->grid->partitions[i].num_edges){

  //       printf("| %-11s (%u,%u) \n", "Partition: ", y, x);
  //  		printf("| %-11s %-40u   \n", "Edges: ", graphGrid->grid->partitions[i].num_edges);  
  //  		printf("| %-11s %-40u   \n", "Vertices: ", graphGrid->grid->partitions[i].num_vertices);  
  //  		// edgeListPrint(graphGrid->grid->partitions[i].edgeList);
  //       }

  //       }


}

struct GraphGrid * graphGridNew(struct EdgeList* edgeList){


    #if ALIGNED
        struct GraphGrid* graphGrid = (struct GraphGrid*) my_aligned_alloc(sizeof(struct GraphGrid));
    #else
        struct GraphGrid* graphGrid = (struct GraphGrid*) my_malloc( sizeof(struct GraphGrid));
    #endif

     graphGrid->num_edges = edgeList->num_edges;
     graphGrid->num_vertices = edgeList->num_vertices;

     graphGrid->grid = gridNew(edgeList); 


     return graphGrid;

}

void   graphGridFree(struct GraphGrid *graphGrid){

    gridFree(graphGrid->grid);
    free(graphGrid);

}




