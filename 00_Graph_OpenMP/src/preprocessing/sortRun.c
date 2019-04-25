#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/types.h>

#include "countsort.h"
#include "radixsort.h"
#include "edgeList.h"
#include "timer.h"
#include "sortRun.h"

// -o [sorting algorithm] 0 radix-src 1 radix-src-dest 2 count-src 3 count-src-dst;
struct EdgeList* sortRunAlgorithms(struct EdgeList* edgeList, __u32 sort){

  struct Timer* timer = (struct Timer*) malloc(sizeof(struct Timer));

  switch (sort)
      {
        case 0: // radix sort by source
        	Start(timer);
    		edgeList = radixSortEdgesBySource(edgeList);
 			Stop(timer);
 			sortRunPrintMessageWithtime("Radix Sort Edges By Source (Seconds)",Seconds(timer));
          break;
        case 1: // radix sort by source and destination
          	Start(timer);
    		edgeList = radixSortEdgesBySourceAndDestination(edgeList);
 			Stop(timer);
 			sortRunPrintMessageWithtime("Radix Sort Edges By Source/Dest (Seconds)",Seconds(timer));
          break;
        case 2: // count sort by source
          	Start(timer);
    		edgeList = countSortEdgesBySource(edgeList);
 			Stop(timer);
 			sortRunPrintMessageWithtime("Count Sort Edges By Source (Seconds)",Seconds(timer));
          break;
        case 3: // count sort by source and destination
         	Start(timer);
    		edgeList = countSortEdgesBySourceAndDestination(edgeList);
 			Stop(timer);
 			sortRunPrintMessageWithtime("Count Sort Edges By Source/Dest (Seconds)",Seconds(timer));
          break;
        default:// bfs file name root
          	Start(timer);
    		edgeList = radixSortEdgesBySource(edgeList);
 			Stop(timer);
 			sortRunPrintMessageWithtime("Radix Sort Edges By Source (Seconds)",Seconds(timer));
          break;          
      }


 free(timer);
 return edgeList;

}

void sortRunPrintMessageWithtime(const char * msg, double time){

    printf(" -----------------------------------------------------\n");
    printf("| %-51s | \n", msg);
    printf(" -----------------------------------------------------\n");
    printf("| %-51f | \n", time);
    printf(" -----------------------------------------------------\n");

}