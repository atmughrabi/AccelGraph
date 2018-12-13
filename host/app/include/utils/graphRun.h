#ifndef GRAPHRUN_H
#define GRAPHRUN_H

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "graphCSR.h"
#include "graphAdjLinkedList.h"
#include "graphAdjArrayList.h"
#include "graphGrid.h"

#include "graphConfig.h"
#include "timer.h"
#include "BFS.h"

  
void generateGraphPrintMessageWithtime(const char * msg, double time);
void * generateGraphDataStructure(const char *fnameb, __u32 datastructure, __u32 sort, __u32 lmode, __u32 symmetric, __u32 weighted);
void runGraphAlgorithms(void *graph, __u32 datastructure, __u32 algorithm, int root, __u32 trials,double epsilon, __u32 iterations, __u32 pushpull,  __u32 delta);
void runBreadthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 trials);
void runPageRankAlgorithm(void *graph, __u32 datastructure, double epsilon, __u32 iterations, __u32 trials, __u32 pushpull);
void runDepthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 trials);
void runIncrementalAggregationAlgorithm(void *graph, __u32 datastructure, __u32 trials);
void runBellmanFordAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 trials, __u32 pushpull);
void runSSSPAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 trials, __u32 pushpull, __u32 delta);

#endif


