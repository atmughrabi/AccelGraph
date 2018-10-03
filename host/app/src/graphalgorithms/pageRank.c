#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "pageRank.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************

void pageRankGraphGrid(double epsilon,  __u32 trials, __u32 pushpull, struct GraphGrid* graph){

	switch (pushpull)
      { 
        case 0: // push
        	pageRankPushGraphGrid(epsilon, trials, graph);
        break;
        case 1: // pull
          	pageRankPullGraphGrid(epsilon, trials, graph);
        break;
        case 2: // pushpull
          	pageRankPullPushGraphGrid(epsilon, trials, graph);
        break;  
        default:// push
           	pageRankPushGraphGrid(epsilon, trials, graph);
        break;          
      }

}
void pageRankPullGraphGrid(double epsilon,  __u32 trials, struct GraphGrid* graph){


}
void pageRankPushGraphGrid(double epsilon,  __u32 trials, struct GraphGrid* graph){


}
void pageRankPullPushGraphGrid(double epsilon,  __u32 trials, struct GraphGrid* graph){


}

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************


void pageRankGraphCSR(double epsilon,  __u32 trials, __u32 pushpull, struct GraphCSR* graph){
       
    switch (pushpull)
      { 
        case 0: // push
        	pageRankPushGraphCSR(epsilon, trials, graph);
        break;
        case 1: // pull
          	pageRankPullGraphCSR(epsilon, trials, graph);
        break;
        case 2: // pushpull
          	pageRankPullPushGraphCSR(epsilon, trials, graph);
        break;  
        default:// push
           	pageRankPushGraphCSR(epsilon, trials, graph);
        break;          
      }

}
void pageRankPullGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph){

	printf("pageRankPullGraphCSR\n");

}
void pageRankPushGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph){

	printf("pageRankPushGraphCSR\n");

}
void pageRankPullPushGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph){

	printf("pageRankPullPushGraphCSR\n");
	
}


// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************


void pageRankGraphAdjArrayList(double epsilon,  __u32 trials, __u32 pushpull, struct GraphAdjArrayList* graph){

	switch (pushpull)
      { 
        case 0: // push
        	pageRankPushGraphAdjArrayList(epsilon, trials, graph);
        break;
        case 1: // pull
          	pageRankPullGraphAdjArrayList(epsilon, trials, graph);
        break;
        case 2: // pushpull
          	pageRankPullPushGraphAdjArrayList(epsilon, trials, graph);
        break;  
        default:// push
           	pageRankPushGraphAdjArrayList(epsilon, trials, graph);
        break;          
      }

}
void pageRankPullGraphAdjArrayList(double epsilon,  __u32 trials, struct GraphAdjArrayList* graph){


}
void pageRankPushGraphAdjArrayList(double epsilon,  __u32 trials, struct GraphAdjArrayList* graph){


}
void pageRankPullPushGraphAdjArrayList(double epsilon,  __u32 trials, struct GraphAdjArrayList* graph){


}


// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************


void pageRankGraphAdjLinkedList(double epsilon,  __u32 trials, __u32 pushpull, struct GraphAdjLinkedList* graph){

	switch (pushpull)
      { 
        case 0: // push
        	pageRankPushGraphAdjLinkedList(epsilon, trials, graph);
        break;
        case 1: // pull
          	pageRankPullGraphAdjLinkedList(epsilon, trials, graph);
        break;
        case 2: // pushpull
          	pageRankPullPushGraphAdjLinkedList(epsilon, trials, graph);
        break;  
        default:// push
           	pageRankPushGraphAdjLinkedList(epsilon, trials, graph);
        break;          
      }

}
void pageRankPullGraphAdjLinkedList(double epsilon,  __u32 trials, struct GraphAdjLinkedList* graph){


}
void pageRankPushGraphAdjLinkedList(double epsilon,  __u32 trials, struct GraphAdjLinkedList* graph){


}
void pageRankPullPushGraphAdjLinkedList(double epsilon,  __u32 trials, struct GraphAdjLinkedList* graph){


}