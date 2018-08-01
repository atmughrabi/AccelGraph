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
            graph->vertices[vertex_id].edges_idx = 1;
        }
    }

return graph;

}

void freeVertexArray(struct Vertex* vertices){

	free(vertices);

}

