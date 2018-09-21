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
void * generateGraphDataStructure(const char *fnameb, int datastructure);
void runGraphAlgorithms(void *graph, int datastructure,int algorithm, int root, int iterations);
void runBreadthFirstSearchAlgorithm(void *graph, int datastructure, int root, int iterations);

#endif


