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
        struct Vertex* vertex_array = (struct Vertex*) my_aligned_alloc( num_vertices * sizeof(struct Vertex));

        __u32 i;

        for(i = 0; i < num_vertices; i++){

                vertex_array[i].edges_idx = NO_OUTGOING_EDGES;

        }

        return vertex_array;

}


void freeVertexArray(struct Vertex* vertices){

	free(vertices);

}

