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
#include "pageRank.h"

struct EdgeList* reorderGraphListPageRank(struct GraphCSR* graph){

	float* pageRanks = NULL;
	__u32 v;
	double epsilon = 1e-6;
	__u32 iterations = 10;
	
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

  #if ALIGNED
      struct EdgeList* edgeList = (struct EdgeList*) my_aligned_malloc(sizeof(struct EdgeList));
  #else
      struct EdgeList* edgeList = (struct EdgeList*) my_malloc(sizeof(struct EdgeList));
  #endif


    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting PageRank Reording/Relabeling");
    printf(" -----------------------------------------------------\n");

    Start(timer);
    #pragma omp parallel for
	for(v = 0; v < graph->num_vertices; v++){
		labelsInverse[v]= v;
	}


  pageRanks = pageRankDataDrivenPushGraphCSR(epsilon, iterations, graph);

  // make sure that nodes with no in/out degrees have zero scores
  #pragma omp parallel for 
  for(v = 0; v < graph->num_vertices; v++){
    if(graph->vertices[v].out_degree || graph->vertices[v].in_degree){
      pageRanks[v] = pageRanks[v];
    }   
    else{
      pageRanks[v] = 0;
    }
  }

	labelsInverse = radixSortEdgesByPageRank(pageRanks, labelsInverse, graph->num_vertices);

  #pragma omp parallel for
  for(v = 0; v < graph->num_vertices; v++){

     labels[labelsInverse[v]] = graph->num_vertices -1 - v;
  }




  edgeList->num_vertices = graph->num_vertices;
  edgeList->num_edges = graph->num_edges;
  edgeList->edges_array = graph->sorted_edges_array;

	edgeList = relabelEdgeList(edgeList ,labels);

	Stop(timer);

	  printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "PageRank Reording/Relabeling Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");

	free(timer);
  free(labelsInverse);

	return edgeList;
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

struct EdgeList* reorderGraphProcessPageRank( __u32 sort, struct EdgeList* edgeList, __u32 lmode , __u32 symmetric){
    
  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

  #if DIRECTED
      struct GraphCSR* graph = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 1);
  #else
      struct GraphCSR* graph = graphCSRNew(edgeList->num_vertices, edgeList->num_edges, 0);
  #endif

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
        struct EdgeList* inverse_edgeList = readEdgeListsMem(edgeList,1, symmetric);
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

  if(graph->vertices)
    freeVertexArray(graph->vertices);
  if(graph->parents)
    free(graph->parents);
  // if(graph->sorted_edges_array)
  //   freeEdgeArray(graph->sorted_edges_array);

  #if DIRECTED
    if(graph->inverse_vertices)
      freeVertexArray(graph->inverse_vertices);
    if(graph->inverse_sorted_edges_array)
      freeEdgeArray(graph->inverse_sorted_edges_array);
  #endif


    free(timer);

    return edgeList;


}


struct EdgeList* reorderGraphProcessDegree( __u32 sort, struct EdgeList* edgeList, __u32 lmode){


     __u32* degrees;

    #if ALIGNED
        degrees = (__u32*) my_aligned_malloc(edgeList->num_vertices*sizeof(__u32));
    #else
        degrees = (__u32*) my_malloc(edgeList->num_vertices*sizeof(__u32));
    #endif

    degrees = reorderGraphProcessInOutDegrees( degrees , edgeList, lmode);

    edgeList = reorderGraphListDegree( edgeList, degrees, lmode);

    return edgeList;

}

__u32 reorderGraphProcessVertexSize( struct EdgeList* edgeList){

    __u32 i;
    __u32 src;
    __u32 dest;
    __u32 num_vertices = 0;

    #pragma omp parallel for default(none) private(i,src,dest) shared(edgeList) reduction(max: num_vertices)
    for(i = 0; i < edgeList->num_edges; i++){

      src  = edgeList->edges_array[i].src;
      dest = edgeList->edges_array[i].dest;
      num_vertices = maxTwoIntegers(num_vertices ,maxTwoIntegers(src, dest));

    }

    return num_vertices;
}


__u32* reorderGraphProcessInOutDegrees(__u32* degrees , struct EdgeList* edgeList, __u32 lmode){

    __u32 i;
    __u32 src;
    __u32 dest;

    #pragma omp parallel for default(none) private(i,src,dest) shared(edgeList,degrees,lmode)
    for(i = 0; i < edgeList->num_edges; i++){
      src  = edgeList->edges_array[i].src;
      dest = edgeList->edges_array[i].dest;

      if(lmode == 3){
      #pragma omp atomic update
          degrees[src]++;
      }
      else if(lmode == 2){
      #pragma omp atomic update
          degrees[dest]++;
      }
      else if(lmode == 4){
      #pragma omp atomic update
          degrees[dest]++;
      #pragma omp atomic update
          degrees[src]++;
      }

    }

    return degrees;
}



struct EdgeList* reorderGraphProcess( __u32 sort, struct EdgeList* edgeList, __u32 lmode, __u32 symmetric){

 


	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    // printf("Filename : %s \n",fnameb);
    
    printf(" *****************************************************\n");
	  printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Reorder Process");
    printf(" -----------------------------------------------------\n");
    Start(timer);

	  

    
    if(lmode == 1) // pageRank
      edgeList = reorderGraphProcessPageRank( sort, edgeList, lmode, symmetric);
    else if(lmode == 2)
      edgeList = reorderGraphProcessDegree( sort, edgeList, lmode);// in-degree
    else if(lmode == 3)
      edgeList = reorderGraphProcessDegree( sort, edgeList, lmode);// out-degree
    else if(lmode == 4)
      edgeList = reorderGraphProcessDegree( sort, edgeList, lmode);// in/out-degree


    Stop(timer);
   

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Reorder Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");
    printf(" *****************************************************\n");

    free(timer);

    return edgeList;

}


struct EdgeList* reorderGraphListDegree(struct EdgeList* edgeList, __u32* degrees, __u32 lmode){

  __u32 v;
  __u32* labelsInverse;
  __u32* labels;
   struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

    #if ALIGNED
        labels = (__u32*) my_aligned_malloc(edgeList->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_aligned_malloc(edgeList->num_vertices*sizeof(__u32));
    
    #else
        labels = (__u32*) my_malloc(edgeList->num_vertices*sizeof(__u32));
        labelsInverse = (__u32*) my_malloc(edgeList->num_vertices*sizeof(__u32));
    #endif

    
    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Starting Degree Reording/Relabeling");
    printf(" -----------------------------------------------------\n");
    if(lmode == 2){ // in-degree
    printf("| %-51s | \n", "IN-DEGREE");
    }
    else if(lmode == 3){
    printf("| %-51s | \n", "OUT-DEGREE");
    }
    else if(lmode == 4){
    printf("| %-51s | \n", "IN/OUT-DEGREE");
    }
    printf(" -----------------------------------------------------\n");

    Start(timer);

  #pragma omp parallel for
  for(v = 0; v < edgeList->num_vertices; v++){
    labelsInverse[v]= v;
  }

  labelsInverse = radixSortEdgesByDegree(degrees, labelsInverse, edgeList->num_vertices);


  //decending order mapping
  #pragma omp parallel for
  for(v = 0; v < edgeList->num_vertices; v++){
    labels[labelsInverse[v]] = edgeList->num_vertices -1 - v;
  }

  edgeList = relabelEdgeList(edgeList,labels);

  Stop(timer);

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Degree Reording/Relabeling Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");


  free(timer);

  return edgeList;
}

struct EdgeList* relabelEdgeList(struct EdgeList* edgeList, __u32* labels){

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
