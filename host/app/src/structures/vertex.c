#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// #include "adjlist.h"
#include "capienv.h"
// #include "countsort.h"
// #include "edgelist.h"

#include "vertex.h"


struct Vertex* newVertexArray(int num_vertices){

        struct Vertex* vertex_array = (struct Vertex*) aligned_alloc(CACHELINE_BYTES, num_vertices * sizeof(struct Vertex));

        int i;

        for(i = 0; i < num_vertices; i++){

                vertex_array[i].edges_idx = NO_OUTGOING_EDGES;

        }

        return vertex_array;

}

