#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>
#include <string.h>
#include <omp.h>

#include "graphStats.h"
#include "myMalloc.h"
#include "graphCSR.h"
#include "graphConfig.h"
#include "timer.h"




void collectStats( __u32 binSize, const char * fnameb,  __u32 sort,  __u32 lmode, __u32 symmetric, __u32 weighted, __u32 inout_degree){

	struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));
    // printf("Filename : %s \n",fnameb);
    
    printf(" *****************************************************\n");
	  printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Collect Stats Process");
    printf(" -----------------------------------------------------\n");
    Start(timer);

	struct GraphCSR* graphStats = graphCSRPreProcessingStep (fnameb, sort, lmode, symmetric, weighted);

	__u32 histSize = (graphStats->num_vertices/binSize) + 1;

	#if ALIGNED
		__u32* histogram =  (__u32*) my_aligned_malloc(sizeof(__u32)*histSize);
	#else
    __u32* histogram = (__u32*) my_malloc(sizeof(__u32)*histSize);
	#endif

       __u32 i = 0;
    for(i = 0 ; i <histSize; i++){
    	histogram[i] = 0;
    }

    char * fname_txt = (char *) malloc((strlen(fnameb)+20)*sizeof(char));
    char * fname_stats = (char *) malloc((strlen(fnameb)+20)*sizeof(char));

    fname_txt = strcpy (fname_txt, fnameb);

    
    if(inout_degree == 1)
      fname_stats = strcat (fname_txt, ".in-degree.dat");// in-degree
    else if(inout_degree == 2)
      fname_stats = strcat (fname_txt, ".out-degree.dat");// out-degree


  countHistogram(graphStats, histogram, binSize, inout_degree);
  printHistogram(fname_stats, histogram, binSize, histSize);

 


   Stop(timer);
   

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", "Collect Stats Complete");
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", Seconds(timer));
    printf(" -----------------------------------------------------\n");
    printf(" *****************************************************\n");

    free(timer);
    graphCSRFree(graphStats);
  	free(histogram);

}


void countHistogram(struct GraphCSR* graphStats, __u32* histogram, __u32 binSize, __u32 inout_degree){

__u32 v;
__u32 index;
for(v = 0; v < graphStats->num_vertices; v++){

	index = v/binSize;

    if(inout_degree == 1)
       histogram[index] += graphStats->vertices[v].in_degree;
    else if(inout_degree == 2)
       histogram[index] += graphStats->vertices[v].out_degree;
   }

}


void printHistogram(const char * fname_stats, __u32* histogram, __u32 binSize, __u32 histSize){

	__u32 index;
	FILE *fptr;
  fptr = fopen(fname_stats,"w");
	for(index = 0; index < histSize; index++){	
	    fprintf(fptr,"%u %u \n", index, histogram[index]);
	   }
	fclose(fptr);
}


void printSparseMatrixList(const char * fname_stats, struct EdgeList* edgeList, __u32 binSize){

  #if ALIGNED
    __u32* SparseMatrix =  (__u32*) my_aligned_malloc(sizeof(__u32)*binSize*binSize);
  #else
    __u32* SparseMatrix = (__u32*) my_malloc(sizeof(__u32)*binSize*binSize);
  #endif

  __u32 x;
  __u32 y;
  #pragma omp parallel for private(y) shared(SparseMatrix)
    for(x = 0; x < binSize; x++){
      for(y = 0; y < binSize; y++){
        SparseMatrix[(binSize*y)+x] = 0;
      }
    }


  __u32 i;
   
    #pragma omp parallel for
    for(i = 0; i < edgeList->num_edges; i++){
      __u32 src;
      __u32 dest;
      src = edgeList->edges_array[i].src/binSize;
      dest = edgeList->edges_array[i].dest/binSize;

      #pragma omp atomic update
       SparseMatrix[(binSize*dest)+src]++;

    }

  FILE *fptr;
  fptr = fopen(fname_stats,"w");
  for(x = 0; x < binSize; x++){
      for(y = 0; y < binSize; y++){
        if(SparseMatrix[(binSize*y)+x])
          fprintf(fptr,"%u %u %u\n", x, y, SparseMatrix[(binSize*y)+x]);
      }
  }

  fclose(fptr);
  free(SparseMatrix); 

}

