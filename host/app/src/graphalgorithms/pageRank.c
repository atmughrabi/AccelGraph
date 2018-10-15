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

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


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

void pageRankGraphGrid(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphGrid* graph){

	switch (pushpull)
      { 
        case 0: // push
        	pageRankPushGraphGrid(epsilon, iterations, graph);
        break;
        case 1: // pull
          	pageRankPullGraphGrid(epsilon, iterations, graph);
        break;
        case 2: // pushpull
          	pageRankPullPushGraphGrid(epsilon, iterations, graph);
        break;  
        default:// push
           	pageRankPushGraphGrid(epsilon, iterations, graph);
        break;          
      }

}
void pageRankPullGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph){


}
void pageRankPushGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph){


}
void pageRankPullPushGraphGrid(double epsilon,  __u32 iterations, struct GraphGrid* graph){


}

// ********************************************************************************************
// ***************					CSR DataStructure							 **************
// ********************************************************************************************


void pageRankGraphCSR(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphCSR* graph){
       
    switch (pushpull)
      { 
        case 0: // push
            pageRankPushGraphCSR(epsilon, iterations, graph);
        break;
        case 1: // pull
          	pageRankPullGraphCSR(epsilon, iterations, graph);
        break;
        case 2: // push
            pageRankPullFixedPointGraphCSR(epsilon, iterations, graph);
        break;
        case 3: // pull
            pageRankPushFixedPointGraphCSR(epsilon, iterations, graph);
        break;
        case 4: // push
            pageRankDataDrivenPullGraphCSR(epsilon, iterations, graph);
        break;
        case 5: // pull
            pageRankDataDrivenPushGraphCSR(epsilon, iterations, graph);
        break;
        case 6: // push
            pageRankDataDrivenPullFixedPointGraphCSR(epsilon, iterations, graph);
        break;
        case 7: // pull
            pageRankDataDrivenPushFixedPointGraphCSR(epsilon, iterations, graph);
        break;
        default:// push
           	pageRankPullGraphCSR(epsilon, iterations, graph);
        break;          
      }

}

// topoligy driven approach
void pageRankPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

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
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(graph->num_vertices*sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf(" -----------------------------------------------------\n");
    printf("| %-10s | %-8s | %-15s | %-9s | \n", "Iteration","Active", "Error", "Time (S)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for default(none) private(v) shared(graph,pageRanks,base_pr)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = base_pr;
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
      float nodeIncomingPR = 0;
      degree = vertices[v].out_degree;
      edge_idx = vertices[v].edges_idx;
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        nodeIncomingPR += riDividedOnDiClause[u];
      }

      float prevPageRank = pageRanks[v];
      float nextPageRank = base_pr + (Damp * nodeIncomingPR);

      pageRanks[v] = nextPageRank;
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

  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-15s | %-15u | %-15f | \n","total", iter+1, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanks);
  free(riDividedOnDiClause);
	

}
void pageRankPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

	__u32 iter;
  __u32 i;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 edge_idx;
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
    pageRanksNext[v] = 0.0f;
  }

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
    
    #pragma omp parallel for default(none) schedule(dynamic, 1024) private(v,j,u,degree,edge_idx) shared(graph,pageRanksNext,riDividedOnDiClause)
    for(v = 0; v < graph->num_vertices; v++){
      degree = graph->vertices[v].out_degree;
      edge_idx = graph->vertices[v].edges_idx;
      __u32 tid = omp_get_thread_num();
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = graph->sorted_edge_array[j];
        // u =  graph->sorted_edges_array[j].src;
        // omp_set_lock(&(vertex_lock[u]));
        //   pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic
          pageRanksNext[u] += riDividedOnDiClause[v];

          // printf("tid %u degree %u edge_idx %u v %u u %u \n",tid,degree,edge_idx,v,u );

        // addAtomicFloat(&pageRanks[u] , riDividedOnDiClause[v]);
      }
    }

    #pragma omp parallel for private(v) shared(pageRanks,pageRanksNext,base_pr) reduction(+ : error_total, activeVertices) 
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


  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-15s | %-15u | %-15f | \n","total", iter+1, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanks);
  free(riDividedOnDiClause);

}


// topoligy driven approach
void pageRankPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 i;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 edge_idx;


  double error = 0;
  float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp) / (float)graph->num_vertices;
 

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
        __u64* riDividedOnDiClause = (__u64*) my_aligned_malloc(graph->num_vertices*sizeof(__u64));
  #else
        float* pageRanks = (float*) my_malloc(graph->num_vertices*sizeof(float));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(graph->num_vertices*sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51.13lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Error", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for
  for(i = 0; i < graph->num_vertices; i++){
    pageRanks[i] = init_pr;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error = 0;
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
        riDividedOnDiClause[v] = DoubleToFixed(pageRanks[v]/graph->vertices[v].out_degree);
      else
        riDividedOnDiClause[v] = 0;
    }
 
    #pragma omp parallel for reduction(+ : error) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      __u64 nodeIncomingPR = 0;
      degree = vertices[v].out_degree;
      edge_idx = vertices[v].edges_idx;
      // #pragma omp parallel for reduction(+ : nodeIncomingPR) schedule(dynamic, 1024)
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        nodeIncomingPR += riDividedOnDiClause[u];
      }
     

      float prevPageRank = pageRanks[v];
      pageRanks[v] = base_pr + (Damp * FixedToFloat64(nodeIncomingPR));
      error += fabs( pageRanks[v] - prevPageRank);
    }


    Stop(timer_inner);
    printf("| %-15u | %-15.13lf | %-15f | \n",iter, error, Seconds(timer_inner));
    if(error < epsilon)
      break;

  }// end iteration loop
  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-15s | %-15u | %-15f | \n","total", iter+1, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);
  free(timer);
  free(timer_inner);
  free(pageRanks);
  free(riDividedOnDiClause);
  

}

void pageRankPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 i;
  __u32 j;
  __u32 v;
  __u32 u;
  __u32 degree;
  __u32 edge_idx;
  double error = 0;
  float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp) / (float)graph->num_vertices;
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
  struct Timer* timer_inner = (struct Timer*) malloc(sizeof(struct Timer));

    #if ALIGNED
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_aligned_malloc( graph->num_vertices * sizeof(omp_lock_t));
    #else
        omp_lock_t *vertex_lock  = (omp_lock_t*) my_malloc( graph->num_vertices *sizeof(omp_lock_t));
    #endif


    #pragma omp parallel for
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
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Error", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for
  for(i = 0; i < graph->num_vertices; i++){
    pageRanks[i] = init_pr;
    pageRanksNext[i] = 0;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error = 0;
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      if(graph->vertices[v].out_degree)
      riDividedOnDiClause[v] = DoubleToFixed(pageRanks[v]/graph->vertices[v].out_degree);
      else
      riDividedOnDiClause[v] = 0;
      
    }
    
    #pragma omp parallel for schedule(dynamic, 2048)  private(v,j,u,degree,edge_idx)
    for(v = 0; v < graph->num_vertices; v++){
      degree = graph->inverse_vertices[v].out_degree;
      edge_idx = graph->inverse_vertices[v].edges_idx;

      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = graph->inverse_sorted_edge_array[j];
          
        // addAtomicFixedPoint(&pageRanksNext[u] ,riDividedOnDiClause[v]);
        // __sync_add_and_fetch(&pageRanksNext[u], riDividedOnDiClause[v]);
        // __atomic_fetch_add(&pageRanksNext[u], riDividedOnDiClause[v], __ATOMIC_RELAXED);
        // pageRanksNext[u]+= riDividedOnDiClause[v];
        // printf("%llu \n", pageRanksNext[u]);

        omp_set_lock(&(vertex_lock[u]));
        pageRanksNext[u] += riDividedOnDiClause[v];
        omp_unset_lock((&vertex_lock[u]));
      }

    }

    #pragma omp parallel for reduction(+ : error)
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      pageRanks[v] = base_pr + (Damp * FixedToDouble64(pageRanksNext[v]));
      error += fabs( pageRanks[v] - prevPageRank);
      pageRanksNext[v] = 0;
    }

    Stop(timer_inner);
    printf("| %-15u | %-15.13lf | %-15f | \n",iter, error, Seconds(timer_inner));
    if(error < epsilon)
      break;

  }// end iteration loop
  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-15s | %-15u | %-15f | \n","total", iter+1, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  // pageRankPrint(pageRanks, graph->num_vertices);

  #pragma omp parallel for
    for (i=0; i<graph->num_vertices; i++){
        omp_destroy_lock(&(vertex_lock[i]));
    }

  free(timer);
  free(timer_inner);
  free(vertex_lock);
  free(pageRanks);
  free(riDividedOnDiClause);

}


void pageRankDataDrivenPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  
  
  __u32 iter;
  __u32 i;
  __u32 v;
 
  
 
  double error_total = 0;
  float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp) / (float)graph->num_vertices;
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
    pageRanks[i] = init_pr;
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
 
    #pragma omp parallel for default(none) shared(epsilon,pageRanks,riDividedOnDiClause,sorted_edges_array,vertices,workListCurr,workListNext,base_pr,graph) private(v) reduction(+:activeVertices,error_total)
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
        error_total+= error;
        if(error >= epsilon){
          pageRanks[v] = newPageRank;
          degree = graph->vertices[v].out_degree;
          edge_idx = graph->vertices[v].edges_idx;
          for(j = edge_idx ; j < (edge_idx + degree) ; j++){
            u = graph->sorted_edge_array[j];
            __u8 old_val = workListNext[u];
            if(!old_val){
               __sync_bool_compare_and_swap(&workListNext[u], old_val, 1);
            }
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
  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-15s | %-15u | %-15f | \n","total", iter+1, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(pageRanks);
  free(riDividedOnDiClause);


}
void pageRankDataDrivenPushGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

  __u32 iter;
  __u32 v;
  __u32 edge_idx;
  __u32 degree;
  __u32 j;
  __u32 u;
  
 
  double error_total = 0;
  float init_pr = 1.0f / (float)graph->num_vertices;
  float base_pr = (1.0f - Damp) / (float)graph->num_vertices;
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

  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){
    if(graph->vertices[v].out_degree)
      riDividedOnDiClause[v] = 1.0f/graph->vertices[v].out_degree;
    else
      riDividedOnDiClause[v] = 0.0f;
  }

  #pragma omp parallel for private(edge_idx,degree,v,j,u) reduction(+:activeVertices)
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = (1.0f - Damp);
    aResiduals[v] = 0.0;
    workListCurr[v]=1;
    workListNext[v]=0;
    activeVertices++;
    degree = vertices[v].out_degree; // when directed we use inverse graph out degree means in degree
    edge_idx = vertices[v].edges_idx;
    for(j = edge_idx ; j < (edge_idx + degree) ; j++){
      u = sorted_edges_array[j];
      aResiduals[v] += riDividedOnDiClause[j]; // sum (PRi/outDegree(i))
    }
    aResiduals[v] = (1.0f - Damp)*Damp*aResiduals[v];
  }

  Stop(timer_inner);
  printf("| %-10s | %-8u | %-15.13lf | %-9f | \n","Init", activeVertices,error_total, Seconds(timer_inner));

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error_total = 0;
    activeVertices = 0;

    for(v = 0; v < graph->num_vertices; v++){
      if(workListCurr[v]){
        float oldPageRank =  pageRanks[v];
        pageRanks[v] += aResiduals[v];
        error_total+= fabs(pageRanks[v]/graph->num_vertices - oldPageRank/graph->num_vertices);
        degree = graph->vertices[v].out_degree;
        edge_idx = graph->vertices[v].edges_idx;
        double delta = Damp*(aResiduals[v]/degree);
        for(j = edge_idx ; j < (edge_idx + degree) ; j++){
          u = graph->sorted_edge_array[j];
          float prevResidual = aResiduals[u];
          aResiduals[u] += delta;
          if ((prevResidual + delta >= epsilon) && (prevResidual <= epsilon)){
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

  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){
    pageRanks[v] = pageRanks[v]/graph->num_vertices;
  }

  Stop(timer);

  printf(" -----------------------------------------------------\n");
  printf("| %-15s | %-15u | %-15f | \n","total", iter+1, Seconds(timer));
  printf(" -----------------------------------------------------\n");

  pageRankPrint(pageRanks, graph->num_vertices);
  free(workListCurr);
  free(workListNext);
  free(timer);
  free(timer_inner);
  free(pageRanks);
  free(riDividedOnDiClause);


}


void pageRankDataDrivenPushPullGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


}


void pageRankDataDrivenPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


}
void pageRankDataDrivenPushFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


}


void pageRankDataDrivenPushPullFixedPointGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){


}



// ********************************************************************************************
// ***************					ArrayList DataStructure					     **************
// ********************************************************************************************


void pageRankGraphAdjArrayList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjArrayList* graph){

	switch (pushpull)
      { 
        case 0: // push
        	pageRankPushGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 1: // pull
          	pageRankPullGraphAdjArrayList(epsilon, iterations, graph);
        break;
        case 2: // pushpull
          	pageRankPullPushGraphAdjArrayList(epsilon, iterations, graph);
        break;  
        default:// push
           	pageRankPushGraphAdjArrayList(epsilon, iterations, graph);
        break;          
      }

}
void pageRankPullGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){


}
void pageRankPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){


}
void pageRankPullPushGraphAdjArrayList(double epsilon,  __u32 iterations, struct GraphAdjArrayList* graph){


}


// ********************************************************************************************
// ***************					LinkedList DataStructure					 **************
// ********************************************************************************************


void pageRankGraphAdjLinkedList(double epsilon,  __u32 iterations, __u32 pushpull, struct GraphAdjLinkedList* graph){

	switch (pushpull)
      { 
        case 0: // push
        	pageRankPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 1: // pull
          	pageRankPullGraphAdjLinkedList(epsilon, iterations, graph);
        break;
        case 2: // pushpull
          	pageRankPullPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;  
        default:// push
           	pageRankPushGraphAdjLinkedList(epsilon, iterations, graph);
        break;          
      }

}
void pageRankPullGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){


}
void pageRankPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){


}
void pageRankPullPushGraphAdjLinkedList(double epsilon,  __u32 iterations, struct GraphAdjLinkedList* graph){


}