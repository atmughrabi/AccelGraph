#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <err.h>
#include <string.h>

#include "edgeList.h"
#include "vertex.h"
#include "myMalloc.h"
#include "graphCSR.h"
#include "graphConfig.h"
#include "graphStats.h"
#include "reorder.h"

//edgelist prerpcessing
// #include "countsort.h"
// #include "radixsort.h"
#include "sortRun.h"

#include "timer.h"

void graphCSRReset (struct GraphCSR *graphCSR)
{

    struct Vertex *vertices;
    __u32 vertex_id;
    // #if DIRECTED
    //     if(inverse){
    //         vertices = graph->inverse_vertices; // sorted edge array
    //     }else{
    //         vertices = graph->vertices;
    //     }
    // #else
    vertices = graphCSR->vertices;
    // #endif

    graphCSR->iteration = 0;
    graphCSR->processed_nodes = 0;

    #pragma omp parallel for default(none) private(vertex_id) shared(vertices,graphCSR)
    for(vertex_id = 0; vertex_id < graphCSR->num_vertices ; vertex_id++)
    {
        if(vertices->out_degree[vertex_id])
            graphCSR->parents[vertex_id] = vertices->out_degree[vertex_id] * (-1);
        else
            graphCSR->parents[vertex_id] = -1;
    }

}


void graphCSRHardReset (struct GraphCSR *graphCSR)
{


    __u32 vertex_id;

    graphCSR->iteration = 0;
    graphCSR->processed_nodes = 0;

    #pragma omp parallel for default(none) private(vertex_id) shared(graphCSR)
    for(vertex_id = 0; vertex_id < graphCSR->num_vertices ; vertex_id++)
    {
#if DIRECTED
        if(graphCSR->inverse_vertices)
        {
            graphCSR->inverse_vertices->in_degree[vertex_id] = 0;
            graphCSR->inverse_vertices->out_degree[vertex_id] = 0;
        }
#endif
        graphCSR->vertices->out_degree[vertex_id] = 0;
        graphCSR->vertices->in_degree[vertex_id] = 0;
        graphCSR->parents[vertex_id] = -1;
    }

}


void graphCSRFree (struct GraphCSR *graphCSR)
{

    if(graphCSR->vertices)
        freeVertexArray(graphCSR->vertices);
    if(graphCSR->parents)
        free(graphCSR->parents);
    if(graphCSR->sorted_edges_array)
        freeEdgeList(graphCSR->sorted_edges_array);

#if DIRECTED
    if(graphCSR->inverse_vertices)
        freeVertexArray(graphCSR->inverse_vertices);
    if(graphCSR->inverse_sorted_edges_array)
        freeEdgeList(graphCSR->inverse_sorted_edges_array);
#endif

    // if(graphCSR->parents)
    //    free(graphCSR->parents);

    if(graphCSR)
        free(graphCSR);



}

void graphCSRFreeDoublePointer (struct GraphCSR **graphCSR)
{

    if((*graphCSR)->vertices)
        freeVertexArray((*graphCSR)->vertices);
    if((*graphCSR)->parents)
        free((*graphCSR)->parents);
    if((*graphCSR)->sorted_edges_array)
        freeEdgeList((*graphCSR)->sorted_edges_array);

#if DIRECTED
    if((*graphCSR)->inverse_vertices)
        freeVertexArray((*graphCSR)->inverse_vertices);
    if((*graphCSR)->inverse_sorted_edges_array)
        freeEdgeList((*graphCSR)->inverse_sorted_edges_array);
#endif

    if((*graphCSR)->parents)
        free((*graphCSR)->parents);

    if((*graphCSR))
        free((*graphCSR));

}

void graphCSRPrint(struct GraphCSR *graphCSR)
{


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "GraphCSR Properties");
    printf(" -----------------------------------------------------\n");
#if WEIGHTED
    printf("| %-51s | \n", "WEIGHTED");
    printf("| %-51s | \n", "MAX WEIGHT");
    printf("| %-51u | \n", graphCSR->max_weight);
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
    printf("| %-51u | \n", graphCSR->num_vertices);
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Number of Edges (E)");
    printf("| %-51u | \n", graphCSR->num_edges);
    printf(" -----------------------------------------------------\n");



    vertexArrayMaxOutdegree(graphCSR->vertices, graphCSR->num_vertices);
#if DIRECTED
    vertexArrayMaxInDegree(graphCSR->inverse_vertices, graphCSR->num_vertices);
#endif

}


struct GraphCSR *graphCSRNew(__u32 V, __u32 E, __u8 inverse)
{
    int i;
    struct GraphCSR *graphCSR = (struct GraphCSR *) my_malloc( sizeof(struct GraphCSR));


    graphCSR->num_vertices = V;
    graphCSR->num_edges = E;

    graphCSR->vertices = newVertexArray(V);

#if DIRECTED
    if (inverse)
    {
        graphCSR->inverse_vertices = newVertexArray(V);
    }
#endif


    graphCSR->parents  = (int *) my_malloc( V * sizeof(int));


    #pragma omp for
    for(i = 0; i < V; i++)
    {
        graphCSR->parents[i] = -1;
    }

    graphCSR->iteration = 0;
    graphCSR->processed_nodes = 0;

    return graphCSR;
}

void graphCSRPrintParentsArray(struct GraphCSR *graphCSR)
{


    __u32 i;

    printf("| %-15s | %-15s | %-15s |  \n", "Node", "out_degree", "Parent");

    for(i = 0; i < graphCSR->num_vertices; i++)
    {

        if((graphCSR->vertices->out_degree[i] > 0) || (graphCSR->vertices->in_degree[i] > 0))
            printf("| %-15u | %-15u | %-15d | \n", i,  graphCSR->vertices->out_degree[i], graphCSR->parents[i]);

    }

}


struct GraphCSR *graphCSRAssignEdgeList (struct GraphCSR *graphCSR, struct EdgeList *edgeList, __u8 inverse)
{


#if DIRECTED

    if(inverse)
        graphCSR->inverse_sorted_edges_array = edgeList;
    else
        graphCSR->sorted_edges_array = edgeList;

#else

    graphCSR->sorted_edges_array = edgeList;

#endif

#if WEIGHTED
    graphCSR->max_weight =  edgeList->max_weight;
#endif

    return mapVerticesWithInOutDegree (graphCSR, inverse);


}


struct GraphCSR *graphCSRPreProcessingStep (const char *fnameb, __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted)
{

    struct Timer *timer = (struct Timer *) malloc(sizeof(struct Timer));

    Start(timer);
    struct EdgeList *edgeList = readEdgeListsbin(fnameb, 0, symmetric, weighted); // read edglist from binary file
    Stop(timer);
    // edgeListPrint(edgeList);
    graphCSRPrintMessageWithtime("Read Edge List From File (Seconds)", Seconds(timer));



    if(lmode)
        edgeList = reorderGraphProcess(sort, edgeList, lmode, symmetric, fnameb);


#if DIRECTED
    struct GraphCSR *graphCSR = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 1);
#else
    struct GraphCSR *graphCSR = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 0);
#endif

    Start(timer);
    edgeList = sortRunAlgorithms(edgeList, sort);

    // edgeListPrint(edgeList);
    Start(timer);
    graphCSR = graphCSRAssignEdgeList (graphCSR, edgeList, 0);
    Stop(timer);



    graphCSRPrintMessageWithtime("Process In/Out degrees of Nodes (Seconds)", Seconds(timer));

#if DIRECTED

    Start(timer);
    struct EdgeList *inverse_edgeList = readEdgeListsMem(edgeList, 1, symmetric); // read edglist from memory since we pre loaded it
    Stop(timer);

    graphCSRPrintMessageWithtime("Read Inverse Edge List From Memory (Seconds)", Seconds(timer));

    inverse_edgeList = sortRunAlgorithms(inverse_edgeList, sort);

    Start(timer);
    graphCSR = graphCSRAssignEdgeList (graphCSR, inverse_edgeList, 1);
    Stop(timer);
    graphCSRPrintMessageWithtime("Process In/Out degrees of Inverse Nodes (Seconds)", Seconds(timer));

#endif


    graphCSRPrint(graphCSR);


    free(timer);

    return graphCSR;


}

void writeToBinFileGraphCSR (const char *fname, struct GraphCSR *graph)
{

    //     struct  Vertex
    // {

    //     __u8 visited;
    //     __u32 out_degree;
    //     __u32 in_degree;
    //     __u32 edges_idx;
    // };

    // struct  EdgeList
    // {

    //     __u32 num_edges;
    //     __u32 num_vertices;
    // #if WEIGHTED
    //     __u32 max_weight;
    //     __u32 *edges_array_weight;
    // #endif
    //     __u32 *edges_array_src;
    //     __u32 *edges_array_dest;
    // };

    // struct GraphCSR
    // {

    //     __u32 num_edges;
    //     __u32 num_vertices;

    // #if WEIGHTED
    //     __u32 max_weight;
    // #endif
    //     // __u32* vertex_count; // needed for counting sort
    //     int *parents;       // specify parent for each vertex // will be removed to stats struct
    //     __u32 iteration;
    //     __u32 processed_nodes;

    //     struct Vertex *vertices;
    //     struct EdgeList *sorted_edges_array; // sorted edge array

    // #if DIRECTED
    //     struct Vertex *inverse_vertices;
    //     struct EdgeList *inverse_sorted_edges_array; // sorted edge array
    // #endif
    // };


    //write data to file binary
    // num_edges
    // num_vertices

    // #if WEIGHTED
    //      max_weight;
    // #endif

    FILE  *pBinary;

#if WEIGHTED

#endif

    char *fname_txt = (char *) malloc((strlen(fname) + 10) * sizeof(char));
    char *fname_bin = (char *) malloc((strlen(fname) + 10) * sizeof(char));

    fname_txt = strcpy (fname_txt, fname);
    fname_bin = strcat (fname_txt, ".csr");

    pBinary = fopen(fname_bin, "wb");

    if (pBinary == NULL)
    {
        err(1, "open: %s", fname_bin);
        return ;
    }

    fwrite(&(graph->num_edges), sizeof (graph->num_edges), 1, pBinary);
    fwrite(&(graph->num_vertices), sizeof (graph->num_vertices), 1, pBinary);
#if WEIGHTED
    fwrite(&(graph->max_weight), sizeof (graph->max_weight), 1, pBinary);
#endif



}


struct GraphCSR *readFromBinFileGraphCSR (const char *fname)
{

    struct GraphCSR * graphCSR = NULL;


    return graphCSR;

}

void graphCSRPrintMessageWithtime(const char *msg, double time)
{

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}
