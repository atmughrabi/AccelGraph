#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// #include "adjlist.h"
#include "capienv.h"
// #include "countsort.h"
// #include "edgelist.h"

#include "vertex.h"
#include "mymalloc.h"

struct Vertex* newVertexArray(__u32 num_vertices){

        // struct Vertex* vertex_array = (struct Vertex*) aligned_alloc(CACHELINE_BYTES, num_vertices * sizeof(struct Vertex));
		
	#if ALIGNED
        struct Vertex* vertex_array = (struct Vertex*) my_aligned_alloc( num_vertices * sizeof(struct Vertex));
    #else
        struct Vertex* vertex_array = (struct Vertex*) my_malloc( num_vertices * sizeof(struct Vertex));
    #endif


        __u32 i;

        for(i = 0; i < num_vertices; i++){

                vertex_array[i].edges_idx  = NO_OUTGOING_EDGES;
                vertex_array[i].visited    = 0;
                vertex_array[i].out_degree = 0;
                vertex_array[i].in_degree  = 0;

        }

        return vertex_array;

}

struct Graph* mapVertices (struct Graph* graph){

    __u32 i;
    __u32 vertex_id;
  
    vertex_id = graph->sorted_edges_array[0].src;
    graph->vertices[vertex_id].edges_idx = 0;

    for(i =1; i < graph->num_edges; i++){

        
        if(graph->sorted_edges_array[i].src != graph->sorted_edges_array[i-1].src){      

            vertex_id = graph->sorted_edges_array[i].src;
            graph->vertices[vertex_id].edges_idx = i; 
     
        }
    }

return graph;

}

struct Graph* mapVerticesWithInOutDegree (struct Graph* graph){

    __u32 i;
    __u32 vertex_id;
    __u32 vertex_id_dest;


    vertex_id_dest = graph->sorted_edges_array[0].dest;
    vertex_id = graph->sorted_edges_array[0].src;

    graph->vertices[vertex_id].edges_idx = 0;
    graph->vertices[vertex_id].out_degree++;
    graph->vertices[vertex_id_dest].in_degree++;

    for(i =1; i < graph->num_edges; i++){

        
        if(graph->sorted_edges_array[i].src != graph->sorted_edges_array[i-1].src){      

            vertex_id = graph->sorted_edges_array[i].src;
            vertex_id_dest = graph->sorted_edges_array[i].dest;
            graph->vertices[vertex_id].edges_idx = i; 
            graph->vertices[vertex_id].out_degree++;      
            graph->vertices[vertex_id_dest].in_degree++;  
            // printf("1| %-15u | %-15u | %-15u | %-15u | \n", vertex_id, vertex_id_dest, graph->vertices[vertex_id].out_degree, graph->vertices[vertex_id_dest].in_degree );


        }else{

            vertex_id_dest = graph->sorted_edges_array[i].dest;
            graph->vertices[vertex_id].out_degree++;
            graph->vertices[vertex_id_dest].in_degree++;
            // printf("2| %-15u | %-15u | %-15u | %-15u | \n", vertex_id, vertex_id_dest, graph->vertices[vertex_id].out_degree, graph->vertices[vertex_id_dest].in_degree );

        }
    }

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


        in_degree = maxTwoIntegers(in_degree, vertex_array[i].in_degree);
        if(vertex_array[i].in_degree == in_degree)
            index = i;
       
        
    }


    printf("| %-15u | %-15u | %-15u | \n",index,  vertex_array[index].out_degree, vertex_array[index].in_degree);
   printf(" -----------------------------------------------------\n");

}

void printVertexArray(struct Vertex* vertex_array, __u32 num_vertices){


    __u32 i;

    printf("| %-15s | %-15s | %-15s | %-15s | \n", "Node", "out_degree", "in_degree", "visited");

    for(i =0; i < num_vertices; i++){

        if((vertex_array[i].out_degree > 0) || (vertex_array[i].in_degree > 0))
        printf("| %-15u | %-15u | %-15u | %-15u | \n",i,  vertex_array[i].out_degree, vertex_array[i].in_degree, vertex_array[i].visited);
    
    }

}

void freeVertexArray(struct Vertex* vertices){

	free(vertices);

}

