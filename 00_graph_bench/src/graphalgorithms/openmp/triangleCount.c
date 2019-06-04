#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "bitmap.h"
#include "triangleCount.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"



struct TCStats *newTCStatsGraphCSR(struct GraphCSR *graph)
{

    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;

    return stats;

}
struct TCStats *newTCStatsGraphGrid(struct GraphGrid *graph)
{
    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;

    return stats;
}
struct TCStats *newTCStatsGraphAdjArrayList(struct GraphAdjArrayList *graph)
{
    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;

    return stats;

}
struct TCStats *newTCStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

    struct TCStats *stats = (struct TCStats *) my_malloc(sizeof(struct TCStats));

    stats->counts = 0;
    stats->num_vertices = graph->num_vertices;
    stats->time_total = 0.0f;

    return stats;

}
void freeTCStats(struct TCStats *stats)
{

	if(stats){

		free(stats);
	}

}

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

struct TCStats *triangleCountGraphCSR(__u32 pushpull, struct GraphCSR *graph)
{

}
struct TCStats *triangleCountPullGraphCSR(struct GraphCSR *graph)
{
  

}
struct TCStats *triangleCountPushGraphCSR(struct GraphCSR *graph)
{

}

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

struct TCStats *triangleCountGraphGrid(__u32 pushpull, struct GraphGrid *graph)
{

}
struct TCStats *triangleCountRowGraphGrid(struct GraphGrid *graph)
{

}
struct TCStats *triangleCountColumnGraphGrid(struct GraphGrid *graph)
{

}

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

struct TCStats *triangleCountGraphAdjArrayList(__u32 pushpull, struct GraphAdjArrayList *graph)
{

}
struct TCStats *triangleCountPullGraphAdjArrayList(struct GraphAdjArrayList *graph)
{

}
struct TCStats *triangleCountPushGraphAdjArrayList(struct GraphAdjArrayList *graph)
{

}

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************

struct TCStats *triangleCountGraphAdjLinkedList(__u32 pushpull, struct GraphAdjLinkedList *graph)
{

}
struct TCStats *triangleCountPullGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

}
struct TCStats *triangleCountPushGraphAdjLinkedList(struct GraphAdjLinkedList *graph)
{

}