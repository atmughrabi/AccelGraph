#ifndef PAGERANK_H
#define PAGERANK_H

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

#define Damp 0.85f

void pageRankPullGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);
void pageRankPushGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);
void pageRankPullPushGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);

void pageRankPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankPullPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

void pageRankPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
void pageRankPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
void pageRankPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);

void pageRankPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
void pageRankPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
void pageRankPullPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);

#endif