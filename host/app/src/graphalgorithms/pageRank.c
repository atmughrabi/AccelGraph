#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "pageRank.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


// void pageRankPullGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);
// void pageRankPushGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);
// void pageRankPullPushGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);

void pageRankPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


	printf("%s\n","hello pageRank" );


}
// void pageRankPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
// void pageRankPullPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

// void pageRankPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
// void pageRankPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
// void pageRankPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);

// void pageRankPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
// void pageRankPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
// void pageRankPullPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);