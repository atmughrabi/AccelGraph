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
void * generateGraphDataStructure(const char *fnameb, __u32 datastructure, __u32 sort);
void runGraphAlgorithms(void *graph, __u32 datastructure, __u32 algorithm, int root, __u32 iterations,double epsilon, __u32 trials, __u32 pushpull);
void runBreadthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 iterations);
void runPageRankAlgorithm(void *graph, __u32 datastructure, double epsilon, __u32 trials, __u32 iterations, __u32 pushpull);

#endif


