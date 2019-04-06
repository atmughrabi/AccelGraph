#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "arrayQueue.h"
#include "bitmap.h"
#include "pageRank.h"

#include "fixedPoint.h"
#include "quantization.h"

#include "reorder.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


// ********************************************************************************************
// ***************          Auxilary functions                                   **************
// ********************************************************************************************

void addAtomicFloat(float *num, float value){

  float newV, oldV;
  __u32* lnewV;
  __u32* loldV;

  do {
    oldV = *num;  
    newV = oldV+value;
    loldV = (__u32*)&oldV; 
    lnewV = (__u32*)&newV;
    } while(!__sync_bool_compare_and_swap((__u32*)num, *(loldV), *(lnewV))); 

}


void addAtomicDouble(double *num, double value){

  double newV, oldV;
  __u64* lnewV;
  __u64* loldV;

  do {
    oldV = *num;  
    newV = oldV+value;
    loldV = (__u64*)&oldV; 
    lnewV = (__u64*)&newV;
    } while(!__sync_bool_compare_and_swap((__u64*)num, *(loldV), *(lnewV))); 

}


void swapWorkLists (__u8** workList1, __u8** workList2){

  
  __u8* workList_temp = *workList1;
  *workList1 = *workList2;
  *workList2 = workList_temp;

}

 void resetWorkList(__u8* workList, __u32 size){

  __u32 i;

  #pragma omp parallel for 
  for(i=0; i< size ;i++){
    workList[i] =0;
    
  }


 }

 void setWorkList(__u8* workList,  __u32 size){

  __u32 i;

  #pragma omp parallel for 
  for(i=0; i< size ;i++){
    workList[i] =1;
    
  }


 }

void setAtomic(__u64 *num, __u64 value){

  
    __u64 newV, oldV;

  do {oldV = *num;  newV = value;}
  while(!__sync_bool_compare_and_swap(num, oldV, newV)); 

}

 void addAtomicFixedPoint(__u64 *num, __u64 value){

  __u64 newV, oldV;

  do {oldV = *num;  newV = oldV+value;}
  while(!__sync_bool_compare_and_swap(num, oldV, newV)); 

}

void pageRankPrint(float *pageRankArray , __u32 num_vertices){
  __u32 v;
  for(v = 0; v < num_vertices; v++){
    printf("Rank[%d]=%f \n",v,pageRankArray[v]);
  }
}

// ********************************************************************************************
// ***************					GRID DataStructure							 **************
// ********************************************************************************************


// function STREAMVERTICES(Fv,F)
//  Sum = 0
//    for each vertex do
//      if F(vertex) then
//        Sum += Fv(edge)
//      end if
//    end for
//  return Sum
// end function

// function STREAMEDGES(Fe,F)
//  Sum = 0
//    for each active block do >> block with active edges
//      for each edge ∈ block do
//        if F(edge.source) then
//          Sum += Fe(edge)
//        end if
//      end for
//    end for
//  return Sum
// end function
//we assume that the edges are not sorted in each partition

void pageRankGraphGrid(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphGrid* graph){

	switch (pushpull)
      { 
        case 0: // push
        	  pageRankPullRowGraphGrid(epsilon, iterations, graph);
        break;
        case 1: // pull
            pageRankPushColumnGraphGrid(epsilon, iterations, graph);
        break;
        case 2: // pull
            pageRankPullRowFixedPointGraphGrid(epsilon, iterations, graph);
        break;
        case 3: // push
            pageRankPushColumnFixedPointGraphGrid(epsilon, iterations, graph);
        break;        
        default:// push
           	pageRankPullRowGraphGrid(epsilon, iterations, graph);
        break;          
      }

}


float* pageRankPullRowGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph){

 __u32 iter;
  __u32 v;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  __u32 totalPartitions  = graph->grid->num_partitions;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Row (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->grid->out_degree[v])
        riDividedOnDiClause[v] = pageRanks[v]/graph->grid->out_degree[v];
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);
   
      __u32 i;
      #pragma omp parallel for private(i) 
      for (i = 0; i < totalPartitions; ++i){ // iterate over partitions rowwise
        __u32 j;
        // #pragma omp parallel for private(j) 
        for (j = 0; j < totalPartitions; ++j){
            __u32 k;
            __u32 src;
            __u32 dest;
            struct Partition* partition = &graph->grid->partitions[(i*totalPartitions)+j];
            for (k = 0; k < partition->num_edges; ++k){
                src  = partition->edgeList->edges_array[k].src;
                dest = partition->edgeList->edges_array[k].dest;

                // #pragma omp atomic update
                // __sync_fetch_and_add(&pageRanksNext[dest],riDividedOnDiClause[src]);
                // addAtomicFloat(float *num, float value)

                 #pragma omp atomic update
                  pageRanksNext[dest] +=  riDividedOnDiClause[src];
          }
        }
      }


    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);
  
   return pageRanks;

}



float* pageRankPullRowFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph){

 __u32 iter;
  __u32 v;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  __u32 totalPartitions  = graph->grid->num_partitions;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Row FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");


  Start(timer);
  
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->grid->out_degree[v])
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->grid->out_degree[v]);
      else
        riDividedOnDiClause[v] = 0;
    }
 
    // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);
   
      __u32 i;
      #pragma omp parallel for private(i) 
      for (i = 0; i < totalPartitions; ++i){ // iterate over partitions rowwise
        __u32 j;
        for (j = 0; j < totalPartitions; ++j){
            __u32 k;
            __u32 src;
            __u32 dest;
            struct Partition* partition = &graph->grid->partitions[(i*totalPartitions)+j];
            for (k = 0; k < partition->num_edges; ++k){
                src  = partition->edgeList->edges_array[k].src;
                dest = partition->edgeList->edges_array[k].dest;

                #pragma omp atomic update
                pageRanksNext[dest] +=  riDividedOnDiClause[src];
          }
        }
      }


    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);
  
   return pageRanks;

}



/******************************************************************/



float* pageRankPushColumnGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph){

  __u32 iter;
  __u32 v;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  __u32 totalPartitions  = graph->grid->num_partitions;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push-Col (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->grid->out_degree[v])
        riDividedOnDiClause[v] = pageRanks[v]/graph->grid->out_degree[v];
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);
   
      __u32 j;
      #pragma omp parallel for private(j) 
      for (j = 0; j < totalPartitions; ++j){ // iterate over partitions columnwise
        __u32 i;
       
        for (i = 0; i < totalPartitions; ++i){
            __u32 k;
            __u32 src;
            __u32 dest;
            struct Partition* partition = &graph->grid->partitions[(i*totalPartitions)+j];
            for (k = 0; k < partition->num_edges; ++k){
                src  = partition->edgeList->edges_array[k].src;
                dest = partition->edgeList->edges_array[k].dest;

                #pragma omp atomic update
                  pageRanksNext[dest] +=  riDividedOnDiClause[src];

                // addAtomicFloat(&pageRanksNext[dest] , riDividedOnDiClause[src]);
          }
        }
      }


    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;
}



float* pageRankPushColumnFixedPointGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph){

  __u32 iter;
  __u32 v;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  __u32 totalPartitions  = graph->grid->num_partitions;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push-Col FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->grid->out_degree[v])
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->grid->out_degree[v]);
      else
        riDividedOnDiClause[v] = 0;
    }
 
    // pageRankStreamEdgesGraphGridRowWise(graph, riDividedOnDiClause, pageRanksNext);
   
      __u32 j;
       #pragma omp parallel for private(j) 
      for (j = 0; j < totalPartitions; ++j){ // iterate over partitions columnwise
        __u32 i;
        for (i = 0; i < totalPartitions; ++i){
            __u32 k;
            __u32 src;
            __u32 dest;
            struct Partition* partition = &graph->grid->partitions[(i*totalPartitions)+j];
            for (k = 0; k < partition->num_edges; ++k){
                src  = partition->edgeList->edges_array[k].src;
                dest = partition->edgeList->edges_array[k].dest;

                #pragma omp atomic update
                  pageRanksNext[dest] +=  riDividedOnDiClause[src];

                // addAtomicFloat(&pageRanksNext[dest] , riDividedOnDiClause[src]);
          }
        }
      }


    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;

}




// ********************************************************************************************
// ***************					CSR DataStructure				                      			 **************
// ********************************************************************************************


void pageRankGraphCSR(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph){
       
    switch (pushpull)
      { 
        
        case 0: // pull
          	pageRankPullGraphCSR(epsilon, iterations, graph);
        break;
        case 1: // push
            pageRankPushGraphCSR(epsilon, iterations, graph);
        break;
       
        case 2: // pull
            pageRankPullFixedPointGraphCSR(epsilon, iterations, graph);
        break;
        case 3: // push
            pageRankPushFixedPointGraphCSR(epsilon, iterations, graph);
        break;

        case 4: // pull
            pageRankPullQuantizationGraphCSR(epsilon, iterations, graph);
        break;
        case 5: // push
            pageRankPushQuantizationGraphCSR(epsilon, iterations, graph);
        break;

        case 6: // pull
            pageRankDataDrivenPullGraphCSR(epsilon, iterations, graph);
        break;
        case 7: // push
            pageRankDataDrivenPushGraphCSR(epsilon, iterations, graph);
        break;
        case 8: // pullpush
            pageRankDataDrivenPullPushGraphCSR(epsilon, iterations, graph);
        break;

        // case 7: // push
        //     pageRankDataDrivenPullFixedPointGraphCSR(epsilon, iterations, graph);
        // break;
        // case 8: // pull
        //     pageRankDataDrivenPushFixedPointGraphCSR(epsilon, iterations, graph);
        // break;
        
        default:// pull
           	pageRankPullGraphCSR(epsilon, iterations, graph);
        break;          
      }

}

// topoligy driven approach
float* pageRankPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 edge_idx;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Vertex* vertices = NULL;
  __u32* sorted_edges_array = NULL;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edge_array;
  #else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edge_array;
  #endif

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,edge_idx) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      float nodeIncomingPR = 0.0f;
      degree = vertices[v].out_degree;
      edge_idx = vertices[v].edges_idx;
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
      }
      pageRanksNext[v] = nodeIncomingPR;
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);
	
   return pageRanks;
}
float* pageRankPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){
 

	__u32 iter;
  __u32 i;
  __u32 v;
 
  // double error = 0;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));

    #endif


    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i=0; i<graph->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;
    #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
        riDividedOnDiClause[v] = 0;
      
    }
    
    #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){

      __u32 degree = graph->vertices[v].out_degree;
      __u32 edge_idx = graph->vertices[v].edges_idx;
      // __u32 tid = omp_get_thread_num();
      __u32 j;

      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
       __u32 u = graph->sorted_edge_array[j];
      
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic update
         pageRanksNext[u] += riDividedOnDiClause[v];

        // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
          // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

        // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
      }
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){

      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    Stop(timer_inner);
    
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");
  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;
}


// topoligy driven approach
float* pageRankPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

 __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 edge_idx;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);

  // __u64 base_pr_fp = FloatToFixed64(base_pr);
  // __u64 epsilon_fp = DoubleToFixed64(epsilon);
  // __u64 num_vertices_fp = UInt32ToFixed64();

  struct Vertex* vertices = NULL;
  __u32* sorted_edges_array = NULL;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edge_array;
  #else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edge_array;
  #endif

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* outDegreesFP = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* pageRanksFP = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* outDegreesFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* pageRanksFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
     pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
      else
        riDividedOnDiClause[v] = 0;
    }

    // Stop(timer_inner);
    // printf("|A %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));

    //  Start(timer_inner);
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,edge_idx) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      degree = vertices[v].out_degree;
      edge_idx = vertices[v].edges_idx;
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        pageRanksNext[v] += riDividedOnDiClause[u];
      }

    }
    // Stop(timer_inner);
    // printf("|B %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));

    // Start(timer_inner);
    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      // pageRanksFP[v] = FloatToFixed(nextPageRank);
      pageRanksNext[v] = 0;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    // Stop(timer_inner);
    // printf("|C %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(riDividedOnDiClause);

   return pageRanks;

}

float* pageRankPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 i;
  __u32 v;
 
  // double error = 0;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  // __u64 base_prFP = DoubleToFixed(base_pr);
  // __u64 DampFP = DoubleToFixed(Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));

    #endif


    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i=0; i<graph->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        // __u32* pageRanksFP = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        // __u32* pageRanksFP = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    // pageRanksFP[v]=base_prFP;
    pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;
    #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree){
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
         // riDividedOnDiClause[v] = DIVFixed64V1(pageRanksFP[v],UInt64ToFixed(graph->vertices[v].out_degree));
       }
      else
        riDividedOnDiClause[v] = 0;
      
    }
    // Stop(timer_inner);
    // printf("|A%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    // Start(timer_inner);
    #pragma omp parallel for default(none) schedule(dynamic, 1024) private(v) shared(graph,pageRanksNext,riDividedOnDiClause)
    for(v = 0; v < graph->num_vertices; v++){



      __u32 degree = graph->vertices[v].out_degree;
      __u32 edge_idx = graph->vertices[v].edges_idx;
      // __u32 tid = omp_get_thread_num();
      __u32 j;

      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
       __u32 u = graph->sorted_edge_array[j];
      
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic update
         pageRanksNext[u] += riDividedOnDiClause[v];

        // addAtomicFixedPoint(&pageRanksNext[u] , riDividedOnDiClause[v]);
      }
    }
    // Stop(timer_inner);
    // printf("|B%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    // Start(timer_inner);
    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      // pageRanksFP[v] = FloatToFixed(nextPageRank);
      pageRanksNext[v] = 0;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;
}

// topoligy driven approach
float* pageRankPullQuantizationGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

 __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 edge_idx;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);

  // __u64 base_pr_fp = FloatToFixed64(base_pr);
  // __u64 epsilon_fp = DoubleToFixed64(epsilon);
  // __u64 num_vertices_fp = UInt32ToFixed64();

  struct Vertex* vertices = NULL;
  __u32* sorted_edges_array = NULL;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

  #if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edge_array;
  #else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edge_array;
  #endif

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* outDegreesFP = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* pageRanksFP = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* outDegreesFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        // __u64* pageRanksFP = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull Quant (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
     pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
      else
        riDividedOnDiClause[v] = 0;
    }

    // Stop(timer_inner);
    // printf("|A %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    //  Start(timer_inner);
    
  // FILE *fptr;
  // fptr = fopen("./trace.re.out","w");
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,edge_idx) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      degree = vertices[v].out_degree;
      // fprintf(fptr,"r %016x\n", &(vertices[v].out_degree));
      edge_idx = vertices[v].edges_idx;
      // fprintf(fptr,"r %016x\n", &(vertices[v].edges_idx));
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        // fprintf(fptr,"r %016x\n", &(sorted_edges_array[j]));
        // fprintf(fptr,"r %016x\n", &(riDividedOnDiClause[u]));
        // fprintf(fptr,"r %016x\n", &(pageRanksNext[v]));
        // fprintf(fptr,"w %016x\n", &(pageRanksNext[v]));
        pageRanksNext[v] += riDividedOnDiClause[u];
      }

    }

    // fclose(fptr);
    // Stop(timer_inner);
    // printf("|B %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    // Start(timer_inner);
    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      // pageRanksFP[v] = FloatToFixed(nextPageRank);
      pageRanksNext[v] = 0;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    // Stop(timer_inner);
    // printf("|C %-9u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(riDividedOnDiClause);

   return pageRanks;

}

float* pageRankPushQuantizationGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 i;
  __u32 v;
 
  // double error = 0;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  // __u64 base_prFP = DoubleToFixed(base_pr);
  // __u64 DampFP = DoubleToFixed(Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));

    #endif


    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i=0; i<graph->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        // __u32* pageRanksFP = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        // __u32* pageRanksFP = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push Quant (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    // pageRanksFP[v]=base_prFP;
    pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;
    #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree){
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
         // riDividedOnDiClause[v] = DIVFixed64V1(pageRanksFP[v],UInt64ToFixed(graph->vertices[v].out_degree));
       }
      else
        riDividedOnDiClause[v] = 0;
      
    }
    // Stop(timer_inner);
    // printf("|A%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    // Start(timer_inner);
    #pragma omp parallel for default(none) schedule(dynamic, 1024) private(v) shared(graph,pageRanksNext,riDividedOnDiClause)
    for(v = 0; v < graph->num_vertices; v++){



      __u32 degree = graph->vertices[v].out_degree;
      __u32 edge_idx = graph->vertices[v].edges_idx;
      // __u32 tid = omp_get_thread_num();
      __u32 j;

      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
       __u32 u = graph->sorted_edge_array[j];
      
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic update
         pageRanksNext[u] += riDividedOnDiClause[v];

        // addAtomicFixedPoint(&pageRanksNext[u] , riDividedOnDiClause[v]);
      }
    }
    // Stop(timer_inner);
    // printf("|B%-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    // Start(timer_inner);
    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      // pageRanksFP[v] = FloatToFixed(nextPageRank);
      pageRanksNext[v] = 0;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;
}

float* pageRankDataDrivenPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  
  
  __u32 iter;
  __u32 i;
  __u32 v;
 
  
 
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Vertex* vertices = NULL;
  __u32* sorted_edges_array = NULL;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;

   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(sizeof(__u8));
        workListNext  = (__u8*) my_malloc(sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);

 #if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edge_array;
  #else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edge_array;
  #endif

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);
  #pragma omp parallel for reduction(+:activeVertices)
  for(i = 0; i < graph->num_vertices; i++){
    pageRanks[i] = base_pr;
    workListNext[i]=1;
    activeVertices++;
  }

  swapWorkLists(&workListNext, &workListCurr);
  resetWorkList(workListNext, graph->num_vertices);
  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
      riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
      riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for default(none) shared(epsilon,pageRanks,riDividedOnDiClause,sorted_edges_array,vertices,workListCurr,workListNext,base_pr,graph) private(v) reduction(+:activeVertices,error_total) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){
        __u32 edge_idx;
        __u32 degree;
        __u32 j;
        __u32 u;
        double error = 0;
        float nodeIncomingPR = 0;
        degree = vertices[v].out_degree; // when directed we use inverse graph out degree means in degree
        edge_idx = vertices[v].edges_idx;
        for(j = edge_idx ; j < (edge_idx + degree) ; j++){
          u = sorted_edges_array[j];
          nodeIncomingPR += riDividedOnDiClause[u]; // sum (PRi/outDegree(i))
        }
        float oldPageRank =  pageRanks[v];
        float newPageRank =  base_pr + (Damp * nodeIncomingPR);
        error = fabs(newPageRank - oldPageRank);
        error_total+= error/graph->num_vertices;
        if(error >= epsilon){
          pageRanks[v] = newPageRank;
          degree = graph->vertices[v].out_degree;
          edge_idx = graph->vertices[v].edges_idx;
          for(j = edge_idx ; j < (edge_idx + degree) ; j++){
            u = graph->sorted_edge_array[j];
          
            #pragma omp atomic write
              workListNext[u] = 1;
            // __u8 old_val = workListNext[u];
            // if(!old_val){
            //    __sync_bool_compare_and_swap(&workListNext[u], 0, 1);
            // }
          }
          activeVertices++;
        }
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(riDividedOnDiClause);

   return pageRanks;
}
float* pageRankDataDrivenPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 v;
  __u32 edge_idx;
  __u32 degree;
  __u32 j;
  __u32 u;
  
 
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Vertex* vertices = NULL;
  __u32* sorted_edges_array = NULL;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;

  #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
        workListNext  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);

 #if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edge_array;
  #else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edge_array;
  #endif

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_malloc(graph->num_vertices*sizeof(float));

  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);


  #pragma omp parallel for private(edge_idx,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    aResiduals[v] = 0.0;
    workListCurr[v]=1;
    workListNext[v]=0;
    activeVertices++;
    degree = vertices[v].out_degree; // when directed we use inverse graph out degree means in degree
    edge_idx = vertices[v].edges_idx;
    for(j = edge_idx ; j < (edge_idx + degree) ; j++){
      u = sorted_edges_array[j];
      if(graph->vertices[u].out_degree)
        aResiduals[v] += 1.0f/graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
    }
    aResiduals[v] = (1.0f - Damp)*Damp*aResiduals[v];
  }

  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for default(none) private(edge_idx,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){
        float oldPageRank =  pageRanks[v];
        float newPageRank =  aResiduals[v]+pageRanks[v];
        error_total+= fabs(newPageRank/graph->num_vertices - oldPageRank/graph->num_vertices);

        // #pragma omp atomic write
        pageRanks[v] = newPageRank;
        
        degree = graph->vertices[v].out_degree;
        float delta = Damp*(aResiduals[v]/degree);
        edge_idx = graph->vertices[v].edges_idx;

        for(j = edge_idx ; j < (edge_idx + degree) ; j++){
          u = graph->sorted_edge_array[j];
          float prevResidual = 0.0f;

          prevResidual = aResiduals[u];

          #pragma omp atomic update
          aResiduals[u] += delta;

          if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon)){
            activeVertices++;
            if(!workListNext[u]){

              // #pragma omp atomic write
              workListNext[u] = 1;

            }
          }
        }
        aResiduals[v] = 0.0f;
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(aResiduals);
  free(riDividedOnDiClause);

   return pageRanks;
}


float* pageRankDataDrivenPullPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

   __u32 iter;
  __u32 v;
  __u32 edge_idx;
  __u32 degree;
  __u32 j;
  __u32 u;
  
 
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Vertex* vertices = NULL;
  __u32* sorted_edges_array = NULL;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;

   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
        workListNext  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);

 #if DIRECTED
    vertices = graph->inverse_vertices;
    sorted_edges_array = graph->inverse_sorted_edge_array;
  #else
    vertices = graph->vertices;
    sorted_edges_array = graph->sorted_edge_array;
  #endif

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_malloc(graph->num_vertices*sizeof(float));

  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);

 
  #pragma omp parallel for private(edge_idx,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    aResiduals[v] = 0.0f;
    workListCurr[v]=1;
    workListNext[v]=0;
    activeVertices++;
    degree = vertices[v].out_degree; // when directed we use inverse graph out degree means in degree
    edge_idx = vertices[v].edges_idx;
    for(j = edge_idx ; j < (edge_idx + degree) ; j++){
      u = sorted_edges_array[j];
      if(graph->vertices[u].out_degree)
        aResiduals[v] += 1.0f/graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
    }
    aResiduals[v] = (1.0f - Damp)*Damp*aResiduals[v];
  }

  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for default(none) private(edge_idx,degree,v,j,u) shared(vertices,sorted_edges_array,epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){

        float nodeIncomingPR = 0.0f;
        degree = vertices[v].out_degree;
        edge_idx = vertices[v].edges_idx;
        for(j = edge_idx ; j < (edge_idx + degree) ; j++){
          u = sorted_edges_array[j];
          nodeIncomingPR += pageRanks[u]/graph->vertices[u].out_degree;
        }

        float newPageRank = base_pr + (Damp * nodeIncomingPR);
        float oldPageRank =  pageRanks[v];
        // float newPageRank =  aResiduals[v]+pageRanks[v];
        error_total+= fabs(newPageRank/graph->num_vertices - oldPageRank/graph->num_vertices);

        #pragma omp atomic write
        pageRanks[v] = newPageRank;

        degree = graph->vertices[v].out_degree;
        float delta = Damp*(aResiduals[v]/degree);
        edge_idx = graph->vertices[v].edges_idx;
        for(j = edge_idx ; j < (edge_idx + degree) ; j++){
          u = graph->sorted_edge_array[j];
          float prevResidual = 0.0f;

          prevResidual = aResiduals[u];

          #pragma omp atomic update
            aResiduals[u] += delta;

          if ((fabs(prevResidual+delta) >= epsilon) && (prevResidual <= epsilon)){
            activeVertices++;
            if(!workListNext[u]){
              workListNext[u] = 1;
            }
          }
        }
        aResiduals[v] = 0.0f;
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(aResiduals);
  free(riDividedOnDiClause);

   return pageRanks;

}


// float* pageRankDataDrivenPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


// }

// float* pageRankDataDrivenPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


// }

// float* pageRankDataDrivenPullPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


// }



// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************


void pageRankGraphAdjArrayList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList* graph){

	switch (pushpull)
      { 
       
        case 0: // pull
            pageRankPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 1: // push
            pageRankPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 2: // pull
            pageRankPullFixedPointGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 3: // push
            pageRankPushFixedPointGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 4: // pull
            pageRankDataDrivenPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 5: // push
            pageRankDataDrivenPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 6: // pullpush
            pageRankDataDrivenPullPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
        default:// push
           	pageRankPullGraphAdjArrayList(epsilon, iterations, graph);
        break;          
      }

}

float* pageRankPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){

  __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 activeVertices = 0;
  double error_total = 0;
  struct Edge* Nodes;

  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      float nodeIncomingPR = 0.0f;

      #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
      #else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
      #endif

      for(j = 0 ; j < (degree) ; j++){
        u = Nodes[j].dest;
        nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
      }

      pageRanksNext[v] = nodeIncomingPR;
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;
}
float* pageRankPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){

  __u32 iter;
  __u32 i;
  __u32 v;
 
  // double error = 0;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  struct Edge* Nodes;

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));

    #endif


    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i=0; i<graph->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;
    #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
    for(v = 0; v < graph->num_vertices; v++){


      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
        riDividedOnDiClause[v] = 0.0f;
      
    }
    
    #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){

        Nodes = graph->vertices[v].outNodes;
       __u32 degree = graph->vertices[v].out_degree;
      // __u32 tid = omp_get_thread_num();
      __u32 j;

      for(j = 0 ; j < (degree) ; j++){
       __u32 u = Nodes[j].dest;
      
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic update
         pageRanksNext[u] += riDividedOnDiClause[v];

        // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
          // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

        // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
      }
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){



      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    Stop(timer_inner);
    
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");
  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;

}
float* pageRankPullFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){

   __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 activeVertices = 0;
  double error_total = 0;
  struct Edge* Nodes;

  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      float nodeIncomingPR = 0.0f;

      #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
      #else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
      #endif

      for(j = 0 ; j < (degree) ; j++){
        u = Nodes[j].dest;
        nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
      }

      pageRanksNext[v] = nodeIncomingPR;
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;
}
float* pageRankPushFixedPointGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){

   __u32 iter;
  __u32 i;
  __u32 v;
 
  // double error = 0;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  struct Edge* Nodes;

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));

    #endif


    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i=0; i<graph->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;
    #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
    for(v = 0; v < graph->num_vertices; v++){


      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
      else
        riDividedOnDiClause[v] = 0;
      
    }
    
    #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){

        Nodes = graph->vertices[v].outNodes;
       __u32 degree = graph->vertices[v].out_degree;
      // __u32 tid = omp_get_thread_num();
      __u32 j;

      for(j = 0 ; j < (degree) ; j++){
       __u32 u = Nodes[j].dest;
      
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic update
         pageRanksNext[u] += riDividedOnDiClause[v];

        // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
          // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

        // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
      }
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){



      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp *Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    Stop(timer_inner);
    
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");
  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanksNext);
  free(riDividedOnDiClause);

  return pageRanks;
}
float* pageRankDataDrivenPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){

  __u32 iter;
  __u32 i;
  __u32 v;
 
  
 
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;
  struct Edge* Nodes;

   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(sizeof(__u8));
        workListNext  = (__u8*) my_malloc(sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);

 

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);
  #pragma omp parallel for reduction(+:activeVertices)
  for(i = 0; i < graph->num_vertices; i++){
    pageRanks[i] = base_pr;
    workListNext[i]=1;
    activeVertices++;
  }

  swapWorkLists(&workListNext, &workListCurr);
  resetWorkList(workListNext, graph->num_vertices);
  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
      riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
      riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for default(none) shared(epsilon,pageRanks,riDividedOnDiClause,workListCurr,workListNext,base_pr,graph) private(v,Nodes) reduction(+:activeVertices,error_total) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){
      
        __u32 degree;
        __u32 j;
        __u32 u;
        double error = 0;
        float nodeIncomingPR = 0;

        #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
          Nodes = graph->vertices[v].inNodes;
          degree = graph->vertices[v].in_degree;
        #else
          Nodes = graph->vertices[v].outNodes;
          degree = graph->vertices[v].out_degree;
        #endif

        for(j = 0 ; j < (degree) ; j++){
          u = Nodes[j].dest;
          nodeIncomingPR += riDividedOnDiClause[u]; // sum (PRi/outDegree(i))
        }
        float oldPageRank =  pageRanks[v];
        float newPageRank =  base_pr + (Damp * nodeIncomingPR);
        error = fabs(newPageRank - oldPageRank);
        error_total+= error/graph->num_vertices;
        if(error >= epsilon){
          pageRanks[v] = newPageRank;
          Nodes = graph->vertices[v].outNodes;
          degree = graph->vertices[v].out_degree;
          for(j = 0 ; j < (degree) ; j++){
            u = Nodes[j].dest;
          
            #pragma omp atomic write
              workListNext[u] = 1;
            // __u8 old_val = workListNext[u];
            // if(!old_val){
            //    __sync_bool_compare_and_swap(&workListNext[u], 0, 1);
            // }
          }
          activeVertices++;
        }
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(riDividedOnDiClause);

   return pageRanks;
}
float* pageRankDataDrivenPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){

   __u32 iter;
  __u32 v;
  __u32 degree;
  __u32 j;
  __u32 u;
  
 
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;
  struct Edge* Nodes;


   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
        workListNext  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_malloc(graph->num_vertices*sizeof(float));

  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);


  #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    aResiduals[v] = 0.0;
    workListCurr[v]=1;
    workListNext[v]=0;
    activeVertices++;


    #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
      Nodes = graph->vertices[v].inNodes;
      degree = graph->vertices[v].in_degree;
    #else
      Nodes = graph->vertices[v].outNodes;
      degree = graph->vertices[v].out_degree;
    #endif


    for(j = 0 ; j < (degree) ; j++){
      u = Nodes[j].dest;
      if(graph->vertices[u].out_degree)
        aResiduals[v] += 1.0f/graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
    }
    aResiduals[v] = (1.0f - Damp)*Damp*aResiduals[v];
  }

  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){
        float oldPageRank =  pageRanks[v];
        float newPageRank =  aResiduals[v]+pageRanks[v];
        error_total+= fabs(newPageRank/graph->num_vertices - oldPageRank/graph->num_vertices);

        // #pragma omp atomic write
        pageRanks[v] = newPageRank;
        
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
        float delta = Damp*(aResiduals[v]/degree);
        
      
        for(j = 0 ; j < (degree) ; j++){
          u = Nodes[j].dest;
          float prevResidual = 0.0f;

          prevResidual = aResiduals[u];

          #pragma omp atomic update
          aResiduals[u] += delta;

          if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon)){
            activeVertices++;
            if(!workListNext[u]){

              // #pragma omp atomic write
              workListNext[u] = 1;

            }
          }
        }
        aResiduals[v] = 0.0f;
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(aResiduals);
  free(riDividedOnDiClause);

   return pageRanks;
}
float* pageRankDataDrivenPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){

   __u32 iter;
  __u32 v;
  __u32 degree;
  __u32 j;
  __u32 u;
  struct Edge* Nodes;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;

   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
        workListNext  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);

 
  #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    aResiduals[v] = 0.0f;
    workListCurr[v]=1;
    workListNext[v]=0;
    activeVertices++;

    
    #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
      Nodes = graph->vertices[v].inNodes;
      degree = graph->vertices[v].in_degree;
    #else
      Nodes = graph->vertices[v].outNodes;
      degree = graph->vertices[v].out_degree;
    #endif

    for(j = 0 ; j < (degree) ; j++){
      u = Nodes[j].dest;
      if(graph->vertices[u].out_degree)
        aResiduals[v] += 1.0f/graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
    }
    aResiduals[v] = (1.0f - Damp)*Damp*aResiduals[v];
  }

  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){

        float nodeIncomingPR = 0.0f;

        #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
          Nodes = graph->vertices[v].inNodes;
          degree = graph->vertices[v].in_degree;
        #else
          Nodes = graph->vertices[v].outNodes;
          degree = graph->vertices[v].out_degree;
        #endif

        for(j = 0 ; j < (degree) ; j++){
          u = Nodes[j].dest;
          nodeIncomingPR += pageRanks[u]/graph->vertices[u].out_degree;
        }

        float newPageRank = base_pr + (Damp * nodeIncomingPR);
        float oldPageRank =  pageRanks[v];
        // float newPageRank =  aResiduals[v]+pageRanks[v];
        error_total+= fabs(newPageRank/graph->num_vertices - oldPageRank/graph->num_vertices);

        #pragma omp atomic write
        pageRanks[v] = newPageRank;

         Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
        float delta = Damp*(aResiduals[v]/degree);
    
       
    
        for(j = 0 ; j < (degree) ; j++){
         __u32 u = Nodes[j].dest;
          float prevResidual = 0.0f;

          prevResidual = aResiduals[u];

          #pragma omp atomic update
            aResiduals[u] += delta;

          if ((fabs(prevResidual+delta) >= epsilon) && (prevResidual <= epsilon)){
            activeVertices++;
            if(!workListNext[u]){
              workListNext[u] = 1;
            }
          }
        }
        aResiduals[v] = 0.0f;
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(aResiduals);
  free(riDividedOnDiClause);

   return pageRanks;

}


// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************


void pageRankGraphAdjLinkedList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList* graph){

	switch (pushpull)
      { 
        case 0: // pull
            pageRankPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 1: // push
            pageRankPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 2: // pull
            pageRankPullFixedPointGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 3: // push
            pageRankPushFixedPointGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 4: // pull
            pageRankDataDrivenPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 5: // push
            pageRankDataDrivenPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 6: // pullpush
            pageRankDataDrivenPullPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        default:// push
           	pageRankPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;          
      }

}

float* pageRankPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){

  __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 activeVertices = 0;
  double error_total = 0;
  struct AdjLinkedListNode* Nodes;

  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      float nodeIncomingPR = 0.0f;

      #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
      #else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
      #endif

      for(j = 0 ; j < (degree) ; j++){
        u = Nodes->dest;
        Nodes = Nodes->next;
        nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
      }

      pageRanksNext[v] = nodeIncomingPR;
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;

}
float* pageRankPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){

   __u32 iter;
  __u32 i;
  __u32 v;
 
  // double error = 0;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  struct AdjLinkedListNode* Nodes;

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));

    #endif


    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i=0; i<graph->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* pageRanksNext = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;
    #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
    for(v = 0; v < graph->num_vertices; v++){


      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
        riDividedOnDiClause[v] = 0.0f;
      
    }
    
    #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){

        Nodes = graph->vertices[v].outNodes;
       __u32 degree = graph->vertices[v].out_degree;
      // __u32 tid = omp_get_thread_num();
      __u32 j;

      for(j = 0 ; j < (degree) ; j++){
        __u32 u = Nodes->dest;
        Nodes = Nodes->next;
      
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic update
         pageRanksNext[u] += riDividedOnDiClause[v];

        // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
          // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

        // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
      }
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){



      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * pageRanksNext[v]);
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    Stop(timer_inner);
    
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");
  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;

}
float* pageRankPullFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){

   __u32 iter;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 activeVertices = 0;
  double error_total = 0;
  struct AdjLinkedListNode* Nodes;

  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
  #pragma omp parallel for default(none) private(v) shared(graph,pageRanksNext,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
     pageRanksNext[v] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    error_total = 0;
    activeVertices = 0;
    Start(timer_inner);
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
      else
        riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for reduction(+ : error_total,activeVertices) private(v,j,u,degree,Nodes) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      float nodeIncomingPR = 0.0f;

      #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
        Nodes = graph->vertices[v].inNodes;
        degree = graph->vertices[v].in_degree;
      #else
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
      #endif

      for(j = 0 ; j < (degree) ; j++){
        u = Nodes->dest;
        Nodes = Nodes->next;
        nodeIncomingPR += riDividedOnDiClause[u]; // pageRanks[v]/graph->vertices[v].out_degree;
      }

      pageRanksNext[v] = nodeIncomingPR;
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp * Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }


    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // printf(" -----------------------------------------------------\n");
  // printf("| %-10s | %-8lf | %-15s | %-9s | \n","PR Sum ",sum, iter, Seconds(timer));
  // printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanksNext);
  free(riDividedOnDiClause);

   return pageRanks;

}
float* pageRankPushFixedPointGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){

   __u32 iter;
  __u32 i;
  __u32 v;
 
  // double error = 0;
  __u32 activeVertices = 0;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  struct AdjLinkedListNode* Nodes;

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));

    #endif


    #pragma omp parallel for default(none) private(i) shared(graph,vertex_lock)
    for (i=0; i<graph->num_vertices; i++){
        omp_init_lock(&(vertex_lock[i]));
    }

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(base_pr,pageRanksNext,graph,pageRanks)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    pageRanksNext[v] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;
    #pragma omp parallel for private(v) shared(riDividedOnDiClause,pageRanks,graph)
    for(v = 0; v < graph->num_vertices; v++){


      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = DoubleToFixed64(pageRanks[v]/graph->vertices[v].out_degree);
      else
        riDividedOnDiClause[v] = 0;
      
    }
    
    #pragma omp parallel for default(none) private(v,Nodes) shared(graph,pageRanksNext,riDividedOnDiClause) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){

        Nodes = graph->vertices[v].outNodes;
       __u32 degree = graph->vertices[v].out_degree;
      // __u32 tid = omp_get_thread_num();
      __u32 j;

      for(j = 0 ; j < (degree) ; j++){
       __u32  u = Nodes->dest;
        Nodes = Nodes->next;
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic update
         pageRanksNext[u] += riDividedOnDiClause[v];

        // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
          // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

        // addAtomicFloat(&pageRanksNext[u] , riDividedOnDiClause[v]);
      }
    }

    #pragma omp parallel for private(v) shared(epsilon, pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
    for(v = 0; v < graph->num_vertices; v++){



      float prevPageRank =  pageRanks[v];
      float nextPageRank =  base_pr + (Damp *Fixed64ToDouble(pageRanksNext[v]));
      pageRanks[v] = nextPageRank;
      pageRanksNext[v] = 0.0f;
      double error = fabs( nextPageRank - prevPageRank);
      error_total += (error/graph->num_vertices);

      if(error >= epsilon){
        activeVertices++;
      }
    }

    Stop(timer_inner);
    
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


  double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");
  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanksNext);
  free(riDividedOnDiClause);

  return pageRanks;

}
float* pageRankDataDrivenPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){

   __u32 iter;
  __u32 i;
  __u32 v;
 
  
 
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;
  struct AdjLinkedListNode* Nodes;

   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(sizeof(__u8));
        workListNext  = (__u8*) my_malloc(sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);

 

  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);
  #pragma omp parallel for reduction(+:activeVertices)
  for(i = 0; i < graph->num_vertices; i++){
    pageRanks[i] = base_pr;
    workListNext[i]=1;
    activeVertices++;
  }

  swapWorkLists(&workListNext, &workListCurr);
  resetWorkList(workListNext, graph->num_vertices);
  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
      riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      else
      riDividedOnDiClause[v] = 0.0f;
    }
 
    #pragma omp parallel for default(none) shared(epsilon,pageRanks,riDividedOnDiClause,workListCurr,workListNext,base_pr,graph) private(v,Nodes) reduction(+:activeVertices,error_total) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){
      
        __u32 degree;
        __u32 j;
        __u32 u;
        double error = 0;
        float nodeIncomingPR = 0;

        #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
          Nodes = graph->vertices[v].inNodes;
          degree = graph->vertices[v].in_degree;
        #else
          Nodes = graph->vertices[v].outNodes;
          degree = graph->vertices[v].out_degree;
        #endif

        for(j = 0 ; j < (degree) ; j++){
          u = Nodes->dest;
          Nodes = Nodes->next;
          nodeIncomingPR += riDividedOnDiClause[u]; // sum (PRi/outDegree(i))
        }
        float oldPageRank =  pageRanks[v];
        float newPageRank =  base_pr + (Damp * nodeIncomingPR);
        error = fabs(newPageRank - oldPageRank);
        error_total+= error/graph->num_vertices;
        if(error >= epsilon){
          pageRanks[v] = newPageRank;
          Nodes = graph->vertices[v].outNodes;
          degree = graph->vertices[v].out_degree;
          for(j = 0 ; j < (degree) ; j++){
            u = Nodes->dest;
            Nodes = Nodes->next;
            #pragma omp atomic write
              workListNext[u] = 1;
            // __u8 old_val = workListNext[u];
            // if(!old_val){
            //    __sync_bool_compare_and_swap(&workListNext[u], 0, 1);
            // }
          }
          activeVertices++;
        }
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop

   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(riDividedOnDiClause);

   return pageRanks;

}
float* pageRankDataDrivenPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){

   __u32 iter;
  __u32 v;
  __u32 degree;
  __u32 j;
  __u32 u;
  
 
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;
  struct AdjLinkedListNode* Nodes;


   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
        workListNext  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_malloc(graph->num_vertices*sizeof(float));

  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);


  #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    aResiduals[v] = 0.0;
    workListCurr[v]=1;
    workListNext[v]=0;
    activeVertices++;


    #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
      Nodes = graph->vertices[v].inNodes;
      degree = graph->vertices[v].in_degree;
    #else
      Nodes = graph->vertices[v].outNodes;
      degree = graph->vertices[v].out_degree;
    #endif


    for(j = 0 ; j < (degree) ; j++){
      u = Nodes->dest;
      Nodes = Nodes->next;
      if(graph->vertices[u].out_degree)
        aResiduals[v] += 1.0f/graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
    }
    aResiduals[v] = (1.0f - Damp)*Damp*aResiduals[v];
  }

  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){
        float oldPageRank =  pageRanks[v];
        float newPageRank =  aResiduals[v]+pageRanks[v];
        error_total+= fabs(newPageRank/graph->num_vertices - oldPageRank/graph->num_vertices);

        // #pragma omp atomic write
        pageRanks[v] = newPageRank;
        
        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
        float delta = Damp*(aResiduals[v]/degree);
        
      
        for(j = 0 ; j < (degree) ; j++){
          u = Nodes->dest;
          Nodes = Nodes->next;
          float prevResidual = 0.0f;

          prevResidual = aResiduals[u];

          #pragma omp atomic update
          aResiduals[u] += delta;

          if ((fabs(prevResidual + delta) >= epsilon) && (prevResidual <= epsilon)){
            activeVertices++;
            if(!workListNext[u]){

              // #pragma omp atomic write
              workListNext[u] = 1;

            }
          }
        }
        aResiduals[v] = 0.0f;
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");


  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(aResiduals);
  free(riDividedOnDiClause);

   return pageRanks;

}

float* pageRankDataDrivenPullPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){

   __u32 iter;
  __u32 v;
  __u32 degree;
  __u32 j;
  __u32 u;
  struct AdjLinkedListNode* Nodes;
  double error_total = 0;
  // float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp);
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));
  __u8* workListCurr = NULL;
  __u8* workListNext = NULL;
  int activeVertices = 0;

   #if ALIGNED
        workListCurr = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
        workListNext = (__u8*) my_aligned_malloc(graph->num_vertices*sizeof(__u8));
  #else
        workListCurr  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
        workListNext  = (__u8*) my_malloc(graph->num_vertices*sizeof(__u8));
  #endif

  resetWorkList(workListNext, graph->num_vertices);
  resetWorkList(workListCurr, graph->num_vertices);


  #if ALIGNED
        float* pageRanks = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* aResiduals = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull-Push DD (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    
  Start(timer_inner);

 
  #pragma omp parallel for private(Nodes,degree,v,j,u) shared(workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:activeVertices)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
    aResiduals[v] = 0.0f;
    workListCurr[v]=1;
    workListNext[v]=0;
    activeVertices++;

    
    #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
      Nodes = graph->vertices[v].inNodes;
      degree = graph->vertices[v].in_degree;
    #else
      Nodes = graph->vertices[v].outNodes;
      degree = graph->vertices[v].out_degree;
    #endif

    for(j = 0 ; j < (degree) ; j++){
      u = Nodes->dest;
      Nodes = Nodes->next;
      if(graph->vertices[u].out_degree)
        aResiduals[v] += 1.0f/graph->vertices[u].out_degree; // sum (PRi/outDegree(i))
    }
    aResiduals[v] = (1.0f - Damp)*Damp*aResiduals[v];
  }

  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    #pragma omp parallel for default(none) private(Nodes,degree,v,j,u) shared(epsilon,graph,workListCurr,workListNext,aResiduals,pageRanks,base_pr) reduction(+:error_total,activeVertices) schedule(dynamic,1024)
    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){

        float nodeIncomingPR = 0.0f;

        #if DIRECTED // will look at the other neighbours if directed by using inverese edge list
          Nodes = graph->vertices[v].inNodes;
          degree = graph->vertices[v].in_degree;
        #else
          Nodes = graph->vertices[v].outNodes;
          degree = graph->vertices[v].out_degree;
        #endif

        for(j = 0 ; j < (degree) ; j++){
          u = Nodes->dest;
          Nodes = Nodes->next;
          nodeIncomingPR += pageRanks[u]/graph->vertices[u].out_degree;
        }

        float newPageRank = base_pr + (Damp * nodeIncomingPR);
        float oldPageRank =  pageRanks[v];
        // float newPageRank =  aResiduals[v]+pageRanks[v];
        error_total+= fabs(newPageRank/graph->num_vertices - oldPageRank/graph->num_vertices);

        #pragma omp atomic write
        pageRanks[v] = newPageRank;

        Nodes = graph->vertices[v].outNodes;
        degree = graph->vertices[v].out_degree;
        
        float delta = Damp*(aResiduals[v]/degree);
    
       
    
        for(j = 0 ; j < (degree) ; j++){
           u = Nodes->dest;
          Nodes = Nodes->next;
          float prevResidual = 0.0f;

          prevResidual = aResiduals[u];

          #pragma omp atomic update
            aResiduals[u] += delta;

          if ((fabs(prevResidual+delta) >= epsilon) && (prevResidual <= epsilon)){
            activeVertices++;
            if(!workListNext[u]){
              workListNext[u] = 1;
            }
          }
        }
        aResiduals[v] = 0.0f;
      }
    }

    // activeVertices = getNumOfSetBits(workListNext);
    swapWorkLists(&workListNext, &workListCurr);
    resetWorkList(workListNext, graph->num_vertices);

    Stop(timer_inner);
    printf("| %-10u | %-8u | %-15.13lf | %-9f | \n",iter, activeVertices,error_total, Seconds(timer_inner));
    if(activeVertices == 0)
      break;

  }// end iteration loop


   double sum = 0.0f;
  #pragma omp parallel for reduction(+:sum)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
    sum += pageRanks[v];
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iterations","PR Sum", "Error", "Time (S)");
  printf(" -----------------------------------------------------\n");
  printf("| %-10u | %-8lf | %-15.13lf | %-9f | \n",iter, sum, error_total, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(aResiduals);
  free(riDividedOnDiClause);


   return pageRanks;

}