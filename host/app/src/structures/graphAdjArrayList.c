#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphAdjArrayList.h"
#include "graphConfig.h"
#include "adjArrayList.h"
#include "timer.h"


void graphAdjArrayListPrintMessageWithtime(const char * msg, double time){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}



// A utility function that creates a graphAdjArrayList of V vertices
struct GraphAdjArrayList* graphAdjArrayListGraphNew(__u32 V){

    // printf("\n Create graphAdjArrayList #Vertecies: %d\n ", V);

	// struct graphAdjArrayList* graphAdjArrayList = (struct graphAdjArrayList*) aligned_alloc(CACHELINE_BYTES, sizeof(struct graphAdjArrayList));
    #if ALIGNED
        struct GraphAdjArrayList* graphAdjArrayList = (struct GraphAdjArrayList*) my_aligned_alloc( sizeof(struct GraphAdjArrayList));
    #else
        struct GraphAdjArrayList* graphAdjArrayList = (struct GraphAdjArrayList*) my_malloc( sizeof(struct GraphAdjArrayList));
    #endif

	graphAdjArrayList->num_vertices = V;
	// graphAdjArrayList->parent_array = (struct AdjArrayList*) aligned_alloc(CACHELINE_BYTES, V * sizeof(struct AdjArrayList));
    #if ALIGNED
        graphAdjArrayList->parent_array = (struct AdjArrayList*) my_aligned_alloc( V * sizeof(struct AdjArrayList));
    #else
        graphAdjArrayList->parent_array = (struct AdjArrayList*) my_malloc( V * sizeof(struct AdjArrayList));
    #endif

	__u32 i;
	for(i = 0; i < V; i++){

        graphAdjArrayList->parent_array[i].visited = 0;
		graphAdjArrayList->parent_array[i].outNodes = NULL;
        graphAdjArrayList->parent_array[i].out_degree = 0; 

        #if DIRECTED
            graphAdjArrayList->parent_array[i].inNodes = NULL; 
            graphAdjArrayList->parent_array[i].in_degree = 0;
        #endif

        graphAdjArrayList->parent_array[i].visited = 0;
	}

    // printf("\n Success!!! V: %d\n ", V);

    return graphAdjArrayList;

}

struct GraphAdjArrayList* graphAdjArrayListEdgeListNew(struct EdgeList* edgeList){

    // printf("\n Create graphAdjArrayList #Vertecies: %d\n ", V);
    struct GraphAdjArrayList* graphAdjArrayList;

    graphAdjArrayList = graphAdjArrayListGraphNew(edgeList->num_vertices);
    
    graphAdjArrayList->num_edges = edgeList->num_edges;

    graphAdjArrayList = graphAdjArrayListEdgeListProcessInOutDegree(graphAdjArrayList, edgeList);

    graphAdjArrayList = graphAdjArrayListEdgeAllocate(graphAdjArrayList);

    graphAdjArrayList = graphAdjArrayListEdgePopulate(graphAdjArrayList, edgeList);

    return graphAdjArrayList;

}

struct GraphAdjArrayList* graphAdjArrayListEdgeListNewWithInverse(struct EdgeList* edgeList, struct EdgeList* inverseEdgeList){

    struct Timer* timer = (struct Timer*) my_malloc( sizeof(struct Timer));

    struct GraphAdjArrayList* graphAdjArrayList;

    Start(timer);
    graphAdjArrayList = graphAdjArrayListGraphNew(edgeList->num_vertices);
    
    graphAdjArrayList->num_edges = edgeList->num_edges;
    Stop(timer);
    graphAdjArrayListPrintMessageWithtime("Graph AdjArrayList New (Seconds)",Seconds(timer));

    

    Start(timer);
    graphAdjArrayList = graphAdjArrayListEdgeListProcessOutDegree(graphAdjArrayList, edgeList);
    Stop(timer);
    graphAdjArrayListPrintMessageWithtime("Graph EdgeList Process OutDegree (Seconds)",Seconds(timer));

    #if DIRECTED
        Start(timer);
        graphAdjArrayList = graphAdjArrayListEdgeListProcessInDegree(graphAdjArrayList, inverseEdgeList);
        Stop(timer);
        graphAdjArrayListPrintMessageWithtime("Graph EdgeList Process InDegree (Seconds)",Seconds(timer));
    #endif

    Start(timer);
    graphAdjArrayList = graphAdjArrayListEdgeAllocate(graphAdjArrayList);
    Stop(timer);
    graphAdjArrayListPrintMessageWithtime("Graph Edge Allocate Memory (Seconds)",Seconds(timer));

    Start(timer);
    graphAdjArrayList = graphAdjArrayListEdgePopulateOutNodes(graphAdjArrayList, edgeList);
    Stop(timer);
    graphAdjArrayListPrintMessageWithtime("Graph Populate OutNodes (Seconds)",Seconds(timer));

    #if DIRECTED
        Start(timer);
        graphAdjArrayList = graphAdjArrayListEdgePopulateInNodes(graphAdjArrayList, inverseEdgeList);
        Stop(timer);
        graphAdjArrayListPrintMessageWithtime("Graph Populate InNodes (Seconds)",Seconds(timer));
    #endif


    free(timer);
    return graphAdjArrayList;



}



struct GraphAdjArrayList* graphAdjArrayListEdgeListProcessInOutDegree(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList){

     __u32 i;
     __u32 src;

      #if DIRECTED 
      __u32 dest;
      #endif

    for(i = 0; i < edgeList->num_edges; i++){

        
        src =  edgeList->edges_array[i].src;

        #if DIRECTED
            dest = edgeList->edges_array[i].dest;
            graphAdjArrayList->parent_array[dest].in_degree++;
        #endif
            graphAdjArrayList->parent_array[src].out_degree++;
    
    }

    return graphAdjArrayList;

}

struct GraphAdjArrayList* graphAdjArrayListEdgeListProcessOutDegree(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList){

     __u32 i;
     __u32 src;

    for(i = 0; i < edgeList->num_edges; i++){

        src =  edgeList->edges_array[i].src;
        graphAdjArrayList->parent_array[src].out_degree++;
    
    
    }

    return graphAdjArrayList;

}

struct GraphAdjArrayList* graphAdjArrayListEdgeListProcessInDegree(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* inverseEdgeList){

     __u32 i;
    __u32 dest;
    

    for(i = 0; i < inverseEdgeList->num_edges; i++){

        dest =  inverseEdgeList->edges_array[i].src;
        graphAdjArrayList->parent_array[dest].in_degree++;
    
    }

    return graphAdjArrayList;

}




struct GraphAdjArrayList* graphAdjArrayListEdgeAllocate(struct GraphAdjArrayList* graphAdjArrayList){

     __u32 v;
    for(v = 0; v < graphAdjArrayList->num_vertices; v++){

        adjArrayListCreateNeighbourList(&(graphAdjArrayList->parent_array[v]));

        #if DIRECTED
              graphAdjArrayList->parent_array[v].in_degree =  0;
        #endif
        graphAdjArrayList->parent_array[v].out_degree = 0; // will be used as an index to edge array outnode
    
    }

    return graphAdjArrayList;

}




struct GraphAdjArrayList* graphAdjArrayListEdgePopulate(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList){

     __u32 i;
     __u32 src;

     #if DIRECTED
     __u32 dest;
     __u32 in_degree;
     #endif

     __u32 out_degree;
    

    for(i = 0; i < edgeList->num_edges; i++){

        src =  edgeList->edges_array[i].src;
        
                 
        out_degree = graphAdjArrayList->parent_array[src].out_degree;
        graphAdjArrayList->parent_array[src].outNodes[out_degree] = edgeList->edges_array[i];
        graphAdjArrayList->parent_array[src].out_degree++;

        #if DIRECTED
            dest = edgeList->edges_array[i].dest;
            in_degree = graphAdjArrayList->parent_array[dest].in_degree;
            graphAdjArrayList->parent_array[dest].inNodes[in_degree] = edgeList->edges_array[i];
            graphAdjArrayList->parent_array[dest].in_degree++;
        #endif  
            
    
    }

    return graphAdjArrayList;

}


struct GraphAdjArrayList* graphAdjArrayListEdgePopulateOutNodes(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* edgeList){

     __u32 i;
     __u32 src;
     __u32 out_degree;
    

    for(i = 0; i < edgeList->num_edges; i++){

        src =  edgeList->edges_array[i].src;
                 
        out_degree = graphAdjArrayList->parent_array[src].out_degree;
        graphAdjArrayList->parent_array[src].outNodes[out_degree] = edgeList->edges_array[i];
        graphAdjArrayList->parent_array[src].out_degree++;  
    
    }

    return graphAdjArrayList;

}


struct GraphAdjArrayList* graphAdjArrayListEdgePopulateInNodes(struct GraphAdjArrayList* graphAdjArrayList, struct EdgeList* inverseEdgeList){

     __u32 i;
     __u32 dest;
     __u32 in_degree;
   

    for(i = 0; i < inverseEdgeList->num_edges; i++){

            dest = inverseEdgeList->edges_array[i].src;
            in_degree = graphAdjArrayList->parent_array[dest].in_degree;
            graphAdjArrayList->parent_array[dest].inNodes[in_degree] = inverseEdgeList->edges_array[i];
            graphAdjArrayList->parent_array[dest].in_degree++;
    
    }

    return graphAdjArrayList;

}



// // A utility function to print the adjacency list 
// // representation of graphAdjArrayList
void graphAdjArrayListPrint(struct GraphAdjArrayList* graphAdjArrayList){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "GraphAdjArrayList Properties");
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
    printf("| %-51u | \n", graphAdjArrayList->num_vertices);
    printf(" -----------------------------------------------------\n"); 
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", graphAdjArrayList->num_edges);  
    printf(" -----------------------------------------------------\n");

    struct AdjArrayList* pCrawl;
    __u32 v;
    for (v = 0; v < graphAdjArrayList->num_vertices; v++){

        pCrawl = &(graphAdjArrayList->parent_array[v]);
        if(pCrawl){

            printf("\n Node : %d \n", v);
            adjArrayListPrint(pCrawl);
        }

    }

}


void graphAdjArrayListFree(struct GraphAdjArrayList* graphAdjArrayList){

    __u32 v;
    struct AdjArrayList* pCrawl;

    for (v = 0; v < graphAdjArrayList->num_vertices; ++v)
    {
        pCrawl = &(graphAdjArrayList->parent_array[v]);
        
        freeEdgeArray(pCrawl->outNodes);
        #if DIRECTED
            freeEdgeArray(pCrawl->inNodes);
        #endif
       
    }

    free(graphAdjArrayList->parent_array);
    free(graphAdjArrayList);


}


