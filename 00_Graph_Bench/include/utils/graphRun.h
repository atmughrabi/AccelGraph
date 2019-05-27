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
struct Arguments
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

// Random root helper functions
__u32 generateRandomRootGraphCSR(struct GraphCSR *graph);
__u32 generateRandomRootGraphGrid(struct GraphGrid *graph);
__u32 generateRandomRootGraphAdjLinkedList(struct GraphAdjLinkedList *graph);
__u32 generateRandomRootGraphAdjArrayList(struct GraphAdjArrayList *graph);
__u32 generateRandomRootGeneral(void *graph, struct Arguments *arguments);

void freeGraphDataStructure(void *graph, __u32 datastructure);
void freeGraphStatsGeneral(void *stats, __u32 algorithm);

void writeSerializedGraphDataStructure(struct Arguments *arguments);
void readSerializeGraphDataStructure(struct Arguments *arguments);

void generateGraphPrintMessageWithtime(const char *msg, double time);
void *generateGraphDataStructure(struct Arguments *arguments);

void runGraphAlgorithms(void *graph, struct Arguments *arguments);

struct BFSStats *runBreadthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root, __u32 pushpull);
struct PageRankStats *runPageRankAlgorithm(void *graph, __u32 datastructure, double epsilon, __u32 iterations, __u32 pushpull);
struct DFSStats *runDepthFirstSearchAlgorithm(void *graph, __u32 datastructure, int root);
struct IncrementalAggregationStats *runIncrementalAggregationAlgorithm(void *graph, __u32 datastructure);
struct BellmanFordStats *runBellmanFordAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 pushpull);
struct SSSPStats *runSSSPAlgorithm(void *graph, __u32 datastructure, __u32 root, __u32 iterations, __u32 pushpull, __u32 delta);



#endif


