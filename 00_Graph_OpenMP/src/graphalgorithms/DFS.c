#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayStack.h"
#include "bitmap.h"
#include "DFS.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"



// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************



void depthFirstSearchGraphCSRBase(__u32 source, struct GraphCSR *graph)
{


    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct ArrayStack *sharedFrontierStack = newArrayStack(graph->num_vertices);

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source < 0 && source > graph->num_vertices)
    {
        printf(" -----------------------------------------------------\n");
        printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
        printf(" -----------------------------------------------------\n");
        return;
    }

    graphCSRReset(graph);


    pushArrayStack(sharedFrontierStack, source);

    graph->parents[source] = source;




    Start(timer);
    while(!isEmptyArrayStackCurr(sharedFrontierStack))  // start while
    {



        __u32 v = popArrayStack(sharedFrontierStack);

        graph->processed_nodes++;
        __u32 edge_idx = graph->vertices->edges_idx[v];
        __u32 j;


        for(j = edge_idx ; j < (edge_idx + graph->vertices->out_degree[v]) ; j++)
        {

            __u32 u = graph->sorted_edges_array->edges_array_dest[j];
            int u_parent = graph->parents[u];
            if(u_parent < 0 )
            {
                graph->parents[u] = v;
                pushArrayStack(sharedFrontierStack, u);
            }
        }


    } // end while
    Stop(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "No OverHead", graph->processed_nodes,  Seconds(timer));
    printf(" -----------------------------------------------------\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "total", graph->processed_nodes, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    freeArrayStack(sharedFrontierStack);

    free(timer);
}



void depthFirstSearchGraphCSR(__u32 source, struct GraphCSR *graph)
{


    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));
    struct ArrayStack *sharedFrontierStack = newArrayStack(graph->num_vertices);


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source < 0 && source > graph->num_vertices)
    {
        printf(" -----------------------------------------------------\n");
        printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
        printf(" -----------------------------------------------------\n");
        return;
    }

    graphCSRReset(graph);

    pushArrayStack(sharedFrontierStack, source);
    graph->parents[source] = source;



    Start(timer);
    while(!isEmptyArrayStackCurr(sharedFrontierStack))  // start while
    {

        __u32 v = popArrayStack(sharedFrontierStack);

        graph->processed_nodes++;
        __u32 edge_idx = graph->vertices->edges_idx[v];
        __u32 j;

        for(j = edge_idx ; j < (edge_idx + graph->vertices->out_degree[v]) ; j++)
        {

            __u32 u = graph->sorted_edges_array->edges_array_dest[j];
            int u_parent = graph->parents[u];
            if(u_parent < 0 )
            {
                graph->parents[u] = v;
                pushArrayStack(sharedFrontierStack, u);
            }
        }


    } // end while
    Stop(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "No OverHead", graph->processed_nodes,  Seconds(timer));
    printf(" -----------------------------------------------------\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "total", graph->processed_nodes, Seconds(timer));
    printf(" -----------------------------------------------------\n");


    freeArrayStack(sharedFrontierStack);

    free(timer);

}

void pDepthFirstSearchGraphCSR(__u32 source, struct GraphCSR *graph)
{


    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting P-Depth First Search (SOURCE NODE)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51u | \n", source);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Nodes", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

    if(source < 0 && source > graph->num_vertices)
    {
        printf(" -----------------------------------------------------\n");
        printf("| %-51s | \n", "ERROR!! CHECK SOURCE RANGE");
        printf(" -----------------------------------------------------\n");
        return;
    }

    graphCSRReset(graph);

    graph->parents[source] = source;

    Start(timer);


    pDepthFirstSearchGraphCSRTask( source, graph );

    Stop(timer);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "No OverHead", graph->processed_nodes,  Seconds(timer));
    printf(" -----------------------------------------------------\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15u | %-15f | \n", "total", graph->processed_nodes, Seconds(timer));
    printf(" -----------------------------------------------------\n");

    graphCSRReset(graph);

    free(timer);

}

void pDepthFirstSearchGraphCSRTask(__u32 source, struct GraphCSR *graph)
{

    __u32 v = source;

    #pragma omp atomic update
    graph->processed_nodes++;

    // printf("%u \n", graph->processed_nodes);

    __u32 edge_idx = graph->vertices->edges_idx[v];
    __u32 j;

    for(j = edge_idx ; j < (edge_idx + graph->vertices->out_degree[v]) ; j++)
    {

        __u32 u = graph->sorted_edges_array->edges_array_dest[j];
        int u_parent = graph->parents[u];
        if(u_parent < 0 )
        {
            if(__sync_bool_compare_and_swap(&graph->parents[u], u_parent, v))
            {

                // #pragma omp task
                pDepthFirstSearchGraphCSRTask( u, graph);

            }
        }
    }

}
