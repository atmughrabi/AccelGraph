#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <omp.h>

#include "graphCSR.h"
#include "vertex.h"
#include "myMalloc.h"

struct Vertex *newVertexArray(__u32 num_vertices)
{


    struct Vertex *vertex_array = (struct Vertex *) my_malloc( num_vertices * sizeof(struct Vertex));

    __u32 i;

    for(i = 0; i < num_vertices; i++)
    {

        vertex_array[i].edges_idx  = 0;
        vertex_array[i].out_degree = 0;
        vertex_array[i].in_degree  = 0;

    }

    return vertex_array;

}

struct GraphCSR *mapVertices (struct GraphCSR *graph, __u8 inverse)
{

    __u32 i;
    __u32 vertex_id;

    struct Vertex *vertices;
    struct EdgeList *sorted_edges_array;


#if DIRECTED
    if(inverse)
    {
        sorted_edges_array = graph->inverse_sorted_edges_array;
        vertices = graph->inverse_vertices; // sorted edge array
    }
    else
    {
        sorted_edges_array = graph->sorted_edges_array;
        vertices = graph->vertices;
    }

#else
    sorted_edges_array = graph->sorted_edges_array;
    vertices = graph->vertices;
#endif


    vertex_id = sorted_edges_array->edges_array_src[0];
    vertices[vertex_id].edges_idx = 0;

    for(i = 1; i < graph->num_edges; i++)
    {


        if(sorted_edges_array->edges_array_src[i] != sorted_edges_array->edges_array_src[i - 1])
        {

            vertex_id = sorted_edges_array->edges_array_src[i];
            vertices[vertex_id].edges_idx = i;

        }
    }

    return graph;

}

void partitionEdgeListOffsetStartEnd(struct GraphCSR *graph, struct EdgeList *sorted_edges_array, __u32 *offset_start, __u32 *offset_end)
{

    __u32 i;
    __u32 j;
    __u32 P = numThreads;

    if(P >  graph->num_edges && graph->num_edges != 0)
        P = graph->num_edges;


    for(i = 0 ; i < P ; i++)
    {

        offset_start[i] = 0;
        offset_end[i] = 0;

    }

    offset_start[0] = 0;
    offset_end[0] = offset_start[0] + (graph->num_edges / P);



    if(1 == (P))
    {
        offset_end[0] = graph->num_edges;
    }

    for(i = 1 ; i < P ; i++)
    {

        j = offset_end[i - 1];

        if(j == graph->num_edges)
        {
            offset_start[i] = graph->num_edges;
            offset_end[i] = graph->num_edges;
            continue;
        }


        for(; j < graph->num_edges; j++)
        {

            if(sorted_edges_array->edges_array_src[j] != sorted_edges_array->edges_array_src[j - 1])
            {
                offset_start[i] = j;
                offset_end[i - 1] = j;

                if(i == (P - 1))
                {
                    offset_end[i] = i * (graph->num_edges / P) + (graph->num_edges / P) + (graph->num_edges % P) ;
                }
                else
                {
                    offset_end[i] =  offset_start[i] + (graph->num_edges / P);
                }

                if(offset_end[i] > graph->num_edges && offset_start[i] < graph->num_edges)
                {
                    offset_end[i] = graph->num_edges;
                    // printf("3-%u %u\n", offset_start[i], offset_end[i] );
                }

                break;
            }
            else if(sorted_edges_array->edges_array_src[j] == sorted_edges_array->edges_array_src[j - 1] && j == (graph->num_edges - 1))
            {
                offset_start[i] = graph->num_edges;
                offset_end[i] = graph->num_edges;
                offset_end[i - 1] = graph->num_edges;

            }

        }


    }
    // for(i=0 ; i < P ; i++){

    //    printf("%u %u\n", offset_start[i], offset_end[i] );

    // }


}

struct GraphCSR *mapVerticesWithInOutDegree (struct GraphCSR *graph, __u8 inverse)
{

    __u32 i;
    __u32 vertex_id;
    // __u32 vertex_id_dest;
    __u32 P = numThreads;
    struct Vertex *vertices;
    struct EdgeList *sorted_edges_array;

    __u32 *offset_start_arr = (__u32 *) my_malloc( P * sizeof(__u32));
    __u32 *offset_end_arr = (__u32 *) my_malloc( P * sizeof(__u32));


#if DIRECTED

    if(inverse)
    {
        sorted_edges_array = graph->inverse_sorted_edges_array;
        vertices = graph->inverse_vertices; // sorted edge array
    }
    else
    {
        sorted_edges_array = graph->sorted_edges_array;
        vertices = graph->vertices;
    }

#else
    sorted_edges_array = graph->sorted_edges_array;
    vertices = graph->vertices;
#endif

    //edge list must be sorted
    partitionEdgeListOffsetStartEnd(graph, sorted_edges_array, offset_start_arr, offset_end_arr);


    __u32 t_id = 0;
    __u32 offset_start = 0;
    __u32 offset_end = 0;



    #pragma omp parallel default(none) private(i,vertex_id) shared(graph,vertices,sorted_edges_array,offset_start_arr,offset_end_arr) firstprivate(t_id, offset_end,offset_start)
    {

        t_id = omp_get_thread_num();

        offset_start = offset_start_arr[t_id];
        offset_end = offset_end_arr[t_id];

        // printf("t_id %u start %u end %u \n",t_id,offset_start, offset_end);

        if(offset_start < graph->num_edges)
        {

            vertex_id = sorted_edges_array->edges_array_src[offset_start];
            vertices[vertex_id].edges_idx = offset_start;
            vertices[vertex_id].out_degree++;

            for(i = offset_start + 1; i < offset_end; i++)
            {

                vertex_id = sorted_edges_array->edges_array_src[i];
                vertices[vertex_id].out_degree++;

                if(sorted_edges_array->edges_array_src[i] != sorted_edges_array->edges_array_src[i - 1])
                {
                    vertices[vertex_id].edges_idx = i;
                }
            }



        }

    }

    // optimization for BFS implentaion instead of -1 we use -out degree to for hybrid approach counter
    if(!inverse)
    {

        #pragma omp parallel for default(none) private(vertex_id) shared(vertices,graph)
        for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++)
        {
#if DIRECTED
            graph->inverse_vertices[vertex_id].in_degree = vertices[vertex_id].out_degree;
#endif
            if(vertices[vertex_id].out_degree)
                graph->parents[vertex_id] = vertices[vertex_id].out_degree * (-1);
            else
                graph->parents[vertex_id] = -1;
        }

    }
#if DIRECTED
    else
    {

        #pragma omp parallel for default(none) private(vertex_id) shared(vertices,graph)
        for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++)
        {
            graph->vertices[vertex_id].in_degree = vertices[vertex_id].out_degree;
        }

    }
#endif


    free(offset_start_arr);
    free(offset_end_arr);

    return graph;

}

void vertexArrayMaxOutdegree(struct Vertex *vertex_array, __u32 num_vertices)
{


    __u32 i;
    __u32 out_degree = 0;
    __u32 index = 0;
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Node", "*max_out_degree", "in_degree");
    printf(" -----------------------------------------------------\n");



    for(i = 0; i < num_vertices; i++)
    {


        out_degree = maxTwoIntegers(out_degree, vertex_array[i].out_degree);
        if(vertex_array[i].out_degree == out_degree)
            index = i;


    }


    printf("| %-15u | %-15u | %-15u | \n", index,  vertex_array[index].out_degree, vertex_array[index].in_degree);
    printf(" -----------------------------------------------------\n");

}

void vertexArrayMaxInDegree(struct Vertex *vertex_array, __u32 num_vertices)
{


    __u32 i;
    __u32 in_degree = 0;
    __u32 index = 0;
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Node", "out_degree", "*max_in_degree");
    printf(" -----------------------------------------------------\n");

    for(i = 0; i < num_vertices; i++)
    {


        in_degree = maxTwoIntegers(in_degree, vertex_array[i].out_degree);
        if(vertex_array[i].out_degree == in_degree)
            index = i;


    }


    printf("| %-15u | %-15u | %-15u | \n", index,  vertex_array[index].in_degree, vertex_array[index].out_degree);
    printf(" -----------------------------------------------------\n");

}

void printVertexArray(struct Vertex *vertex_array, __u32 num_vertices)
{


    __u32 i;

    printf("| %-15s | %-15s | %-15s |\n", "Node", "out_degree", "in_degree");

    for(i = 0; i < num_vertices; i++)
    {

        if((vertex_array[i].out_degree > 0) )
            printf("| %-15u | %-15u | %-15u | \n", i,  vertex_array[i].out_degree, vertex_array[i].in_degree);

    }

}

void freeVertexArray(struct Vertex *vertices)
{

    free(vertices);

}

