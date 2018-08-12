#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "edgeList.h"
#include "myMalloc.h"
#include "graphConfig.h"
#include "adjArrayList.h"


void adjArrayListPrint(struct AdjArrayList *adjArrayList){

        __u32 i;
        struct Edge* pCrawl;
        if(adjArrayList->out_degree){
        pCrawl = adjArrayList->outNodes;
        for (i = 0; i < adjArrayList->out_degree; ++i)
        {
             printf("-> %d", pCrawl[i].dest);
        }
        printf("\n");
        }

        #if DIRECTED
        if(adjArrayList->in_degree){
         pCrawl = adjArrayList->inNodes;
         for (i = 0; i < adjArrayList->in_degree; ++i)
        {
            printf("<- %d", pCrawl[i].dest);
        }
            printf("\n");
        }
        #endif
    
}

struct AdjArrayList * adjArrayListNew(){

    #if ALIGNED
        struct AdjArrayList* newNode = (struct AdjArrayList*) my_aligned_alloc(sizeof(struct AdjArrayList));
    #else
        struct AdjArrayList* newNode = (struct AdjArrayList*) my_malloc(sizeof(struct AdjArrayList));
    #endif


        newNode->visited = 0;
        newNode->out_degree = 0;
        newNode->outNodes = NULL;

        #if DIRECTED
            newNode->in_degree = 0;
            newNode->inNodes = NULL;
        #endif

    return newNode;

}

struct AdjArrayList * adjArrayListCreateNeighbourList(struct AdjArrayList *adjArrayList){
       
        adjArrayList->outNodes = newEdgeArray(adjArrayList->out_degree);
        #if DIRECTED
            adjArrayList->inNodes = newEdgeArray(adjArrayList->in_degree);
        #endif

        return adjArrayList;
}

struct AdjArrayList * adjArrayListCreateNeighbourListOutNodes(struct AdjArrayList *adjArrayList){
       
       
      
        adjArrayList->outNodes = newEdgeArray(adjArrayList->out_degree);

        return adjArrayList;
}


struct AdjArrayList * adjArrayListCreateNeighbourListInNodes(struct AdjArrayList *adjArrayList){
       
       
      
        adjArrayList->inNodes = newEdgeArray(adjArrayList->in_degree);
    

        return adjArrayList;
}


void adjArrayListFree(struct AdjArrayList *adjArrayList){

    freeEdgeArray(adjArrayList->outNodes);
    
    #if DIRECTED
        freeEdgeArray(adjArrayList->inNodes);
    #endif
    
    free(adjArrayList);

}
