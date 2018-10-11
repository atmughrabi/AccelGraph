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

#include "graphCSR.h"
#include "graphGrid.h"
#include "graphAdjArrayList.h"
#include "graphAdjLinkedList.h"


void addAtomicFloat(float *num, float value){

  float newV, oldV;

  do {oldV = *num;  newV = oldV+value;}
  while(!__sync_bool_compare_and_swap((long*)num, *((long*)&oldV), *((long*)&newV))); 

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

// topoligy driven approach
void pageRankPullGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph){

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

  for(iter = 0; iter < trials; iter++){
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
      
      for(j = edge_idx ; j < (edge_idx + degree) ; j++){
        u = sorted_edges_array[j];
        nodeIncomingPR += riDividedOnDiClause[u];
      }
      float prevPageRank = pageRanks[v];
      pageRanks[v] = base_pr + (Damp * nodeIncomingPR);
      error += fabs( pageRanks[v] - prevPageRank);
    }


    Stop(timer_inner);
    printf("| %-15u | %-15lf | %-15f | \n",iter, error, Seconds(timer_inner));
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
void pageRankPushGraphCSR(double epsilon,  __u32 trials, struct GraphCSR* graph){

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

  for(iter = 0; iter < trials; iter++){
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
        pageRanksNext[u] += riDividedOnDiClause[v];
        // omp_unset_lock((&vertex_lock[u]));

        // #pragma omp atomic
        // pageRanksNext[u] += riDividedOnDiClause[v];
      
        // addAtomicFloat(&pageRanks[u] , riDividedOnDiClause[v]);
      }

      // printf(" %d \n",v );
    }

    #pragma omp parallel for reduction(+ : error)
    for(v = 0; v < graph->num_vertices; v++){
      float prevPageRank =  pageRanks[v];
      pageRanks[v] = base_pr + (Damp * pageRanksNext[v]);
      error += fabs( pageRanks[v] - prevPageRank);
      pageRanksNext[v] = 0.0f;
    }

    Stop(timer_inner);
    printf("| %-15u | %-15lf | %-15f | \n",iter, error, Seconds(timer_inner));
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