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

/* Used by main to communicate with parse_opt. */
struct arguments
{
    int wflag;
    int xflag;
    int sflag;

    __u32 iterations;
    __u32 trials;
    double epsilon;
    int root;
    __u32 algorithm;
    __u32 datastructure;
    __u32 pushpull;
    __u32 sort;
    __u32 lmode;
    __u32 symmetric;
    __u32 weighted;
    __u32 delta;
    __u32 numThreads;
    char *fnameb;
    __u32 fnameb_format;
    __u32 convert_format;
};

void writeSerializedGraphDataStructure(struct arguments *arguments);
void readSerializeGraphDataStructure(struct arguments *arguments);
void generateGraphPrintMessageWithtime(const char *msg, double time);
void *generateGraphDataStructure(struct arguments *arguments);
void runGraphAlgorithms(void *graph, struct arguments *arguments);
void runBreadthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 trials);
void runPageRankAlgorithm(void *graph, __u32 datastructure, double epsilon, __u32 iterations, __u32 trials, __u32 pushpull);
void runDepthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 trials);
void runIncrementalAggregationAlgorithm(void *graph, __u32 datastructure, __u32 trials);
void runBellmanFordAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 trials, __u32 pushpull);
void runSSSPAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 trials, __u32 pushpull, __u32 delta);

#endif


