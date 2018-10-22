#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <omp.h>
#include <linux/types.h>

#include "sortRun.h"
#include "fixedPoint.h"
#include "timer.h"
#include "myMalloc.h"
#include "graphCSR.h"
#include "reorder.h"
#include "edgeList.h"

struct EdgeList* reorderGraphListPageRank(struct GraphCSR* graph){

	float* pageRanks = NULL;
	__u32 v;
	double epsilon = 0.0001;
	__u32 iterations = 10;
	struct EdgeList* edgeList = NULL;
	__u32* labelsInverse;
	__u32* labels;
	 struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

	#if ALIGNED
        labels = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
  	#else
        labels = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
  	#endif


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting PageRank Reording/Relabeling");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    #pragma omp parallel for
	for(v = 0; v < graph->num_vertices; v++){
		labelsInverse[v]= v;
	}

	pageRanks = pageRankPullReOrderGraphCSR(epsilon, iterations, graph);


	labelsInverse = radixSortEdgesByPageRank(pageRanks, labelsInverse, graph->num_vertices);

	#pragma omp parallel for
	for(v = 0; v < graph->num_vertices; v++){
		labels[labelsInverse[v]] = v;
	}

	edgeList = relabelEdgeList(graph,labels);

	Stop(timer);

	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "PageRank Reording/Relabeling Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");

	free(timer);

	return edgeList;
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
  	if(graph->vertices[v].out_degree || graph->vertices[v].in_degree)
    	pageRanks[v] = pageRanks[v]/graph->num_vertices;
    else
    	pageRanks[v] = 0.0f;

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


void radixSortCountSortEdgesByRanks (__u32** pageRanksFP, __u32** pageRanksFPTemp, __u32** labels, __u32** labelsTemp,__u32 radix, __u32 buckets, __u32* buckets_count, __u32 num_vertices){

	__u32* tempPointer = NULL; 
    __u32 t = 0;
    __u32 o = 0;
    __u32 u = 0;
    __u32 i = 0;
    __u32 j = 0;
    __u32 P = numThreads;  // 32/8 8 bit radix needs 4 iterations
    __u32 t_id = 0;
    __u32 offset_start = 0;
    __u32 offset_end = 0;
    __u32 base = 0;

    #pragma omp parallel default(none) shared(pageRanksFP, pageRanksFPTemp,radix,labels,labelsTemp,buckets,buckets_count, num_vertices) firstprivate(t_id, P, offset_end,offset_start,base,i,j,t,u,o) 
    {
        P = omp_get_num_threads();
        t_id = omp_get_thread_num();
        offset_start = t_id*(num_vertices/P);


        if(t_id == (P-1)){
            offset_end = offset_start+(num_vertices/P) + (num_vertices%P) ;
        }
        else{
            offset_end = offset_start+(num_vertices/P);
        }
        

        //HISTOGRAM-KEYS 
        for(i=0; i < buckets; i++){ 
            buckets_count[(t_id*buckets)+i] = 0;
        }

       
        for (i = offset_start; i < offset_end; i++) {      
            u = (*pageRanksFP)[i];
            t = (u >> (radix*8)) & 0xff;
            buckets_count[(t_id*buckets)+t]++;
        }


        #pragma omp barrier

       
        // SCAN BUCKETS
        if(t_id == 0){
            for(i=0; i < buckets; i++){
                 for(j=0 ; j < P; j++){
                 t = buckets_count[(j*buckets)+i];
                 buckets_count[(j*buckets)+i] = base;
                 base += t;
                }
            }
        }


        #pragma omp barrier

        //RANK-AND-PERMUTE
        for (i = offset_start; i < offset_end; i++) {       /* radix sort */
            u = (*pageRanksFP)[i];
            t = (u >> (radix*8)) & 0xff;
            o = buckets_count[(t_id*buckets)+t];
            (*pageRanksFPTemp)[o] = (*pageRanksFP)[i];
            (*labelsTemp)[o] = (*labels)[i];
            buckets_count[(t_id*buckets)+t]++;

        }

    }

    tempPointer = *labels;
    *labels = *labelsTemp;
    *labelsTemp = tempPointer;


    tempPointer = *pageRanksFP;
    *pageRanksFP = *pageRanksFPTemp;
    *pageRanksFPTemp = tempPointer;
    
}

__u32* radixSortEdgesByPageRank (float* pageRanks, __u32* labels, __u32 num_vertices){

	
	    // printf("*** START Radix Sort Edges By Source *** \n");

    // struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number
	__u32 v;
    __u32 radix = 4;  // 32/8 8 bit radix needs 4 iterations
    __u32 P = numThreads;  // 32/8 8 bit radix needs 4 iterations
    __u32 buckets = 256; // 2^radix = 256 buckets
    __u32* buckets_count = NULL;

    // omp_set_num_threads(P);
   	
    __u32 j = 0; //1,2,3 iteration

    __u32* pageRanksFP = NULL;
    __u32* pageRanksFPTemp = NULL;
    __u32* labelsTemp = NULL;
  

    #if ALIGNED
        buckets_count = (__u32*) my_aligned_malloc(P * buckets * sizeof(__u32));
        pageRanksFP = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
        pageRanksFPTemp = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
        labelsTemp = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
    #else
        buckets_count = (__u32*) my_malloc(P * buckets * sizeof(__u32));
        pageRanksFP = (__u32*) my_malloc(num_vertices * sizeof(__u32));
        pageRanksFPTemp = (__u32*) my_malloc(num_vertices * sizeof(__u32));
        labelsTemp = (__u32*) my_malloc(num_vertices * sizeof(__u32));
    #endif

   	#pragma omp parallel for
	for(v = 0; v < num_vertices; v++){
		pageRanksFP[v]= FloatToFixed32(pageRanks[v]);
	}

    for(j=0 ; j < radix ; j++){
        radixSortCountSortEdgesByRanks (&pageRanksFP, &pageRanksFPTemp, &labels, &labelsTemp,j, buckets, buckets_count, num_vertices);
    }

 	//  	#pragma omp parallel for
	// for(v = 0; v < num_vertices; v++){
	// 	pageRanks[v]= Fixed32ToFloat(pageRanksFP[v]);
	// }

    free(buckets_count);
    free(pageRanksFP);
    free(pageRanksFPTemp);
    free(labelsTemp);

    return labels;

}

__u32* radixSortEdgesByDegree (__u32* degrees, __u32* labels, __u32 num_vertices){

	
	    // printf("*** START Radix Sort Edges By Source *** \n");

    // struct Graph* graph = graphNew(edgeList->num_vertices, edgeList->num_edges, inverse);

    // Do counting sort for every digit. Note that instead
    // of passing digit number, exp is passed. exp is 10^i
    // where i is current digit number
    __u32 radix = 4;  // 32/8 8 bit radix needs 4 iterations
    __u32 P = numThreads;  // 32/8 8 bit radix needs 4 iterations
    __u32 buckets = 256; // 2^radix = 256 buckets
    __u32* buckets_count = NULL;

    // omp_set_num_threads(P);
   	
    __u32 j = 0; //1,2,3 iteration
    __u32* degreesTemp = NULL;
    __u32* labelsTemp = NULL;
  
    #if ALIGNED
        buckets_count = (__u32*) my_aligned_malloc(P * buckets * sizeof(__u32));
        degreesTemp = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
        labelsTemp = (__u32*) my_aligned_malloc(num_vertices * sizeof(__u32));
    #else
        buckets_count = (__u32*) my_malloc(P * buckets * sizeof(__u32));
        degreesTemp = (__u32*) my_malloc(num_vertices * sizeof(__u32));
        labelsTemp = (__u32*) my_malloc(num_vertices * sizeof(__u32));
    #endif

    for(j=0 ; j < radix ; j++){
        radixSortCountSortEdgesByRanks (&degrees, &degreesTemp, &labels, &labelsTemp,j, buckets, buckets_count, num_vertices);
    }


    free(buckets_count);
    free(degreesTemp);
    free(labelsTemp);

    return labels;

}


struct EdgeList* reorderGraphProcess(struct GraphCSR* graph, __u32 sort, struct EdgeList* edgeList, __u32 lmode){

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    // printf("Filename : %s \n",fnameb);
    
	printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Reorder Process");
    printf(" -----------------------------------------------------\n");
    Start(timer);

	    // Start(timer);
    edgeList = sortRunAlgorithms(edgeList, sort);
    // edgeList = radixSortEdgesBySourceOptimized(edgeList);
    // edgeListPrint(edgeList);
    // Stop(timer);
    // graphCSRPrintMessageWithtime("Radix Sort Edges By Source (Seconds)",Seconds(timer));

    Start(timer);
    graph = graphCSRAssignEdgeList (graph,edgeList, 0);
    Stop(timer);


    graphCSRPrintMessageWithtime("Process In/Out degrees of Nodes (Seconds)",Seconds(timer));

     #if DIRECTED

        Start(timer);
        // struct EdgeList* inverse_edgeList = readEdgeListsbin(fnameb,1);
        struct EdgeList* inverse_edgeList = readEdgeListsMem(edgeList,1);
        Stop(timer);
        // edgeListPrint(inverse_edgeList);
        graphCSRPrintMessageWithtime("Read Inverse Edge List From File (Seconds)",Seconds(timer));


        // Start(timer);
        inverse_edgeList = sortRunAlgorithms(inverse_edgeList, sort);
        // inverse_edgeList = radixSortEdgesBySourceOptimized(inverse_edgeList);
        // Stop(timer);
        // graphCSRPrintMessageWithtime("Radix Sort Inverse Edges By Source (Seconds)",Seconds(timer));

        Start(timer);
        graph = graphCSRAssignEdgeList (graph,inverse_edgeList, 1);
        Stop(timer);
        graphCSRPrintMessageWithtime("Process In/Out degrees of Inverse Nodes (Seconds)",Seconds(timer));

    #endif
    
   
  
    edgeList = reorderGraphListPageRank(graph);


    Stop(timer);
   

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Reorder Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");

    free(timer);

    #if DIRECTED
		if(graph->inverse_sorted_edges_array)
			freeEdgeArray(graph->inverse_sorted_edges_array);
	#endif

	
	graphCSRHardReset(graph);


    return edgeList;



}


struct EdgeList* reorderGraphListDegree(struct GraphCSR* graph, __u32 lmode){

  __u32 v;
  struct EdgeList* edgeList = NULL;
  __u32* labelsInverse;
  __u32* labels;
  __u32* degrees;
   struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    #if ALIGNED
        labels = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_aligned_malloc(graph->num_vertices*sizeof(__u32));

    #else
        labels = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));
        degrees = (__u32*) my_malloc(graph->num_vertices*sizeof(__u32));

    #endif


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Degree Reording/Relabeling");
    printf(" -----------------------------------------------------\n");
    if(lmode == 1){ // in-degree
    printf("| %-51s | \n", "IN-DEGREE");
    }
    else if(lmode == 2){
    printf("| %-51s | \n", "OUT-DEGREE");
    }
    printf(" -----------------------------------------------------\n");

    Start(timer);

  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){
    labelsInverse[v]= v;
  }

  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){
    // degrees[v]= vertices[v].out_degree;

    if(lmode == 1){ // in-degree
      #if DIRECTED
        degrees[v]= graph->inverse_vertices[v].out_degree;
      #else
        degrees[v]= graph->vertices[v].out_degree;
      #endif
    }
    else if(lmode == 2){ // out-degree
      degrees[v]= graph->vertices[v].out_degree;
    }
  }


  labelsInverse = radixSortEdgesByDegree(degrees, labelsInverse, graph->num_vertices);


  //decending order
  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){
    labels[labelsInverse[v]] = v;
  }

  edgeList = relabelEdgeList(graph,labels);

  Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Degree Reording/Relabeling Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");

  free(timer);

  return edgeList;
}

struct EdgeList* relabelEdgeList(struct GraphCSR* graph, __u32* labels){

  struct  EdgeList* edgeList;

  #if ALIGNED
        edgeList = (struct  EdgeList*) my_aligned_malloc(graph->num_vertices*sizeof(struct  EdgeList));
    #else
        edgeList = (struct  EdgeList*) my_malloc(graph->num_vertices*sizeof(struct  EdgeList));
    #endif

    edgeList->num_edges = graph->num_edges;
    edgeList->num_vertices = graph->num_vertices;
    edgeList->edges_array = graph->sorted_edges_array;

    __u32 i;
   
    #pragma omp parallel for
    for(i = 0; i < edgeList->num_edges; i++){
      __u32 src;
      __u32 dest;
      src = edgeList->edges_array[i].src;
      dest = edgeList->edges_array[i].dest;

      edgeList->edges_array[i].src = labels[src];
      edgeList->edges_array[i].dest = labels[dest];

    }

   

    return edgeList;

}
