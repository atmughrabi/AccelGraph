#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <omp.h>

#include "graphCSR.h"
#include "vertex.h"
#include "myMalloc.h"

struct Vertex* newVertexArray(__u32 num_vertices){

        // struct Vertex* vertex_array = (struct Vertex*) aligned_alloc(CACHELINE_BYTES, num_vertices * sizeof(struct Vertex));
		
	#if ALIGNED
        struct Vertex* vertex_array = (struct Vertex*) my_aligned_malloc( num_vertices * sizeof(struct Vertex));
    #else
        struct Vertex* vertex_array = (struct Vertex*) my_malloc( num_vertices * sizeof(struct Vertex));
    #endif


        __u32 i;

        for(i = 0; i < num_vertices; i++){

                vertex_array[i].edges_idx  = 0;
                vertex_array[i].visited    = 0;
                vertex_array[i].out_degree = 0;
                vertex_array[i].in_degree  = 0;

        }

        return vertex_array;

}

struct GraphCSR* mapVertices (struct GraphCSR* graph, __u8 inverse){

    __u32 i;
    __u32 vertex_id;

    struct Vertex* vertices;
    struct Edge* sorted_edges_array;
    

    #if DIRECTED

        if(inverse){
            sorted_edges_array = graph->inverse_sorted_edges_array;
            vertices = graph->inverse_vertices; // sorted edge array
        }else{
            sorted_edges_array = graph->sorted_edges_array;
            vertices = graph->vertices;
        }

    #else
            sorted_edges_array = graph->sorted_edges_array;
            vertices = graph->vertices;
    #endif


    vertex_id = sorted_edges_array[0].src;
    vertices[vertex_id].edges_idx = 0;

    for(i =1; i < graph->num_edges; i++){

        
        if(sorted_edges_array[i].src != sorted_edges_array[i-1].src){      

            vertex_id = sorted_edges_array[i].src;
            vertices[vertex_id].edges_idx = i; 
     
        }
    }

return graph;

}

void partitionEdgeListOffsetStartEnd(struct GraphCSR* graph, struct Edge* sorted_edges_array, __u32* offset_start,__u32* offset_end){

    __u32 i;
    __u32 j;
    __u32 P = numThreads;

 

    for(i=0 ; i < P ; i++){
    
        offset_start[i] = 0;
        offset_end[i] = 0;

    }

    offset_start[0] = 0;
    offset_end[0] = offset_start[0] + (graph->num_edges/P);


    for(i=1 ; i < P ; i++){

        j = offset_end[i-1];

        if(j == graph->num_edges){
            offset_start[i] = graph->num_edges;
            offset_end[i] = graph->num_edges;
            continue;
        }
          

        for(; j < graph->num_edges; j++){
            // printf("j %u \n",j );
             if(sorted_edges_array[j].src != sorted_edges_array[j-1].src){  
                offset_start[i] = j;
                offset_end[i-1] = j;

                if(i == (P-1)){
                    offset_end[i] = i*(graph->num_edges/P) + (graph->num_edges/P) + (graph->num_edges%P) ;
                }
                else{
                    offset_end[i] =  offset_start[i] + (graph->num_edges/P);
                }

                if(offset_end[i] > graph->num_edges && offset_start[i] < graph->num_edges){
                    offset_end[i] = graph->num_edges;       
                }
                break;
             }

            
         }

       
    }
     for(i=0 ; i < P ; i++){


     }


}

struct GraphCSR* mapVerticesWithInOutDegree (struct GraphCSR* graph, __u8 inverse){

    __u32 i;
    __u32 vertex_id;
    // __u32 vertex_id_dest;
    __u32 P = numThreads; 
     struct Vertex* vertices;
     struct Edge* sorted_edges_array;
    

    #if ALIGNED
        __u32* offset_start_arr = (__u32*) my_aligned_malloc( P * sizeof(__u32));
        __u32* offset_end_arr = (__u32*) my_aligned_malloc( P * sizeof(__u32));
        __u32* sorted_edge_array = (__u32*) my_aligned_malloc( graph->num_edges * sizeof(__u32));
    #else
        __u32* offset_start_arr = (__u32*) my_malloc( P * sizeof(__u32));
        __u32* offset_end_arr = (__u32*) my_malloc( P * sizeof(__u32));
        __u32* sorted_edge_array = (__u32*) my_malloc( graph->num_edges * sizeof(__u32));
    #endif

   
    
    #if DIRECTED

        if(inverse){
            sorted_edges_array = graph->inverse_sorted_edges_array;
            vertices = graph->inverse_vertices; // sorted edge array
            graph->inverse_sorted_edge_array = sorted_edge_array;
        }else{
            sorted_edges_array = graph->sorted_edges_array;
            vertices = graph->vertices;
            graph->sorted_edge_array = sorted_edge_array;
        }
    
    #else
            sorted_edges_array = graph->sorted_edges_array;
            vertices = graph->vertices;
            graph->sorted_edge_array = sorted_edge_array;
    #endif
    
   //edge list must be sorted 
    partitionEdgeListOffsetStartEnd(graph, sorted_edges_array, offset_start_arr, offset_end_arr);


    __u32 t_id = 0;
    __u32 offset_start = 0;
    __u32 offset_end = 0;

    

    #pragma omp parallel default(none) private(i,vertex_id) shared(graph,sorted_edge_array,vertices,sorted_edges_array,offset_start_arr,offset_end_arr) firstprivate(t_id, offset_end,offset_start) 
    {
        
        t_id = omp_get_thread_num();

        offset_start = offset_start_arr[t_id];
        offset_end = offset_end_arr[t_id];

        if(offset_start < graph->num_edges){

        vertex_id = sorted_edges_array[offset_start].src;
        vertices[vertex_id].edges_idx = offset_start;
        vertices[vertex_id].out_degree++;

         // printf("tid %u start %u end %u v vertex_id %u\n",t_id,offset_start,offset_end,vertex_id );

        sorted_edge_array[offset_start] = sorted_edges_array[offset_start].dest;

        for(i = offset_start+1; i < offset_end; i++){

        sorted_edge_array[i] = sorted_edges_array[i].dest;
        
        if(sorted_edges_array[i].src != sorted_edges_array[i-1].src){      

            vertex_id = sorted_edges_array[i].src;
            vertices[vertex_id].edges_idx = i; 
            vertices[vertex_id].out_degree++;
         
        }
        else{
            vertices[vertex_id].out_degree++;
           
            }
        }
    }

    }

// optimization for BFS implentaion instead of -1 we use -out degree to for hybrid approach counter
    if(!inverse){

    #pragma omp parallel for default(none) private(vertex_id) shared(vertices,graph)
    for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++){
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
    else{
       
            #pragma omp parallel for default(none) private(vertex_id) shared(vertices,graph)
            for(vertex_id = 0; vertex_id < graph->num_vertices ; vertex_id++){
                graph->vertices[vertex_id].in_degree = vertices[vertex_id].out_degree;          
            }
        
    }
    #endif

    // if(graph->sorted_edges_array)
    //     freeEdgeArray(graph->sorted_edges_array);
    // #if DIRECTED
    //     if(inverse)
    //     if(graph->inverse_sorted_edges_array)
    //         freeEdgeArray(graph->inverse_sorted_edges_array);
    // #endif

// printVertexArray(graph->vertices, graph->num_vertices);
// printVertexArray(graph->inverse_vertices, graph->num_vertices);
// printVertexArray(graph->vertices,graph->num_vertices);
return graph;

}

void vertexArrayMaxOutdegree(struct Vertex* vertex_array, __u32 num_vertices){


    __u32 i;
    __u32 out_degree = 0;
    __u32 index = 0;
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Node", "*max_out_degree", "in_degree");
    printf(" -----------------------------------------------------\n");



    for(i =0; i < num_vertices; i++){


        out_degree = maxTwoIntegers(out_degree, vertex_array[i].out_degree);
        if(vertex_array[i].out_degree == out_degree)
            index = i;
       
        
    }


    printf("| %-15u | %-15u | %-15u | \n",index,  vertex_array[index].out_degree, vertex_array[index].in_degree);
    printf(" -----------------------------------------------------\n");

}

void vertexArrayMaxInDegree(struct Vertex* vertex_array, __u32 num_vertices){


    __u32 i;
    __u32 in_degree = 0;
    __u32 index = 0;
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Node", "out_degree", "*max_in_degree");
    printf(" -----------------------------------------------------\n");

    for(i =0; i < num_vertices; i++){


        in_degree = maxTwoIntegers(in_degree, vertex_array[i].out_degree);
        if(vertex_array[i].out_degree == in_degree)
            index = i;
       
        
    }


    printf("| %-15u | %-15u | %-15u | \n",index,  vertex_array[index].in_degree, vertex_array[index].out_degree);
   printf(" -----------------------------------------------------\n");

}

void printVertexArray(struct Vertex* vertex_array, __u32 num_vertices){


    __u32 i;

    printf("| %-15s | %-15s | %-15s | %-15s | \n", "Node", "out_degree", "in_degree", "visited");

    for(i =0; i < num_vertices; i++){

        if((vertex_array[i].out_degree > 0) )
        printf("| %-15u | %-15u | %-15u | %-15u | \n",i,  vertex_array[i].out_degree, vertex_array[i].in_degree, vertex_array[i].visited);
    
    }

}

void freeVertexArray(struct Vertex* vertices){

	free(vertices);

}

