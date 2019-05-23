#ifndef PAGERANK_H
#define PAGERANK_H

#include <linux/types.h>
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

#define Damp 0.85f

struct PageRanks
{

    __u32 vertex;
    float pageRank;

};

// ********************************************************************************************
// ***************					Auxiliary functions  	  					 **************
// ********************************************************************************************

void addAtomicFixedPoint(__u64 *num, __u64 value);
void addAtomicFloat(float *num, float value);
void addAtomicDouble(double *num, double value);
void setAtomic(__u64 *num, __u64 value);

void pageRankPrint(float *pageRankArray, __u32 num_vertices);
void pageRankCompare(float *pageRankArrayOp1, float *pageRankArrayOp2);
void swapWorkLists (__u8 **workList1, __u8 **workList2);
void resetWorkList(__u8 *workList, __u32 size);
void setWorkList(__u8 *workList,  __u32 size);

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

float *pageRankGraphGrid(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphGrid *graph);
float *pageRankPullRowGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);
float *pageRankPushColumnGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);
float *pageRankPullRowFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);
float *pageRankPushColumnFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

float *pageRankGraphCSR(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphCSR *graph);


float *pageRankPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
void pageRankPullGraphCSRKernel(float *riDividedOnDiClause, float *pageRanksNext, struct Vertex *vertices, __u32 *sorted_edges_array, __u32 num_vertices);

float *pageRankPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);

float *pageRankPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
float *pageRankPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);

float *pageRankPulCacheAnalysisGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
float *pageRankPushQuantizationGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);

float *pageRankDataDrivenPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
float *pageRankDataDrivenPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
float *pageRankDataDrivenPullPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);

// void pageRankDataDrivenPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
// void pageRankDataDrivenPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
// void pageRankDataDrivenPullPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

float *pageRankGraphAdjArrayList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList *graph);
float *pageRankPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
float *pageRankPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);

float *pageRankPullFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
float *pageRankPushFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);

float *pageRankDataDrivenPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
float *pageRankDataDrivenPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
float *pageRankDataDrivenPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************

float *pageRankGraphAdjLinkedList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList *graph);
float *pageRankPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);
float *pageRankPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);

float *pageRankPullFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);
float *pageRankPushFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);

float *pageRankDataDrivenPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);
float *pageRankDataDrivenPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);
float *pageRankDataDrivenPullPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);

#endif