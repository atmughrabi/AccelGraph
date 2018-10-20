#ifndef PAGERANK_H
#define PAGERANK_H

#include <linux/types.h>
#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

#define Damp 0.85f

struct PageRanks{

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
void pageRankCompare(float *pageRankArrayOp1,float *pageRankArrayOp2);
void swapWorkLists (__u8** workList1, __u8** workList2);
void resetWorkList(__u8* workList, __u32 size);
void setWorkList(__u8* workList,  __u32 size);

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

void pageRankGraphGrid(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphGrid* graph);
void pageRankPullGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);
void pageRankPushGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);

void pageRankPullFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);
void pageRankPushFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph);


// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

void pageRankGraphCSR(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph);
void pageRankPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

void pageRankPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

void pageRankDataDrivenPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankDataDrivenPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankDataDrivenPullPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

void pageRankDataDrivenPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankDataDrivenPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);
void pageRankDataDrivenPullPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph);

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

void pageRankGraphAdjArrayList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList* graph);
void pageRankPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
void pageRankPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);

void pageRankPullFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
void pageRankPushFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);

void pageRankDataDrivenPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
void pageRankDataDrivenPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);
void pageRankDataDrivenPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph);

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************

void pageRankGraphAdjLinkedList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList* graph);
void pageRankPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
void pageRankPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);

void pageRankPullFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
void pageRankPushFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);

void pageRankDataDrivenPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
void pageRankDataDrivenPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);
void pageRankDataDrivenPullPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph);

#endif