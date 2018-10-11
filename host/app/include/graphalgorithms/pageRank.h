#ifndef PAGERANK_H
#define PAGERANK_H

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

#define Damp 0.85f

// ********************************************************************************************
// ***************					Auxilary functions  	  					 **************
// ********************************************************************************************

void addAtomicFloat(float *num, float value);
void pageRankPrint(float *pageRankArray, __u32 num_vertices);
void pageRankCompare(float *pageRankArrayOp1,float *pageRankArrayOp2);

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

void pageRankGraphGrid(double epsilon,  __u32 trials, __u32 pushpull, struct GraphGrid* graph);
void pageRankPullGraphGrid(double epsilon,  __u32 trials, struct GraphGrid* graph);
void pageRankPushGraphGrid(double epsilon,  __u32 trials, struct GraphGrid* graph);
void pageRankPullPushGraphGrid(double epsilon,  __u32 trials, struct GraphGrid* graph);

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void pageRankGraphCSR(double epsilon,  __u32 trials, __u32 pushpull, struct GraphCSR* graph);
void pageRankPullGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph);
void pageRankPushGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph);
void pageRankPullPushGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph);

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

void pageRankGraphAdjArrayList(double epsilon,  __u32 trials, __u32 pushpull, struct GraphAdjArrayList* graph);
void pageRankPullGraphAdjArrayList(double epsilon,  __u32 trials, struct GraphAdjArrayList* graph);
void pageRankPushGraphAdjArrayList(double epsilon,  __u32 trials, struct GraphAdjArrayList* graph);
void pageRankPullPushGraphAdjArrayList(double epsilon,  __u32 trials, struct GraphAdjArrayList* graph);

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************


void pageRankGraphAdjLinkedList(double epsilon,  __u32 trials, __u32 pushpull, struct GraphAdjLinkedList* graph);
void pageRankPullGraphAdjLinkedList(double epsilon,  __u32 trials, struct GraphAdjLinkedList* graph);
void pageRankPushGraphAdjLinkedList(double epsilon,  __u32 trials, struct GraphAdjLinkedList* graph);
void pageRankPullPushGraphAdjLinkedList(double epsilon,  __u32 trials, struct GraphAdjLinkedList* graph);

#endif