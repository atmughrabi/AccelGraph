#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "boolean.h"
#include "pageRank.h"
#include "fixedPoint.h"

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


//   void addAtomicFloat(float *num, float value){

//   float newV, oldV;

//   do {oldV = *num;  newV = oldV+value;}
//   while(!__sync_bool_compare_and_swap((long*)num, *((long*)&oldV), *((long*)&newV))); 

// }

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
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51lf | \n", epsilon);
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
      riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
    }
 
    #pragma omp parallel for reduction(+ : error) schedule(dynamic, 1024)
    for(v = 0; v < graph->num_vertices; v++){
      float nodeIncomingPR = 0;
      degree = vertices[v].out_degree;
      edge_idx = vertices[v].edges_idx;
      // #pragma omp parallel for reduction(+ : nodeIncomingPR) schedule(dynamic, 1024)
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        nodeIncomingPR += riDividedOnDiClause[u];
      }
      float prevPageRank = pageRanks[v];
      pageRanks[v] = base_pr + (Damp * nodeIncomingPR);
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
        float* pageRanksNext = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
        float* riDividedOnDiClause = (float*) my_aligned_malloc(graph->num_vertices*sizeof(float));
  #else
        float* pageRanks = (float*) my_malloc(sizeof(float));
        float* pageRanksNext = (float*) my_malloc(sizeof(float));
        float* riDividedOnDiClause = (float*) my_malloc(sizeof(float));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51lf | \n", epsilon);
    printf(" -----------------------------------------------------\n");
    printf("| %-15s | %-15s | %-15s | \n", "Iteration", "Error", "Time (Seconds)");
    printf(" -----------------------------------------------------\n");

  Start(timer);
    

  #pragma omp parallel for
  for(i = 0; i < graph->num_vertices; i++){
    pageRanks[i] = init_pr;
    pageRanksNext[i] = 0.0f;
  }

  for(iter = 0; iter < iterations; iter++){
    Start(timer_inner);
    error = 0;
    #pragma omp parallel for
    for(v = 0; v < graph->num_vertices; v++){
      riDividedOnDiClause[v] = pageRanks[v]/graph->vertices[v].out_degree;
      
    }
    
    #pragma omp parallel for schedule(dynamic, 2048)
    for(v = 0; v < graph->num_vertices; v++){
      degree = graph->vertices[v].out_degree;
      edge_idx = graph->vertices[v].edges_idx;

      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = graph->sorted_edge_array[j];
        
        // omp_set_lock(&(vertex_lock[u]));
        // pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        #pragma omp atomic
          pageRanksNext[u] += riDividedOnDiClause[v];
      
        // addAtomicFloat(&pageRanks[u] , riDividedOnDiClause[v]);
      }
    }

    #pragma omp parallel for reduction(+ : error)
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      pageRanks[v] = base_pr + (Damp * pageRanksNext[v]);
      error += fabs( pageRanks[v] - prevPageRank);
      pageRanksNext[v] = 0.0f;
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
        float* pageRanks = (float*) my_malloc(sizeof(float));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Pull FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51lf | \n", epsilon);
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
      riDividedOnDiClause[v] = DoubleToFixed(pageRanks[v]/graph->vertices[v].out_degree);
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
        float* pageRanks = (float*) my_malloc(sizeof(float));
        __u64* pageRanksNext = (__u64*) my_malloc(sizeof(__u64));
        __u64* riDividedOnDiClause = (__u64*) my_malloc(sizeof(__u64));
  #endif

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Page Rank Push FP (tolerance/epsilon)");
    printf(" -----------------------------------------------------\n");
    printf("| %-51lf | \n", epsilon);
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
      riDividedOnDiClause[v] = DoubleToFixed(pageRanks[v]/graph->vertices[v].out_degree);
      
    }
    
    #pragma omp parallel for schedule(dynamic, 2048)
    for(v = 0; v < graph->num_vertices; v++){
      degree = graph->vertices[v].out_degree;
      edge_idx = graph->vertices[v].edges_idx;

      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = graph->sorted_edge_array[j];
          
        // addAtomicFixedPoint(&pageRanksNext[u],riDividedOnDiClause[v] );
        __sync_add_and_fetch(&pageRanksNext[u], riDividedOnDiClause[v]);
    
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

    free(vertex_lock);
  free(pageRanks);
  free(riDividedOnDiClause);

}


void pageRankDataDrivenPullGraphCSR(double epsilon,  __u32 iteraions, struct GraphCSR* graph){


}
void pageRankDataDrivenPushGraphCSR(double epsilon,  __u32 iteraions, struct GraphCSR* graph){


}
void pageRankDataDrivenPullFixedPointGraphCSR(double epsilon,  __u32 iteraions, struct GraphCSR* graph){


}
void pageRankDataDrivenPushFixedPointGraphCSR(double epsilon,  __u32 iteraions, struct GraphCSR* graph){


}

void pageRankDataDrivenPushPullGraphCSR(double epsilon,  __u32 iteraions, struct GraphCSR* graph){


}

void pageRankDataDrivenPushPullFixedPointGraphCSR(double epsilon,  __u32 iteraions, struct GraphCSR* graph){


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