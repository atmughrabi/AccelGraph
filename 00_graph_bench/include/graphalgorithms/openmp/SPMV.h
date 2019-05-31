#ifndef SPMV_H
#define SPMV_H

#include <linux/types.h>

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


// ********************************************************************************************
// ***************                  Stats DataStructure                          **************
// ********************************************************************************************


struct SPMVStats
{
	
    __u32 iterations;
    __u32 num_vertices;
    float *vector;
    double time_total;
    double error_total;
};

struct SPMVStats *newSPMVStatsGraphCSR(struct GraphCSR *graph);
struct SPMVStats *newSPMVStatsGraphGrid(struct GraphGrid *graph);
struct SPMVStats *newSPMVStatsGraphAdjArrayList(struct GraphAdjArrayList *graph);
struct SPMVStats *newSPMVStatsGraphAdjLinkedList(struct GraphAdjLinkedList *graph);

void freeSPMVStats(struct SPMVStats *stats);

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphGrid(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphGrid *graph);
struct SPMVStats *SPMVPullRowGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);
struct SPMVStats *SPMVPushColumnGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);
struct SPMVStats *SPMVPullRowFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);
struct SPMVStats *SPMVPushColumnFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid *graph);

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphCSR(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphCSR *graph);
struct SPMVStats *SPMVPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
struct SPMVStats *SPMVPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);

struct SPMVStats *SPMVPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
struct SPMVStats *SPMVPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);

struct SPMVStats *SPMVDataDrivenPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);
struct SPMVStats *SPMVDataDrivenPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR *graph);

// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphAdjArrayList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList *graph);
struct SPMVStats *SPMVPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
struct SPMVStats *SPMVPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);

struct SPMVStats *SPMVPullFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
struct SPMVStats *SPMVPushFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);

struct SPMVStats *SPMVDataDrivenPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
struct SPMVStats *SPMVDataDrivenPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);
struct SPMVStats *SPMVDataDrivenPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList *graph);

// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************

struct SPMVStats *SPMVGraphAdjLinkedList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList *graph);
struct SPMVStats *SPMVPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);
struct SPMVStats *SPMVPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);

struct SPMVStats *SPMVPullFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);
struct SPMVStats *SPMVPushFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);

struct SPMVStats *SPMVDataDrivenPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);
struct SPMVStats *SPMVDataDrivenPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList *graph);

#endif