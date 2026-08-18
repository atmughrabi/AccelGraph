#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "betweennessCentrality.h"

int main(void)
{
    mt19937state state;
    uint32_t degrees[4] = {1, 1, 1, 1};
    struct Vertex vertices = {0};
    struct GraphCSR graph = {0};
    uint32_t root;

    initializeMersenneState(&state, 27491095);
    vertices.out_degree = degrees;
    graph.num_vertices = 4;
    graph.avg_degree = 1;
    graph.vertices = &vertices;

    root = generateRandomRootBetweennessCentrality(&state, &graph);
    if(root >= graph.num_vertices)
        return EXIT_FAILURE;

    degrees[0] = 0;
    degrees[1] = 0;
    degrees[2] = 0;
    degrees[3] = 0;
    graph.avg_degree = 0;

    root = generateRandomRootBetweennessCentrality(&state, &graph);
    if(root >= graph.num_vertices)
        return EXIT_FAILURE;

    graph.num_vertices = 0;
    if(generateRandomRootBetweennessCentrality(&state, &graph) != UINT32_MAX)
        return EXIT_FAILURE;

    printf("PASS betweenness_root_selection\n");
    return EXIT_SUCCESS;
}
