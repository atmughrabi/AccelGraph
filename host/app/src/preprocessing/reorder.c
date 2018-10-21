
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>

#include "timer.h"
#include "myMalloc.h"
#include "graphCSR.h"


struct EdgeList* reorderGraphList(struct GraphCSR* graph){

	float* pageRanks = NULL;
	__u32 v;
	double epsilon = 0.000001;
	__u32 iterations = 20;

	#if ALIGNED
        __u32* labels = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
  	#else
        __u32* labels = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
  	#endif

    #pragma omp parallel for
	for(v = 0; v < graph->num_vertices; v++){
		labels[v]=v;
	}

	pageRanks = pageRankPullReOrderGraphCSR(epsilon, iterations, graph);

}

// topoligy driven approach
float* pageRankPullReOrderGraphCSR(double epsilon,  __u32 iterations, struct GraphCSR* graph){

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